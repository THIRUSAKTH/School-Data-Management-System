import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AttendanceMonthlyReportPage extends StatefulWidget {
  final String schoolId;

  const AttendanceMonthlyReportPage({super.key, required this.schoolId});

  @override
  State<AttendanceMonthlyReportPage> createState() =>
      _AttendanceMonthlyReportPageState();
}

class _AttendanceMonthlyReportPageState
    extends State<AttendanceMonthlyReportPage> {
  String selectedClass = "";
  String selectedSection = "A";
  DateTime selectedMonth = DateTime.now();
  bool _isLoading = false;

  List<String> _availableClasses = [];
  List<String> _availableSections = ['A', 'B', 'C', 'D'];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);

    try {
      final classesSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('classes')
              .get();

      setState(() {
        _availableClasses =
            classesSnapshot.docs
                .map(
                  (doc) =>
                      doc['className'] as String? ??
                      doc['class'] as String? ??
                      '',
                )
                .where((name) => name.isNotEmpty)
                .toList();

        if (_availableClasses.isNotEmpty) {
          selectedClass = _availableClasses.first;
          _loadSections(selectedClass);
        }
      });
    } catch (e) {
      debugPrint('Error loading classes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSections(String className) async {
    try {
      final studentsSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('students')
              .where('class', isEqualTo: className)
              .get();

      final sectionsSet = <String>{};
      for (var doc in studentsSnapshot.docs) {
        final section = doc['section'] as String?;
        if (section != null && section.isNotEmpty) {
          sectionsSet.add(section);
        }
      }

      setState(() {
        _availableSections = sectionsSet.toList()..sort();
        if (_availableSections.isNotEmpty) {
          selectedSection = _availableSections.first;
        } else {
          _availableSections = ['A', 'B', 'C', 'D'];
          selectedSection = 'A';
        }
      });
    } catch (e) {
      debugPrint('Error loading sections: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          "Monthly Attendance Report",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: "Refresh",
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [_buildFilters(), Expanded(child: _buildReport())],
              ),
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          // Month Selector
          GestureDetector(
            onTap: _pickMonth,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month,
                    size: 18,
                    color: Colors.indigo,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Select Month",
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        Text(
                          DateFormat('MMMM yyyy').format(selectedMonth),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.indigo),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Class Selector
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Class",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedClass.isEmpty ? null : selectedClass,
                          hint: const Text("Select Class"),
                          isExpanded: true,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.indigo,
                          ),
                          items:
                              _availableClasses.map((className) {
                                return DropdownMenuItem(
                                  value: className,
                                  child: Text(
                                    className,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedClass = value!;
                              _loadSections(selectedClass);
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Section",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedSection,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.indigo,
                          ),
                          items:
                              _availableSections.map((section) {
                                return DropdownMenuItem(
                                  value: section,
                                  child: Text(
                                    section,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedSection = value!;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReport() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _generateReport(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text(
                  "Error loading report",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          );
        }

        final report = snapshot.data;

        if (report == null || report.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  "No attendance data found",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "for ${DateFormat('MMMM yyyy').format(selectedMonth)}",
                  style: TextStyle(color: Colors.grey.shade500),
                ),
                const SizedBox(height: 16),
                Text(
                  "Selected Class: ${selectedClass.isEmpty ? 'None' : selectedClass}",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          );
        }

        // Calculate overall statistics
        int totalPresent = 0;
        int totalDays = 0;
        for (var entry in report.entries) {
          final data = entry.value;
          totalPresent += data['present'] as int;
          totalDays += data['total'] as int;
        }
        double overallPercentage =
            totalDays > 0 ? (totalPresent / totalDays) * 100 : 0;

        return Column(
          children: [
            _buildOverallStatsCard(totalPresent, totalDays, overallPercentage),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: report.entries.length,
                itemBuilder: (context, index) {
                  final entry = report.entries.elementAt(index);
                  final data = entry.value;
                  return _buildStudentCard(
                    name: data['name'],
                    rollNo: data['rollNo'],
                    present: data['present'] as int,
                    total: data['total'] as int,
                    percentage: data['percentage'] as double,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOverallStatsCard(int present, int total, double percentage) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.indigo, Colors.deepPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Overall Attendance",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            "${percentage.toStringAsFixed(1)}%",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "$present out of $total days present",
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _overallStat("Present", present.toString(), Colors.green),
              _overallStat("Total Days", total.toString(), Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _overallStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildStudentCard({
    required String name,
    required String rollNo,
    required int present,
    required int total,
    required double percentage,
  }) {
    Color getPercentageColor() {
      if (percentage >= 90) return Colors.green;
      if (percentage >= 75) return Colors.lightGreen;
      if (percentage >= 60) return Colors.orange;
      if (percentage >= 40) return Colors.deepOrange;
      return Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: getPercentageColor().withOpacity(0.1),
          child: Text(
            rollNo,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: getPercentageColor(),
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          "Present: $present / $total days",
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: getPercentageColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "${percentage.toStringAsFixed(1)}%",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: getPercentageColor(),
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _generateReport() async {
    final Map<String, dynamic> report = {};

    try {
      // Get all attendance records for the selected month
      final startDate = DateTime(selectedMonth.year, selectedMonth.month, 1);
      final endDate = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);

      // Get all attendance documents in the date range
      final attendanceSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('attendance')
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

      // Get all students in the selected class
      final studentsSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('students')
              .where('class', isEqualTo: selectedClass)
              .where('section', isEqualTo: selectedSection)
              .get();

      // Initialize report for each student
      for (var student in studentsSnapshot.docs) {
        final data = student.data();
        report[student.id] = {
          'name': data['name'] ?? 'Student',
          'rollNo': data['rollNo']?.toString() ?? '',
          'present': 0,
          'total': 0,
        };
      }

      // Process each attendance date
      for (var dateDoc in attendanceSnapshot.docs) {
        final recordsSnapshot =
            await dateDoc.reference
                .collection('records')
                .where('className', isEqualTo: selectedClass)
                .where('section', isEqualTo: selectedSection)
                .get();

        for (var record in recordsSnapshot.docs) {
          final data = record.data();
          final studentId = record.id;
          final status = data['status'] ?? 'Absent';

          if (report.containsKey(studentId)) {
            final studentReport = report[studentId] as Map<String, dynamic>;
            final currentTotal = studentReport['total'] as int;
            final currentPresent = studentReport['present'] as int;

            studentReport['total'] = currentTotal + 1;
            if (status == 'Present' || status == 'Late') {
              studentReport['present'] = currentPresent + 1;
            }
          }
        }
      }

      // Calculate percentages
      for (var entry in report.entries) {
        final studentReport = entry.value as Map<String, dynamic>;
        final present = studentReport['present'] as int;
        final total = studentReport['total'] as int;
        studentReport['percentage'] = total > 0 ? (present / total) * 100 : 0.0;
      }

      // Remove students with no records
      report.removeWhere(
        (key, value) => (value as Map<String, dynamic>)['total'] == 0,
      );
    } catch (e) {
      debugPrint('Error generating report: $e');
    }

    return report;
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != selectedMonth) {
      setState(() {
        selectedMonth = picked;
      });
    }
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }
}
