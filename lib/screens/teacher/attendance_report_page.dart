import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class AttendanceReportPage extends StatefulWidget {
  final String schoolId;

  const AttendanceReportPage({
    super.key,
    required this.schoolId,
  });

  @override
  State<AttendanceReportPage> createState() => _AttendanceReportPageState();
}

class _AttendanceReportPageState extends State<AttendanceReportPage> {
  DateTime selectedDate = DateTime.now();
  bool _isLoading = false;

  // Statistics
  int _totalClasses = 0;
  int _totalStudents = 0;
  int _totalPresent = 0;
  int _totalAbsent = 0;
  double _overallRate = 0;

  List<Map<String, dynamic>> _classData = [];

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  String get formattedDate => DateFormat('yyyy-MM-dd').format(selectedDate);

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);

    try {
      // Get attendance for selected date
      final attendanceDoc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('attendance')
          .doc(formattedDate)
          .collection('records')
          .get();

      if (attendanceDoc.docs.isEmpty) {
        setState(() {
          _classData = [];
          _totalClasses = 0;
          _totalStudents = 0;
          _totalPresent = 0;
          _totalAbsent = 0;
          _overallRate = 0;
          _isLoading = false;
        });
        return;
      }

      // Group by class and section
      Map<String, Map<String, dynamic>> classMap = {};

      for (var doc in attendanceDoc.docs) {
        final data = doc.data();
        final className = data['className'] ?? 'Unknown';
        final section = data['section'] ?? '';
        final classKey = '$className - $section';
        final status = data['status'] ?? 'Absent';

        if (!classMap.containsKey(classKey)) {
          classMap[classKey] = {
            'className': className,
            'section': section,
            'total': 0,
            'present': 0,
            'absent': 0,
            'late': 0,
            'students': [],
          };
        }

        classMap[classKey]!['total'] = (classMap[classKey]!['total'] as int) + 1;

        if (status == 'Present') {
          classMap[classKey]!['present'] = (classMap[classKey]!['present'] as int) + 1;
        } else if (status == 'Late') {
          classMap[classKey]!['late'] = (classMap[classKey]!['late'] as int) + 1;
        } else {
          classMap[classKey]!['absent'] = (classMap[classKey]!['absent'] as int) + 1;
        }

        (classMap[classKey]!['students'] as List).add({
          'name': data['name'] ?? 'Unknown',
          'rollNo': data['rollNo'] ?? '',
          'status': status,
          'checkInTime': data['checkInTime'],
          'checkOutTime': data['checkOutTime'],
          'remark': data['remark'],
        });
      }

      // Convert to list and calculate statistics
      List<Map<String, dynamic>> classList = [];
      int totalStudents = 0;
      int totalPresent = 0;
      int totalAbsent = 0;

      for (var entry in classMap.entries) {
        final data = entry.value;
        final total = data['total'] as int;
        final present = data['present'] as int;
        final rate = total > 0 ? (present / total) * 100 : 0;

        totalStudents += total;
        totalPresent += present;
        totalAbsent += (data['absent'] as int);

        classList.add({
          'key': entry.key,
          'className': data['className'],
          'section': data['section'],
          'total': total,
          'present': present,
          'absent': data['absent'],
          'late': data['late'],
          'rate': rate,
          'students': data['students'],
        });
      }

      // Sort by class name
      classList.sort((a, b) => a['className'].compareTo(b['className']));

      setState(() {
        _classData = classList;
        _totalClasses = classList.length;
        _totalStudents = totalStudents;
        _totalPresent = totalPresent;
        _totalAbsent = totalAbsent;
        _overallRate = totalStudents > 0 ? (totalPresent / totalStudents) * 100 : 0;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading report: $e');
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
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.indigo,
        title: const Text(
          "Attendance Report",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReportData,
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
          // Date Picker Card
          _buildDatePicker(),

          // Statistics Cards
          if (!_isLoading && _classData.isNotEmpty)
            _buildStatisticsCards(),

          // Summary Header
          if (!_isLoading && _classData.isNotEmpty)
            _buildSummaryHeader(),

          // Class List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _classData.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _classData.length,
              itemBuilder: (context, index) {
                return _buildClassCard(_classData[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
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
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.calendar_today, color: Colors.indigo),
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
                  DateFormat('EEEE, dd MMMM yyyy').format(selectedDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.edit_calendar, size: 18),
            label: const Text("Change"),
            style: TextButton.styleFrom(
              foregroundColor: Colors.indigo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: "Classes",
                value: _totalClasses.toString(),
                color: Colors.white,
                icon: Icons.class_,
              ),
              _StatItem(
                label: "Students",
                value: _totalStudents.toString(),
                color: Colors.white,
                icon: Icons.people,
              ),
              _StatItem(
                label: "Present",
                value: _totalPresent.toString(),
                color: Colors.green,
                icon: Icons.check_circle,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: _overallRate / 100,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "${_overallRate.toStringAsFixed(1)}%",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          SizedBox(width: 40, child: Text('S.No', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('Class', style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 50, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 50, child: Text('Present', style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 50, child: Text('Rate', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildClassCard(Map<String, dynamic> classInfo) {
    final rate = classInfo['rate'] as double;
    final rateColor = rate >= 75
        ? Colors.green
        : (rate >= 50 ? Colors.orange : Colors.red);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rateColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${_classData.indexOf(classInfo) + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: rateColor,
                ),
              ),
            ),
          ),
          title: Text(
            '${classInfo['className']} - ${classInfo['section']}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Row(
            children: [
              Icon(Icons.people, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text('${classInfo['total']} students'),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: rateColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${rate.toStringAsFixed(1)}%',
              style: TextStyle(
                color: rateColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Stats Row
                  Row(
                    children: [
                      _buildMiniStat('Present', classInfo['present'].toString(), Colors.green),
                      const SizedBox(width: 12),
                      _buildMiniStat('Absent', classInfo['absent'].toString(), Colors.red),
                      const SizedBox(width: 12),
                      if (classInfo['late'] > 0)
                        _buildMiniStat('Late', classInfo['late'].toString(), Colors.orange),
                    ],
                  ),
                  const Divider(height: 24),

                  // Students List Header
                  const Row(
                    children: [
                      SizedBox(width: 50, child: Text('Roll', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(child: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      SizedBox(width: 80, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Students List
                  ...List.generate(classInfo['students'].length, (index) {
                    final student = classInfo['students'][index];
                    final status = student['status'];
                    final statusColor = status == 'Present'
                        ? Colors.green
                        : (status == 'Late' ? Colors.orange : Colors.red);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 50,
                            child: Text(
                              student['rollNo'] ?? '',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              student['name'],
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 8),

                  // View Details Button
                  TextButton.icon(
                    onPressed: () => _showClassDetails(classInfo),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Complete Details'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.indigo,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
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
            "No Attendance Records",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            "No attendance marked for ${DateFormat('dd MMM yyyy').format(selectedDate)}",
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today),
            label: const Text("Select Another Date"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showClassDetails(Map<String, dynamic> classInfo) {
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
                        color: Colors.indigo.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.class_, size: 30, color: Colors.indigo),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${classInfo['className']} - ${classInfo['section']}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            DateFormat('EEEE, dd MMMM yyyy').format(selectedDate),
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
                        label: 'Total Students',
                        value: classInfo['total'].toString(),
                        color: Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _DetailStat(
                        label: 'Present',
                        value: classInfo['present'].toString(),
                        color: Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _DetailStat(
                        label: 'Absent',
                        value: classInfo['absent'].toString(),
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Student Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: classInfo['students'].length,
                    itemBuilder: (context, index) {
                      final student = classInfo['students'][index];
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
                              student['rollNo'] ?? '',
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(student['name']),
                          subtitle: student['checkInTime'] != null
                              ? Text('In: ${student['checkInTime']} | Out: ${student['checkOutTime'] ?? "—"}')
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDate: selectedDate,
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      await _loadReportData();
    }
  }

  Future<void> _exportReport() async {
    if (_classData.isEmpty) {
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
            ListTile(
              leading: const Icon(Icons.share, color: Colors.blue),
              title: const Text('Share Report'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share feature coming soon')),
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

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
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
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
      ],
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