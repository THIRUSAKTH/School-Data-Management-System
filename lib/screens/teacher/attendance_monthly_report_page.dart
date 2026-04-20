import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class AttendanceMonthlyReportPage extends StatefulWidget {
  final String schoolId;

  const AttendanceMonthlyReportPage({
    super.key,
    required this.schoolId,
  });

  @override
  State<AttendanceMonthlyReportPage> createState() =>
      _AttendanceMonthlyReportPageState();
}

class _AttendanceMonthlyReportPageState
    extends State<AttendanceMonthlyReportPage> {
  String? selectedClass;
  String? selectedSection;
  DateTime selectedMonth = DateTime.now();
  bool _isLoading = true;

  List<String> _availableClasses = [];
  List<String> _availableSections = [];

  Map<String, dynamic> _reportData = {};
  List<Map<String, dynamic>> _studentsList = [];

  // Statistics
  int _totalStudents = 0;
  double _overallAttendanceRate = 0;
  int _totalPresentDays = 0;
  int _totalWorkingDays = 0;

  @override
  void initState() {
    super.initState();
    _loadAvailableClasses();
  }

  Future<void> _loadAvailableClasses() async {
    try {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('students')
          .get();

      final Set<String> classesSet = {};
      final Map<String, Set<String>> classSectionsMap = {};

      for (var doc in studentsSnapshot.docs) {
        final data = doc.data();
        final className = data['class'] as String?;
        final section = data['section'] as String?;

        if (className != null && className.isNotEmpty) {
          classesSet.add(className);

          if (section != null && section.isNotEmpty) {
            if (!classSectionsMap.containsKey(className)) {
              classSectionsMap[className] = {};
            }
            classSectionsMap[className]!.add(section);
          }
        }
      }

      setState(() {
        _availableClasses = classesSet.toList()..sort();
        if (_availableClasses.isNotEmpty) {
          selectedClass = _availableClasses.first;
          _availableSections = classSectionsMap[selectedClass]?.toList() ?? [];
          if (_availableSections.isNotEmpty) {
            selectedSection = _availableSections.first;
          }
        }
        _isLoading = false;
      });

      if (selectedClass != null && selectedSection != null) {
        await _generateReport();
      }
    } catch (e) {
      debugPrint('Error loading classes: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSectionsForClass(String className) async {
    try {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('students')
          .where('class', isEqualTo: className)
          .get();

      final Set<String> sectionsSet = {};

      for (var doc in studentsSnapshot.docs) {
        final data = doc.data();
        final section = data['section'] as String?;
        if (section != null && section.isNotEmpty) {
          sectionsSet.add(section);
        }
      }

      setState(() {
        _availableSections = sectionsSet.toList()..sort();
        if (_availableSections.isNotEmpty) {
          selectedSection = _availableSections.first;
        }
      });

      await _generateReport();
    } catch (e) {
      debugPrint('Error loading sections: $e');
    }
  }

  Future<void> _generateReport() async {
    if (selectedClass == null || selectedSection == null) return;

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> report = {};
      final monthStart = DateTime(selectedMonth.year, selectedMonth.month, 1);
      final monthEnd = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);

      // Get all attendance records for the month
      final attendanceSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('attendance')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(monthStart))
          .where(FieldPath.documentId, isLessThanOrEqualTo: DateFormat('yyyy-MM-dd').format(monthEnd))
          .get();

      // Get all students in the class
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('students')
          .where('class', isEqualTo: selectedClass)
          .where('section', isEqualTo: selectedSection)
          .get();

      // Initialize report for each student
      for (var doc in studentsSnapshot.docs) {
        final data = doc.data();
        report[doc.id] = {
          'name': data['name'] ?? 'Unknown',
          'rollNo': data['rollNo'] ?? '',
          'present': 0,
          'absent': 0,
          'late': 0,
          'total': 0,
          'attendanceRecords': [],
        };
      }

      // Process attendance records
      for (var doc in attendanceSnapshot.docs) {
        final date = doc.id;
        final records = doc.data() as Map<String, dynamic>;

        // Find records for this class/section
        for (var studentId in report.keys) {
          if (records.containsKey(studentId)) {
            final studentRecord = records[studentId] as Map<String, dynamic>;
            final status = studentRecord['status'] ?? 'Absent';

            // FIXED: Proper type casting for totals
            int currentTotal = (report[studentId]['total'] as int?) ?? 0;
            report[studentId]['total'] = currentTotal + 1;

            if (status == 'Present') {
              int currentPresent = (report[studentId]['present'] as int?) ?? 0;
              report[studentId]['present'] = currentPresent + 1;
            } else if (status == 'Late') {
              int currentLate = (report[studentId]['late'] as int?) ?? 0;
              report[studentId]['late'] = currentLate + 1;
            } else {
              int currentAbsent = (report[studentId]['absent'] as int?) ?? 0;
              report[studentId]['absent'] = currentAbsent + 1;
            }

            (report[studentId]['attendanceRecords'] as List).add({
              'date': date,
              'status': status,
            });
          }
        }
      }

      // Calculate percentages
      List<Map<String, dynamic>> studentsList = [];
      int totalPresentSum = 0;
      int totalDaysSum = 0;

      for (var entry in report.entries) {
        final present = (entry.value['present'] as int?) ?? 0;
        final total = (entry.value['total'] as int?) ?? 0;
        final late = (entry.value['late'] as int?) ?? 0;
        final absent = (entry.value['absent'] as int?) ?? 0;

        totalPresentSum += present;
        totalDaysSum += total;

        final percentage = total > 0 ? (present / total) * 100 : 0.0;

        studentsList.add({
          'id': entry.key,
          'name': entry.value['name'],
          'rollNo': entry.value['rollNo'],
          'present': present,
          'absent': absent,
          'late': late,
          'total': total,
          'percentage': percentage,
          'attendanceRecords': entry.value['attendanceRecords'],
        });
      }

      // Sort by percentage (highest first) then by roll number
      studentsList.sort((a, b) {
        if (a['percentage'] != b['percentage']) {
          return b['percentage'].compareTo(a['percentage']);
        }
        return (a['rollNo'] as String).compareTo(b['rollNo'] as String);
      });

      _totalStudents = studentsList.length;
      _overallAttendanceRate = totalDaysSum > 0 ? (totalPresentSum / totalDaysSum) * 100 : 0;
      _totalPresentDays = totalPresentSum;
      _totalWorkingDays = totalDaysSum;

      setState(() {
        _reportData = report;
        _studentsList = studentsList;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error generating report: $e');
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
        title: const Text("Monthly Attendance Report"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _selectMonth,
            tooltip: "Select Month",
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportReport,
            tooltip: "Export Report",
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _generateReport,
            tooltip: "Refresh",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Filters
          _buildFilters(),

          // Month Header
          _buildMonthHeader(),

          // Statistics Cards
          _buildStatisticsCards(),

          // Attendance Chart
          if (_studentsList.isNotEmpty) _buildAttendanceChart(),

          // Students List Header
          _buildListHeader(),

          // Students List
          Expanded(
            child: _buildStudentsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
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
      child: Row(
        children: [
          Expanded(
            child: _buildClassDropdown(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSectionDropdown(),
          ),
        ],
      ),
    );
  }

  Widget _buildClassDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedClass,
      decoration: const InputDecoration(
        labelText: "Select Class",
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: _availableClasses.map((className) {
        return DropdownMenuItem(
          value: className,
          child: Text(className),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedClass = value;
          if (value != null) {
            _loadSectionsForClass(value);
          }
        });
      },
    );
  }

  Widget _buildSectionDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedSection,
      decoration: const InputDecoration(
        labelText: "Select Section",
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: _availableSections.map((section) {
        return DropdownMenuItem(
          value: section,
          child: Text(section),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedSection = value;
        });
        _generateReport();
      },
    );
  }

  Widget _buildMonthHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.indigo, Colors.indigoAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Report Period",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            DateFormat('MMMM yyyy').format(selectedMonth),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: () {
                  setState(() {
                    selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
                  });
                  _generateReport();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                onPressed: () {
                  setState(() {
                    selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
                  });
                  _generateReport();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _StatsCard(
              title: "Total Students",
              value: _totalStudents.toString(),
              color: Colors.blue,
              icon: Icons.people,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatsCard(
              title: "Overall Rate",
              value: "${_overallAttendanceRate.toStringAsFixed(1)}%",
              color: Colors.green,
              icon: Icons.trending_up,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatsCard(
              title: "Working Days",
              value: _totalWorkingDays.toString(),
              color: Colors.orange,
              icon: Icons.calendar_today,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceChart() {
    if (_studentsList.isEmpty) return const SizedBox.shrink();

    // Get top 10 students for chart
    var topStudents = _studentsList.take(10).toList();

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < topStudents.length; i++) {
      final percentage = topStudents[i]['percentage'] as double;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: percentage,
              color: percentage >= 75 ? Colors.green : Colors.orange,
              width: 25,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top 10 Students Performance',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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

  Widget _buildStudentsList() {
    if (_studentsList.isEmpty) {
      return const Center(
        child: Text("No students found for this class"),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _studentsList.length,
      itemBuilder: (context, index) {
        final student = _studentsList[index];
        final percentage = student['percentage'] as double;
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
                      '${student['present']}/${student['total']}',
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
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showStudentDetails(Map<String, dynamic> student) {
    final records = List<Map<String, dynamic>>.from(student['attendanceRecords']);
    records.sort((a, b) => b['date'].compareTo(a['date']));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
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
                        student['rollNo'] ?? '',
                        style: TextStyle(color: Colors.indigo.shade700, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student['name'],
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '$selectedClass - $selectedSection',
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
                      child: _DetailStat(
                        label: 'Present',
                        value: '${student['present']}',
                        color: Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _DetailStat(
                        label: 'Absent',
                        value: '${student['absent']}',
                        color: Colors.red,
                      ),
                    ),
                    Expanded(
                      child: _DetailStat(
                        label: 'Late',
                        value: '${student['late']}',
                        color: Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _DetailStat(
                        label: 'Rate',
                        value: '${(student['percentage'] as double).toStringAsFixed(1)}%',
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Daily Records',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final record = records[index];
                      final date = DateTime.parse(record['date']);
                      final status = record['status'];
                      final statusColor = status == 'Present'
                          ? Colors.green
                          : (status == 'Late' ? Colors.orange : Colors.red);

                      return ListTile(
                        leading: Icon(
                          status == 'Present' ? Icons.check_circle : Icons.cancel,
                          color: statusColor,
                        ),
                        title: Text(DateFormat('EEEE, dd MMM yyyy').format(date)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _selectMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      helpText: 'Select Month',
    );

    if (picked != null && picked != selectedMonth) {
      setState(() {
        selectedMonth = picked;
      });
      await _generateReport();
    }
  }

  Future<void> _exportReport() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Export Report',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Export as PDF'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF export coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Export as Excel'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Excel export coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ================= HELPER WIDGETS =================

class _StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatsCard({
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

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DetailStat({
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
              fontSize: 20,
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