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
  State<AdminMonthlyAttendancePage> createState() => _AdminMonthlyAttendancePageState();
}

class _AdminMonthlyAttendancePageState extends State<AdminMonthlyAttendancePage> {
  List<Map<String, dynamic>> _attendanceData = [];
  bool _isLoading = true;
  double _classAverage = 0;
  int _totalDays = 0;
  int _totalStudents = 0;

  @override
  void initState() {
    super.initState();
    _calculateAttendance();
  }

  Future<void> _calculateAttendance() async {
    setState(() => _isLoading = true);

    try {
      final attendanceRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('attendance');

      // Get all attendance documents for the month
      final startDate = DateTime(widget.year, widget.month, 1);
      final endDate = DateTime(widget.year, widget.month + 1, 0);

      final snapshot = await attendanceRef
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(startDate))
          .where(FieldPath.documentId, isLessThanOrEqualTo: DateFormat('yyyy-MM-dd').format(endDate))
          .get();

      // Get all students in the class
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('students')
          .where('class', isEqualTo: widget.className)
          .where('section', isEqualTo: widget.section)
          .get();

      Map<String, Map<String, dynamic>> studentData = {};

      // Initialize student data
      for (var doc in studentsSnapshot.docs) {
        final data = doc.data();
        studentData[doc.id] = {
          'name': data['name'] ?? 'Unknown',
          'rollNo': data['rollNo'] ?? '',
          'present': 0,
          'absent': 0,
          'late': 0,
          'percentage': 0.0,
        };
      }

      _totalStudents = studentData.length;
      _totalDays = snapshot.docs.length;

      // Process attendance records using records subcollection
      for (var dateDoc in snapshot.docs) {
        final recordsSnapshot = await dateDoc.reference
            .collection('records')
            .get();

        // Track which students have records for this day
        Set<String> studentsWithRecords = {};

        for (var recordDoc in recordsSnapshot.docs) {
          final recordData = recordDoc.data();
          final studentId = recordData['studentId'];
          final status = recordData['status'] ?? 'Absent';

          if (studentId != null && studentData.containsKey(studentId)) {
            studentsWithRecords.add(studentId);

            if (status == 'Present') {
              studentData[studentId]!['present'] = (studentData[studentId]!['present'] as int) + 1;
            } else if (status == 'Late') {
              studentData[studentId]!['late'] = (studentData[studentId]!['late'] as int) + 1;
            }
          }
        }

        // For students without records on this date, mark as absent
        for (var studentId in studentData.keys) {
          if (!studentsWithRecords.contains(studentId)) {
            studentData[studentId]!['absent'] = (studentData[studentId]!['absent'] as int) + 1;
          }
        }
      }

      // Calculate percentages
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

      // Sort by percentage (highest first)
      result.sort((a, b) => b['percentage'].compareTo(a['percentage']));

      _classAverage = _totalStudents > 0 ? totalPercentage / _totalStudents : 0;

      setState(() {
        _attendanceData = result;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error calculating attendance: $e');
      setState(() => _isLoading = false);
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
            onPressed: _exportPDF,
            tooltip: "Export PDF",
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _calculateAttendance,
            tooltip: "Refresh",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _attendanceData.isEmpty
          ? _buildEmptyState()
          : Column(
        children: [
          _buildMonthHeader(),
          _buildSummaryCards(),
          _buildAttendanceChart(),
          _buildListHeader(),
          Expanded(
            child: _buildStudentList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No Attendance Data",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            "No attendance records found for ${DateFormat('MMMM yyyy').format(DateTime(widget.year, widget.month))}",
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.indigo, Colors.indigoAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Report Period",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            DateFormat('MMMM yyyy').format(DateTime(widget.year, widget.month)),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "$_totalDays Days",
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    int totalPresent = _attendanceData.fold(0, (sum, student) => sum + (student['present'] as int));
    int totalAbsent = _attendanceData.fold(0, (sum, student) => sum + (student['absent'] as int));
    int totalLate = _attendanceData.fold(0, (sum, student) => sum + (student['late'] as int));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
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
        ],
      ),
    );
  }

  Widget _buildAttendanceChart() {
    var topStudents = _attendanceData.take(10).toList();

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < topStudents.length; i++) {
      final percentage = topStudents[i]['percentage'] as double;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: percentage,
              color: percentage >= 75 ? Colors.green : (percentage >= 50 ? Colors.orange : Colors.red),
              width: 25,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top 10 Students Performance',
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
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toInt()}%', style: const TextStyle(fontSize: 10));
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
                              topStudents[index]['rollNo'] ?? '',
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: true),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${topStudents[groupIndex]['name']}\n${(topStudents[groupIndex]['percentage'] as double).toStringAsFixed(1)}%',
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
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          SizedBox(width: 50, child: Text('Roll', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 60, child: Text('Present', style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 60, child: Text('Rate', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _attendanceData.length,
      itemBuilder: (context, index) {
        final student = _attendanceData[index];
        final percentage = student['percentage'] as double;
        final present = student['present'] as int;
        final color = percentage >= 75
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
                      student['rollNo'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      student['name'],
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    final percentage = student['percentage'] as double;
    final present = student['present'] as int;
    final absent = student['absent'] as int;
    final late = student['late'] as int;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
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
                        student['rollNo'] ?? '?',
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
                            student['name'],
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
                              style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
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
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Monthly Attendance Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              '${widget.className} - ${widget.section}',
              style: pw.TextStyle(fontSize: 16),
            ),
            pw.Text(
              DateFormat('MMMM yyyy').format(DateTime(widget.year, widget.month)),
              style: pw.TextStyle(fontSize: 14, color: PdfColors.grey),
            ),
            pw.Divider(),
            pw.SizedBox(height: 20),
            pw.Text(
              'Summary',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    pw.Text('Total Students'),
                    pw.Text('${_attendanceData.length}',
                        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text('Working Days'),
                    pw.Text('$_totalDays',
                        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text('Class Average'),
                    pw.Text('${_classAverage.toStringAsFixed(1)}%',
                        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Student-wise Attendance',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
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
                  final percentage = student['percentage'] as double;
                  return pw.TableRow(
                    children: [
                      _pdfCell(student['rollNo'] ?? ''),
                      _pdfCell(student['name']),
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

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
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
}

// ================= HELPER WIDGETS =================

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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
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
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}