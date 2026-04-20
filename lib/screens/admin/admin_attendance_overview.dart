import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminAttendanceOverviewPage extends StatefulWidget {
  final String schoolId;

  const AdminAttendanceOverviewPage({
    super.key,
    required this.schoolId,
  });

  @override
  State<AdminAttendanceOverviewPage> createState() => _AdminAttendanceOverviewPageState();
}

class _AdminAttendanceOverviewPageState extends State<AdminAttendanceOverviewPage> {
  DateTime selectedDate = DateTime.now();
  bool _isLoading = false;

  // Statistics
  int _totalStudents = 0;
  int _totalPresent = 0;
  int _totalAbsent = 0;
  int _totalLate = 0;
  double _attendanceRate = 0;

  Map<String, Map<String, dynamic>> _classStats = {};

  String get formattedDate => DateFormat('yyyy-MM-dd').format(selectedDate);
  String get displayDate => DateFormat('EEEE, dd MMMM yyyy').format(selectedDate);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text("Attendance Overview"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
            tooltip: "Select Date",
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: "Refresh",
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportReport,
            tooltip: "Export",
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Selector Card
          _buildDateSelector(),

          // Main Content
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('schools')
                  .doc(widget.schoolId)
                  .collection('attendance')
                  .doc(formattedDate)
                  .collection('records')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                _processRecords(snapshot.data!.docs);

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Card
                      _buildSummaryCard(),
                      const SizedBox(height: 20),

                      // Attendance Chart
                      _buildAttendanceChart(),
                      const SizedBox(height: 20),

                      // Class-wise Breakdown Header
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Class-wise Breakdown",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Tap to view details",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Class-wise List
                      ..._buildClassWiseList(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.calendar_today, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Report Date",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  displayDate,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (selectedDate != DateTime.now())
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Past Date",
                style: TextStyle(fontSize: 10, color: Colors.orange.shade700),
              ),
            ),
        ],
      ),
    );
  }

  void _processRecords(List<QueryDocumentSnapshot> records) {
    _totalStudents = records.length;
    _totalPresent = records.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['status'] == 'Present';
    }).length;
    _totalAbsent = records.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['status'] == 'Absent';
    }).length;
    _totalLate = records.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['status'] == 'Late';
    }).length;
    _attendanceRate = _totalStudents > 0 ? (_totalPresent / _totalStudents) * 100 : 0;

    // Process class-wise statistics
    _classStats.clear();

    for (var doc in records) {
      final data = doc.data() as Map<String, dynamic>;
      final className = data['className'] ?? 'Unknown';
      final section = data['section'] ?? '';
      final classKey = '$className - $section';
      final status = data['status'] ?? 'Absent';

      if (!_classStats.containsKey(classKey)) {
        _classStats[classKey] = {
          'className': className,
          'section': section,
          'total': 0,
          'present': 0,
          'absent': 0,
          'late': 0,
          'students': [],
        };
      }

      _classStats[classKey]!['total'] = (_classStats[classKey]!['total'] as int) + 1;

      if (status == 'Present') {
        _classStats[classKey]!['present'] = (_classStats[classKey]!['present'] as int) + 1;
      } else if (status == 'Late') {
        _classStats[classKey]!['late'] = (_classStats[classKey]!['late'] as int) + 1;
      } else {
        _classStats[classKey]!['absent'] = (_classStats[classKey]!['absent'] as int) + 1;
      }

      (_classStats[classKey]!['students'] as List).add({
        'name': data['name'] ?? 'Unknown',
        'rollNo': data['rollNo'] ?? '',
        'status': status,
        'checkInTime': data['checkInTime'],
        'checkOutTime': data['checkOutTime'],
      });
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No Attendance Records",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            "No attendance marked for ${DateFormat('dd MMM yyyy').format(selectedDate)}",
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),
          if (selectedDate != DateTime.now())
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  selectedDate = DateTime.now();
                });
              },
              icon: const Icon(Icons.today),
              label: const Text("View Today's Attendance"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blue, Colors.indigo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _topItem("Total", _totalStudents, Icons.groups),
              _topItem("Present", _totalPresent, Icons.check_circle),
              _topItem("Absent", _totalAbsent, Icons.cancel),
              if (_totalLate > 0) _topItem("Late", _totalLate, Icons.access_time),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: _attendanceRate / 100,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "${_attendanceRate.toStringAsFixed(1)}%",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Overall Attendance Rate",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceChart() {
    // Prepare data for pie chart
    final sections = <PieChartSectionData>[];

    if (_totalPresent > 0) {
      sections.add(
        PieChartSectionData(
          value: _totalPresent.toDouble(),
          title: '${((_totalPresent / _totalStudents) * 100).toStringAsFixed(0)}%',
          color: Colors.green,
          radius: 80,
          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (_totalAbsent > 0) {
      sections.add(
        PieChartSectionData(
          value: _totalAbsent.toDouble(),
          title: '${((_totalAbsent / _totalStudents) * 100).toStringAsFixed(0)}%',
          color: Colors.red,
          radius: 80,
          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (_totalLate > 0) {
      sections.add(
        PieChartSectionData(
          value: _totalLate.toDouble(),
          title: '${((_totalLate / _totalStudents) * 100).toStringAsFixed(0)}%',
          color: Colors.orange,
          radius: 80,
          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (sections.isEmpty) {
      sections.add(
         PieChartSectionData(
          value: 1,
          title: 'No Data',
          color: Colors.grey,
          radius: 80,
        ),
      );
    }

    return Container(
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
            "Attendance Distribution",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem(Colors.green, 'Present'),
              const SizedBox(width: 16),
              _legendItem(Colors.red, 'Absent'),
              if (_totalLate > 0) ...[
                const SizedBox(width: 16),
                _legendItem(Colors.orange, 'Late'),
              ],
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildClassWiseList() {
    List<Widget> widgets = [];

    // Sort classes by attendance rate
    var sortedClasses = _classStats.entries.toList();
    sortedClasses.sort((a, b) {
      double rateA = (a.value['present'] as int) / (a.value['total'] as int);
      double rateB = (b.value['present'] as int) / (b.value['total'] as int);
      return rateB.compareTo(rateA);
    });

    for (var entry in sortedClasses) {
      final classKey = entry.key;
      final data = entry.value;
      final total = data['total'] as int;
      final present = data['present'] as int;
      final absent = data['absent'] as int;
      final late = data['late'] as int;
      final percent = total > 0 ? (present / total) * 100 : 0;

      final color = percent >= 75
          ? Colors.green
          : (percent >= 50 ? Colors.orange : Colors.red);

      widgets.add(
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () => _showClassDetails(classKey, data),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.class_, color: color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              classKey,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "$present / $total Present",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${percent.toStringAsFixed(1)}%",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (late > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            "$late students arrived late",
                            style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  void _showClassDetails(String className, Map<String, dynamic> classData) {
    final students = List<Map<String, dynamic>>.from(classData['students']);
    final total = classData['total'] as int;
    final present = classData['present'] as int;
    final absent = classData['absent'] as int;
    final late = classData['late'] as int;
    final percent = total > 0 ? (present / total) * 100 : 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
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
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.class_, size: 30, color: Colors.blue),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            className,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            displayDate,
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
                      child: _detailStat('Total', total.toString(), Colors.blue),
                    ),
                    Expanded(
                      child: _detailStat('Present', present.toString(), Colors.green),
                    ),
                    Expanded(
                      child: _detailStat('Absent', absent.toString(), Colors.red),
                    ),
                    if (late > 0)
                      Expanded(
                        child: _detailStat('Late', late.toString(), Colors.orange),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Student List',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      final status = student['status'];
                      final statusColor = status == 'Present'
                          ? Colors.green
                          : (status == 'Late' ? Colors.orange : Colors.red);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: statusColor.withValues(alpha: 0.1),
                            child: Text(
                              student['rollNo'] ?? '?',
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(student['name']),
                          subtitle: student['checkInTime'] != null
                              ? Text('In: ${student['checkInTime']}')
                              : null,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
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

  Widget _topItem(String title, int value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 6),
        Text(
          value.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _detailStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
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
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      helpText: 'Select Date',
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _exportReport() async {
    if (_totalStudents == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export'), backgroundColor: Colors.orange),
      );
      return;
    }

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