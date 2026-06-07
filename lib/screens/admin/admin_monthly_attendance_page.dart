import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'Please log in to view attendance data';
          _isLoading = false;
        });
        return;
      }

      debugPrint('=== Starting Monthly Attendance Calculation ===');
      debugPrint('Class: ${widget.className}, Section: ${widget.section}');
      debugPrint('Month: ${widget.month}, Year: ${widget.year}');

      // Get all students in the class
      QuerySnapshot studentsSnapshot =
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

      if (studentsSnapshot.docs.isEmpty) {
        setState(() {
          _errorMessage =
              'No students found in class ${widget.className}-${widget.section}';
          _isLoading = false;
        });
        return;
      }

      // Build student data map
      Map<String, Map<String, dynamic>> studentData = {};
      for (var doc in studentsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        studentData[doc.id] = {
          'name': data['name'] ?? data['studentName'] ?? 'Unknown',
          'rollNo':
              data['rollNo']?.toString() ??
              data['rollNumber']?.toString() ??
              '',
          'present': 0,
          'absent': 0,
          'late': 0,
        };
      }
      _totalStudents = studentData.length;
      debugPrint('✅ Students found: $_totalStudents');

      // Use Collection Group query
      final recordsSnapshot =
          await FirebaseFirestore.instance.collectionGroup('records').get();

      debugPrint(
        '📊 Collection group total records: ${recordsSnapshot.docs.length}',
      );

      if (recordsSnapshot.docs.isEmpty) {
        setState(() {
          _errorMessage =
              'No attendance records found. Please mark attendance first.';
          _isLoading = false;
        });
        return;
      }

      // Filter and group records
      Map<String, List<Map<String, dynamic>>> recordsByDate = {};

      for (var doc in recordsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final date = data['date'] ?? '';
        final className = data['className'] ?? '';
        final section = data['section'] ?? '';

        if (className != widget.className || section != widget.section) {
          continue;
        }

        if (date.isEmpty) continue;

        final dateParts = date.split('-');
        if (dateParts.length >= 3) {
          final recordYear = int.tryParse(dateParts[0]);
          final recordMonth = int.tryParse(dateParts[1]);

          if (recordYear == widget.year && recordMonth == widget.month) {
            if (!recordsByDate.containsKey(date)) {
              recordsByDate[date] = [];
            }
            recordsByDate[date]!.add(data);
            debugPrint(
              '✅ Date: $date, Student: ${data['studentName']}, Status: ${data['status']}',
            );
          }
        }
      }

      _totalDays = recordsByDate.keys.length;
      debugPrint('📅 Days in selected month: $_totalDays');

      if (_totalDays == 0) {
        setState(() {
          _errorMessage =
              'No attendance records for ${DateFormat('MMMM yyyy').format(DateTime(widget.year, widget.month))}';
          _isLoading = false;
        });
        return;
      }

      // Process attendance
      for (var entry in recordsByDate.entries) {
        final records = entry.value;
        final studentsPresentOnDay = <String>{};

        for (var record in records) {
          final studentId = record['studentId'];
          final status = record['status'] ?? 'Absent';

          if (studentId != null && studentData.containsKey(studentId)) {
            studentsPresentOnDay.add(studentId);

            if (status == 'Present') {
              studentData[studentId]!['present'] =
                  (studentData[studentId]!['present'] as int) + 1;
            } else if (status == 'Late') {
              studentData[studentId]!['late'] =
                  (studentData[studentId]!['late'] as int) + 1;
            } else {
              studentData[studentId]!['absent'] =
                  (studentData[studentId]!['absent'] as int) + 1;
            }
          }
        }

        for (var studentId in studentData.keys) {
          if (!studentsPresentOnDay.contains(studentId)) {
            studentData[studentId]!['absent'] =
                (studentData[studentId]!['absent'] as int) + 1;
          }
        }
      }

      // Calculate percentages
      List<Map<String, dynamic>> result = [];
      double totalPercentage = 0;

      for (var entry in studentData.entries) {
        final present = entry.value['present'] as int;
        final percentage = _totalDays > 0 ? (present / _totalDays) * 100 : 0;
        totalPercentage += percentage;

        result.add({
          'studentId': entry.key,
          'name': entry.value['name'],
          'rollNo': entry.value['rollNo'],
          'present': present,
          'absent': entry.value['absent'],
          'late': entry.value['late'],
          'percentage': percentage,
        });
      }

      result.sort(
        (a, b) =>
            (b['percentage'] as double).compareTo(a['percentage'] as double),
      );
      _classAverage = _totalStudents > 0 ? totalPercentage / _totalStudents : 0;

      debugPrint('✅ Class Average: ${_classAverage.toStringAsFixed(1)}%');
      debugPrint('✅ Total days: $_totalDays');

      setState(() {
        _attendanceData = result;
        _isLoading = false;
        _errorMessage = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Found $_totalDays days of attendance records'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error: $e');
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
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
                      final double percentage = student['percentage'];
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(_errorMessage, textAlign: TextAlign.center),
              const SizedBox(height: 24),
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

    if (_attendanceData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              "No Attendance Data",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "No attendance records found for ${DateFormat('MMMM yyyy').format(DateTime(widget.year, widget.month))}",
              textAlign: TextAlign.center,
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
      );
    }

    return RefreshIndicator(
      onRefresh: _calculateAttendance,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildStats(),
            const SizedBox(height: 20),
            _buildChart(),
            const SizedBox(height: 20),
            const Text(
              "Student-wise Attendance",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildStudentList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.indigo, Colors.indigoAccent],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Report Period",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              SizedBox(height: 4),
              Text(
                "Monthly Attendance",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
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
                  fontSize: 16,
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
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "$_totalDays Days",
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
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

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: "Class Average",
            value: "${_classAverage.toStringAsFixed(1)}%",
            color: Colors.indigo,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: "Total Present",
            value: totalPresent.toString(),
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: "Total Absent",
            value: totalAbsent.toString(),
            color: Colors.red,
          ),
        ),
        if (totalLate > 0)
          Expanded(
            child: _StatCard(
              title: "Total Late",
              value: totalLate.toString(),
              color: Colors.orange,
            ),
          ),
      ],
    );
  }

  Widget _buildChart() {
    final topStudents = _attendanceData.take(10).toList();
    final barGroups = <BarChartGroupData>[];

    for (int i = 0; i < topStudents.length; i++) {
      final percentage = topStudents[i]['percentage'];
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
              width: 25,
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
          const Text(
            "Top 10 Students Performance",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Attendance percentage by roll number',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
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
                      getTitlesWidget:
                          (value, meta) => Text(
                            '${value.toInt()}%',
                            style: const TextStyle(fontSize: 10),
                          ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
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
                      final double perc = topStudents[groupIndex]['percentage'];
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

  Widget _buildStudentList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _attendanceData.length,
      itemBuilder: (context, index) {
        final student = _attendanceData[index];
        final double percentage = student['percentage'];
        final present = student['present'] as int;
        final color =
            percentage >= 75
                ? Colors.green
                : (percentage >= 50 ? Colors.orange : Colors.red);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _showStudentDetails(student),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        student['rollNo']?.toString() ?? '?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student['name']?.toString() ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          "$present / $_totalDays days present",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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
    final double percentage = student['percentage'];
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
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.8,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Attendance Summary',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
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
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
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
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}
