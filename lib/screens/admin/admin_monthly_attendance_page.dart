import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

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
      // Get students using direct path (NO INDEX NEEDED)
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
          _errorMessage = 'No students found in class';
          _isLoading = false;
        });
        return;
      }

      // Build student data map
      Map<String, Map<String, dynamic>> studentData = {};
      for (var doc in studentsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        studentData[doc.id] = {
          'name': data['name'] ?? 'Unknown',
          'rollNo': data['rollNo']?.toString() ?? '',
          'present': 0,
          'absent': 0,
          'late': 0,
        };
      }
      _totalStudents = studentData.length;

      // Get ALL attendance documents from direct path (NO INDEX NEEDED)
      final attendanceDocs =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('attendance')
              .get();

      print('📊 Total attendance docs: ${attendanceDocs.docs.length}');

      if (attendanceDocs.docs.isEmpty) {
        setState(() {
          _errorMessage =
              'No attendance records found. Please mark attendance first.';
          _isLoading = false;
        });
        return;
      }

      // Print all document IDs for debugging
      for (var doc in attendanceDocs.docs) {
        print('📁 Document ID: ${doc.id}');
      }

      // Filter documents for the selected month
      final targetMonth =
          '${widget.year}-${widget.month.toString().padLeft(2, '0')}';
      final validDates = <String>[];

      for (var doc in attendanceDocs.docs) {
        if (doc.id.startsWith(targetMonth)) {
          validDates.add(doc.id);
          print('✅ Matched: ${doc.id}');
        }
      }

      _totalDays = validDates.length;
      print('📅 Days in month: $_totalDays');

      if (_totalDays == 0) {
        setState(() {
          _errorMessage =
              'No attendance for ${DateFormat('MMMM yyyy').format(DateTime(widget.year, widget.month))}';
          _isLoading = false;
        });
        return;
      }

      // Process each date's attendance
      for (String date in validDates) {
        final records =
            await FirebaseFirestore.instance
                .collection('schools')
                .doc(widget.schoolId)
                .collection('attendance')
                .doc(date)
                .collection('records')
                .get();

        print('📝 $date: ${records.docs.length} records');

        final presentStudents = <String>{};

        for (var record in records.docs) {
          final data = record.data();
          final studentId = record.id;
          final status = data['status'] ?? 'Absent';

          if (studentData.containsKey(studentId)) {
            presentStudents.add(studentId);
            if (status == 'Present') {
              studentData[studentId]!['present']++;
            } else if (status == 'Late') {
              studentData[studentId]!['late']++;
            }
          }
        }

        // Mark absent for students without records
        for (var studentId in studentData.keys) {
          if (!presentStudents.contains(studentId)) {
            studentData[studentId]!['absent']++;
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

      result.sort((a, b) => b['percentage'].compareTo(a['percentage']));
      _classAverage = _totalStudents > 0 ? totalPercentage / _totalStudents : 0;

      setState(() {
        _attendanceData = result;
        _isLoading = false;
        _errorMessage = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Found $_totalDays days of attendance'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text(
          "Monthly Attendance - ${widget.className} ${widget.section}",
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _calculateAttendance,
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
            Icon(Icons.history, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text("No Attendance Data", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _calculateAttendance,
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh"),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
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
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.indigo, Colors.indigoAccent],
        ),
        borderRadius: BorderRadius.circular(16),
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
              Text(
                "Monthly Attendance",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white24,
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
      (sum, s) => sum + (s['present'] as int),
    );
    int totalAbsent = _attendanceData.fold(
      0,
      (sum, s) => sum + (s['absent'] as int),
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
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const Text(
            "Top 10 Students",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                barGroups: barGroups,
                maxY: 100,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 25,
                      getTitlesWidget: (v, m) => Text('${v.toInt()}%'),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, m) {
                        final i = v.toInt();
                        return i < topStudents.length
                            ? Text(
                              topStudents[i]['rollNo'] ?? '',
                              style: const TextStyle(fontSize: 10),
                            )
                            : const Text('');
                      },
                    ),
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
        final s = _attendanceData[index];
        final percentage = s['percentage'];
        final color =
            percentage >= 75
                ? Colors.green
                : (percentage >= 50 ? Colors.orange : Colors.red);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Text(
                s['rollNo'] ?? '?',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(s['name']),
            subtitle: Text("${s['present']}/$_totalDays days present"),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${percentage.toStringAsFixed(1)}%",
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
