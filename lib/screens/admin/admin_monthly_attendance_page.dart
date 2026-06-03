import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

class AdminMonthlyAttendancePage extends StatefulWidget {
  final String schoolId;
  final String className;
  final String section;
  final int month;
  final int year;

  const AdminMonthlyAttendancePage({
    super.key,
    required this.schoolId,
    required this.className,
    required this.section,
    required this.month,
    required this.year,
  });

  @override
  State<AdminMonthlyAttendancePage> createState() =>
      _AdminMonthlyAttendancePageState();
}

class _AdminMonthlyAttendancePageState
    extends State<AdminMonthlyAttendancePage> {
  List<Map<String, dynamic>> _attendanceData = [];
  bool _isLoading = true;
  double _classAverage = 0;
  int _totalDays = 0;
  int _totalStudents = 0;
  String _errorMessage = '';

  double _safePercentage(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return 0.0;
  }

  @override
  void initState() {
    super.initState();
    _calculateAttendance();
  }

  Future<void> _calculateAttendance() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final attendanceRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('attendance');

      final startDate = DateTime(widget.year, widget.month, 1);
      final endDate = DateTime(widget.year, widget.month + 1, 0);

      final snapshot =
          await attendanceRef
              .where(
                FieldPath.documentId,
                isGreaterThanOrEqualTo: DateFormat(
                  'yyyy-MM-dd',
                ).format(startDate),
              )
              .where(
                FieldPath.documentId,
                isLessThanOrEqualTo: DateFormat('yyyy-MM-dd').format(endDate),
              )
              .get();

      debugPrint('📊 Attendance days found: ${snapshot.docs.length}');

      QuerySnapshot studentsSnapshot;
      try {
        studentsSnapshot =
            await FirebaseFirestore.instance
                .collection('schools')
                .doc(widget.schoolId)
                .collection('students')
                .where('class', isEqualTo: widget.className)
                .where('section', isEqualTo: widget.section)
                .get();

        if (studentsSnapshot.docs.isEmpty) {
          studentsSnapshot =
              await FirebaseFirestore.instance
                  .collection('schools')
                  .doc(widget.schoolId)
                  .collection('students')
                  .where('className', isEqualTo: widget.className)
                  .where('section', isEqualTo: widget.section)
                  .get();
        }
      } catch (e) {
        studentsSnapshot =
            await FirebaseFirestore.instance
                .collection('schools')
                .doc(widget.schoolId)
                .collection('students')
                .get();
      }

      debugPrint('📚 Total students found: ${studentsSnapshot.docs.length}');

      Map<String, Map<String, dynamic>> studentData = {};

      for (var doc in studentsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        final studentClass = data['class'] ?? data['className'] ?? '';
        final studentSection = data['section'] ?? '';

        if (studentClass != widget.className ||
            studentSection != widget.section) {
          continue;
        }

        studentData[doc.id] = {
          'name': data['name'] ?? data['studentName'] ?? 'Unknown',
          'rollNo': data['rollNo'] ?? data['rollNumber'] ?? '',
          'present': 0,
          'absent': 0,
          'late': 0,
          'percentage': 0.0,
        };
      }

      _totalStudents = studentData.length;
      _totalDays = snapshot.docs.length;

      debugPrint('👨‍🎓 Students in class: $_totalStudents');
      debugPrint('📅 Total days: $_totalDays');

      if (_totalStudents == 0) {
        setState(() {
          _errorMessage =
              'No students found in class ${widget.className}-${widget.section}';
          _isLoading = false;
        });
        return;
      }

      if (_totalDays == 0) {
        setState(() {
          _attendanceData = [];
          _isLoading = false;
        });
        return;
      }

      for (var dateDoc in snapshot.docs) {
        final recordsSnapshot =
            await dateDoc.reference.collection('records').get();
        Set<String> studentsWithRecords = {};

        for (var recordDoc in recordsSnapshot.docs) {
          final recordData = recordDoc.data();
          final studentId = recordData['studentId'];
          final status = recordData['status'] ?? 'Absent';

          if (studentId != null && studentData.containsKey(studentId)) {
            studentsWithRecords.add(studentId);

            if (status == 'Present') {
              studentData[studentId]!['present'] =
                  (studentData[studentId]!['present'] as int) + 1;
            } else if (status == 'Late') {
              studentData[studentId]!['late'] =
                  (studentData[studentId]!['late'] as int) + 1;
            }
          }
        }

        for (var studentId in studentData.keys) {
          if (!studentsWithRecords.contains(studentId)) {
            studentData[studentId]!['absent'] =
                (studentData[studentId]!['absent'] as int) + 1;
          }
        }
      }

      List<Map<String, dynamic>> result = [];
      double totalPercentage = 0;

      for (var entry in studentData.entries) {
        final present = entry.value['present'] as int;
        final percentage = _totalDays > 0 ? (present / _totalDays) * 100 : 0;
        entry.value['percentage'] = percentage;
        totalPercentage += percentage;

        result.add({
          'studentId': entry.key,
          'name': entry.value['name'],
          'rollNo': entry.value['rollNo'],
          'present': entry.value['present'],
          'absent': entry.value['absent'],
          'late': entry.value['late'],
          'percentage': percentage,
        });
      }

      result.sort((a, b) => b['percentage'].compareTo(a['percentage']));
      _classAverage = _totalStudents > 0 ? totalPercentage / _totalStudents : 0;

      debugPrint('✅ Final data count: ${result.length}');

      setState(() {
        _attendanceData = result;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text(
          "Monthly Attendance - ${widget.className} ${widget.section}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed:
                _attendanceData.isNotEmpty && _totalDays > 0
                    ? _exportPDF
                    : null,
            tooltip: "Export PDF",
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _calculateAttendance,
            tooltip: "Refresh",
          ),
        ],
      ),
      body: _buildResponsiveBody(),
    );
  }

  Widget _buildResponsiveBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorState();
    }

    if (_totalDays == 0 || _attendanceData.isEmpty) {
      return _buildEmptyState();
    }

    // Responsive layout based on screen width
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;
        final isTablet =
            constraints.maxWidth > 600 && constraints.maxWidth <= 800;

        return RefreshIndicator(
          onRefresh: _calculateAttendance,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isDesktop ? 24 : 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - kToolbarHeight - 50,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMonthHeader(isDesktop),
                  const SizedBox(height: 16),
                  _buildSummaryCards(isDesktop, isTablet),
                  const SizedBox(height: 16),
                  _buildAttendanceChart(isDesktop),
                  const SizedBox(height: 20),
                  Text(
                    "Student-wise Attendance",
                    style: TextStyle(
                      fontSize: isDesktop ? 20 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildListHeader(),
                  const SizedBox(height: 8),
                  _buildStudentList(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              "Error Loading Data",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage,
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _calculateAttendance,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              "No Attendance Data",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "No attendance records found for ${DateFormat('MMMM yyyy').format(DateTime(widget.year, widget.month))}",
              style: TextStyle(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              "Please mark attendance first",
              style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _calculateAttendance,
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.indigo, Colors.indigoAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child:
          isDesktop
              ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Report Period",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Monthly Attendance Report",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat(
                          'MMMM yyyy',
                        ).format(DateTime(widget.year, widget.month)),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "$_totalDays Days",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
              : Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Report Period",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "$_totalDays Days",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat(
                      'MMMM yyyy',
                    ).format(DateTime(widget.year, widget.month)),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildSummaryCards(bool isDesktop, bool isTablet) {
    int totalPresent = _attendanceData.fold(
      0,
      (sum, student) => sum + (student['present'] as int),
    );
    int totalAbsent = _attendanceData.fold(
      0,
      (sum, student) => sum + (student['absent'] as int),
    );
    int totalLate = _attendanceData.fold(
      0,
      (sum, student) => sum + (student['late'] as int),
    );

    if (isDesktop) {
      return Row(
        children: [
          Expanded(
            child: _SummaryCard(
              title: "Class Average",
              value: "${_classAverage.toStringAsFixed(1)}%",
              color: Colors.indigo,
              icon: Icons.trending_up,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              title: "Total Present",
              value: totalPresent.toString(),
              color: Colors.green,
              icon: Icons.check_circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              title: "Total Absent",
              value: totalAbsent.toString(),
              color: Colors.red,
              icon: Icons.cancel,
            ),
          ),
          if (totalLate > 0) ...[
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: "Total Late",
                value: totalLate.toString(),
                color: Colors.orange,
                icon: Icons.access_time,
              ),
            ),
          ],
        ],
      );
    } else {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: isTablet ? 200 : double.infinity,
            child: _SummaryCard(
              title: "Class Average",
              value: "${_classAverage.toStringAsFixed(1)}%",
              color: Colors.indigo,
              icon: Icons.trending_up,
            ),
          ),
          SizedBox(
            width: isTablet ? 200 : double.infinity,
            child: _SummaryCard(
              title: "Total Present",
              value: totalPresent.toString(),
              color: Colors.green,
              icon: Icons.check_circle,
            ),
          ),
          SizedBox(
            width: isTablet ? 200 : double.infinity,
            child: _SummaryCard(
              title: "Total Absent",
              value: totalAbsent.toString(),
              color: Colors.red,
              icon: Icons.cancel,
            ),
          ),
          if (totalLate > 0)
            SizedBox(
              width: isTablet ? 200 : double.infinity,
              child: _SummaryCard(
                title: "Total Late",
                value: totalLate.toString(),
                color: Colors.orange,
                icon: Icons.access_time,
              ),
            ),
        ],
      );
    }
  }

  Widget _buildAttendanceChart(bool isDesktop) {
    if (_attendanceData.isEmpty) {
      return const SizedBox();
    }

    var topStudents = _attendanceData.take(10).toList();

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < topStudents.length; i++) {
      final double percentage = _safePercentage(topStudents[i]['percentage']);

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: percentage,
              color:
                  percentage >= 75
                      ? Colors.green
                      : (percentage >= 50 ? Colors.orange : Colors.red),
              width: isDesktop ? 30 : 25,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top 10 Students Performance',
            style: TextStyle(
              fontSize: isDesktop ? 18 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Attendance percentage by roll number',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: isDesktop ? 300 : 250,
            child: BarChart(
              BarChartData(
                barGroups: barGroups,
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                minY: 0,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 25,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < topStudents.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              topStudents[index]['rollNo']?.toString() ?? '',
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: true),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final studentName =
                          topStudents[groupIndex]['name']?.toString() ??
                          'Unknown';
                      final double perc = _safePercentage(
                        topStudents[groupIndex]['percentage'],
                      );
                      return BarTooltipItem(
                        '$studentName\n${perc.toStringAsFixed(1)}%',
                        const TextStyle(color: Colors.white, fontSize: 11),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader() {
    if (_attendanceData.isEmpty) {
      return const SizedBox();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 50,
            child: Text('Roll', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text(
              'Student Name',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              'Present',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text('Rate', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    if (_attendanceData.isEmpty) {
      return const SizedBox();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _attendanceData.length,
      itemBuilder: (context, index) {
        final student = _attendanceData[index];

        final double percentage = _safePercentage(student['percentage']);
        final present = student['present'] as int;
        final color =
            percentage >= 75
                ? Colors.green
                : (percentage >= 50 ? Colors.orange : Colors.red);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _showStudentDetails(student),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      student['rollNo']?.toString() ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      student['name']?.toString() ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(
                      "$present/$_totalDays",
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showStudentDetails(Map<String, dynamic> student) {
    final double percentage = _safePercentage(student['percentage']);
    final present = student['present'] as int? ?? 0;
    final absent = student['absent'] as int? ?? 0;
    final late = student['late'] as int? ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.indigo.shade100,
                          child: Text(
                            student['rollNo']?.toString() ?? '?',
                            style: TextStyle(
                              color: Colors.indigo.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student['name']?.toString() ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "${widget.className} - ${widget.section}",
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _DetailCard(
                            label: 'Present',
                            value: present.toString(),
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DetailCard(
                            label: 'Absent',
                            value: absent.toString(),
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DetailCard(
                            label: 'Rate',
                            value: '${percentage.toStringAsFixed(1)}%',
                            color: Colors.indigo,
                          ),
                        ),
                      ],
                    ),
                    if (late > 0) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _DetailCard(
                              label: 'Late',
                              value: late.toString(),
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Attendance Summary',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Out of $_totalDays working days',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Close"),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  Future<void> _exportPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build:
            (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Monthly Attendance Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  '${widget.className} - ${widget.section}',
                  style: pw.TextStyle(fontSize: 16),
                ),
                pw.Text(
                  DateFormat(
                    'MMMM yyyy',
                  ).format(DateTime(widget.year, widget.month)),
                  style: pw.TextStyle(fontSize: 14, color: PdfColors.grey),
                ),
                pw.Divider(),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Summary',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text('Total Students'),
                        pw.Text(
                          '${_attendanceData.length}',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text('Working Days'),
                        pw.Text(
                          '$_totalDays',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text('Class Average'),
                        pw.Text(
                          '${_classAverage.toStringAsFixed(1)}%',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Student-wise Attendance',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      children: [
                        _pdfHeaderCell('Roll No'),
                        _pdfHeaderCell('Student Name'),
                        _pdfHeaderCell('Present'),
                        _pdfHeaderCell('Percentage'),
                      ],
                    ),
                    ..._attendanceData.map((student) {
                      final double percentage = _safePercentage(
                        student['percentage'],
                      );
                      return pw.TableRow(
                        children: [
                          _pdfCell(student['rollNo']?.toString() ?? ''),
                          _pdfCell(student['name']?.toString() ?? 'Unknown'),
                          _pdfCell('${student['present']}/$_totalDays'),
                          _pdfCell('${percentage.toStringAsFixed(1)}%'),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ],
            ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  pw.Widget _pdfHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
    );
  }

  pw.Widget _pdfCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DetailCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
