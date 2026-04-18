import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../app_config.dart';

class AttendanceHistoryPage extends StatefulWidget {
  final String studentId;
  final String studentName;

  const AttendanceHistoryPage({
    super.key,
    required this.studentId,
    this.studentName = '',
  });

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  Map<String, dynamic> _attendanceData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAttendanceData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAttendanceData() async {
    setState(() => _isLoading = true);

    try {
      final attendanceSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('attendance')
          .get();

      Map<String, List<Map<String, dynamic>>> monthlyRecords = {};
      Map<String, int> monthlyPresent = {};
      Map<String, int> monthlyAbsent = {};
      Map<String, int> monthlyLate = {};
      List<Map<String, dynamic>> allRecords = [];

      for (var doc in attendanceSnapshot.docs) {
        final date = doc.id;
        final records = doc.data() as Map<String, dynamic>;

        // Check if this student exists in this date's attendance
        if (records.containsKey(widget.studentId)) {
          final studentRecord = records[widget.studentId] as Map<String, dynamic>;
          final status = studentRecord['status'] ?? 'Absent';
          final month = date.substring(0, 7);

          if (!monthlyRecords.containsKey(month)) {
            monthlyRecords[month] = [];
            monthlyPresent[month] = 0;
            monthlyAbsent[month] = 0;
            monthlyLate[month] = 0;
          }

          monthlyRecords[month]!.add({
            'date': date,
            'status': status,
            'checkInTime': studentRecord['checkInTime'],
            'checkOutTime': studentRecord['checkOutTime'],
            'remark': studentRecord['remark'],
          });

          allRecords.add({
            'date': date,
            'status': status,
            'checkInTime': studentRecord['checkInTime'],
            'checkOutTime': studentRecord['checkOutTime'],
            'remark': studentRecord['remark'],
          });

          if (status == 'Present') {
            monthlyPresent[month] = (monthlyPresent[month] ?? 0) + 1;
          } else if (status == 'Absent') {
            monthlyAbsent[month] = (monthlyAbsent[month] ?? 0) + 1;
          } else if (status == 'Late') {
            monthlyLate[month] = (monthlyLate[month] ?? 0) + 1;
          }
        }
      }

      // Sort records by date (newest first)
      allRecords.sort((a, b) => b['date'].compareTo(a['date']));

      setState(() {
        _attendanceData = {
          'monthlyRecords': monthlyRecords,
          'monthlyPresent': monthlyPresent,
          'monthlyAbsent': monthlyAbsent,
          'monthlyLate': monthlyLate,
          'allRecords': allRecords,
        };
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading attendance: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading attendance: $e'), backgroundColor: Colors.red),
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
          widget.studentName.isNotEmpty
              ? 'Attendance - ${widget.studentName}'
              : 'Attendance History',
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month), text: 'Monthly View'),
            Tab(icon: Icon(Icons.list_alt), text: 'All Records'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAttendanceData,
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'export') {
                // TODO: Export to PDF
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export feature coming soon')),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 12),
                    Text('Export Report'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildMonthlyView(),
          _buildAllRecordsView(),
        ],
      ),
    );
  }

  Widget _buildMonthlyView() {
    final monthlyPresent = _attendanceData['monthlyPresent'] ?? {};
    final monthlyAbsent = _attendanceData['monthlyAbsent'] ?? {};
    final monthlyLate = _attendanceData['monthlyLate'] ?? {};

    List<String> months = monthlyPresent.keys.toList();
    months.sort();

    if (months.isEmpty) {
      return _buildEmptyState();
    }

    // Calculate total stats
    int totalPresent = monthlyPresent.values.fold(0, (a, b) => a + b);
    int totalAbsent = monthlyAbsent.values.fold(0, (a, b) => a + b);
    int totalLate = monthlyLate.values.fold(0, (a, b) => a + b);
    int totalDays = totalPresent + totalAbsent;
    double overallRate = totalDays > 0 ? (totalPresent / totalDays) * 100 : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Overall Stats Card
          _buildOverallStatsCard(totalPresent, totalAbsent, totalLate, overallRate),
          const SizedBox(height: 20),

          // Attendance Chart
          _buildAttendanceChart(monthlyPresent, monthlyAbsent, monthlyLate, months),
          const SizedBox(height: 20),

          // Monthly Breakdown
          _buildMonthlyBreakdown(months, monthlyPresent, monthlyAbsent, monthlyLate),
        ],
      ),
    );
  }

  Widget _buildOverallStatsCard(int present, int absent, int late, double rate) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.deepPurple, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'Overall Attendance',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '${rate.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatsItem(
                label: 'Present',
                value: present.toString(),
                color: Colors.green,
                icon: Icons.check_circle,
              ),
              _StatsItem(
                label: 'Absent',
                value: absent.toString(),
                color: Colors.red,
                icon: Icons.cancel,
              ),
              if (late > 0)
                _StatsItem(
                  label: 'Late',
                  value: late.toString(),
                  color: Colors.orange,
                  icon: Icons.access_time,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceChart(
      Map<String, int> present,
      Map<String, int> absent,
      Map<String, int> late,
      List<String> months,
      ) {
    List<BarChartGroupData> barGroups = [];

    for (int i = 0; i < months.length; i++) {
      final month = months[i];
      final presentCount = present[month]?.toDouble() ?? 0;
      final absentCount = absent[month]?.toDouble() ?? 0;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: presentCount,
              color: Colors.green,
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
            BarChartRodData(
              toY: absentCount,
              color: Colors.red,
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
          barsSpace: 4,
        ),
      );
    }

    double maxY = 0;
    for (var month in months) {
      final total = (present[month] ?? 0) + (absent[month] ?? 0);
      if (total > maxY) maxY = total.toDouble();
    }
    maxY = maxY > 0 ? maxY + 2 : 10;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Attendance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Green: Present | Red: Absent',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                barGroups: barGroups,
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                minY: 0,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < months.length) {
                          DateTime date = DateTime.parse('${months[index]}-01');
                          return Text(DateFormat('MMM').format(date), style: const TextStyle(fontSize: 10));
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
                      final month = months[groupIndex];
                      final presentCount = present[month] ?? 0;
                      final absentCount = absent[month] ?? 0;
                      return BarTooltipItem(
                        '$month\nPresent: $presentCount\nAbsent: $absentCount',
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

  Widget _buildMonthlyBreakdown(
      List<String> months,
      Map<String, int> present,
      Map<String, int> absent,
      Map<String, int> late,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Breakdown',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: months.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final month = months[index];
              final presentCount = present[month] ?? 0;
              final absentCount = absent[month] ?? 0;
              final lateCount = late[month] ?? 0;
              final total = presentCount + absentCount;
              final rate = total > 0 ? (presentCount / total) * 100 : 0;

              DateTime date = DateTime.parse('$month-01');
              String monthName = DateFormat('MMMM yyyy').format(date);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: rate >= 75 ? Colors.green.shade100 : Colors.orange.shade100,
                  child: Text(
                    '${presentCount + absentCount}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: rate >= 75 ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
                title: Text(monthName),
                subtitle: Text('Present: $presentCount | Absent: $absentCount'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${rate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: rate >= 75 ? Colors.green : Colors.orange,
                      ),
                    ),
                    if (lateCount > 0)
                      Text(
                        '$lateCount late',
                        style: const TextStyle(fontSize: 10, color: Colors.orange),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAllRecordsView() {
    final allRecords = List<Map<String, dynamic>>.from(_attendanceData['allRecords'] ?? []);

    if (allRecords.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: allRecords.length,
      itemBuilder: (context, index) {
        final record = allRecords[index];
        final date = DateTime.parse(record['date']);
        final status = record['status'];
        final checkInTime = record['checkInTime'];
        final checkOutTime = record['checkOutTime'];
        final remark = record['remark'];

        Color statusColor;
        IconData statusIcon;
        if (status == 'Present') {
          statusColor = Colors.green;
          statusIcon = Icons.check_circle;
        } else if (status == 'Absent') {
          statusColor = Colors.red;
          statusIcon = Icons.cancel;
        } else if (status == 'Late') {
          statusColor = Colors.orange;
          statusIcon = Icons.access_time;
        } else {
          statusColor = Colors.grey;
          statusIcon = Icons.help_outline;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () => _showRecordDetails(record),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: statusColor.withValues(alpha: 0.1),
                        child: Icon(statusIcon, color: statusColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEEE, dd MMMM yyyy').format(date),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              status,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
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
                    ],
                  ),
                  if (checkInTime != null || checkOutTime != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          if (checkInTime != null)
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(Icons.login, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text('In: $checkInTime', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          if (checkOutTime != null)
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(Icons.logout, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text('Out: $checkOutTime', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (remark != null && remark.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.comment, size: 14, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(child: Text(remark, style: const TextStyle(fontSize: 12))),
                          ],
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

  void _showRecordDetails(Map<String, dynamic> record) {
    final date = DateTime.parse(record['date']);
    final status = record['status'];
    final checkInTime = record['checkInTime'];
    final checkOutTime = record['checkOutTime'];
    final remark = record['remark'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: status == 'Present' ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    status == 'Present' ? Icons.check_circle : Icons.cancel,
                    color: status == 'Present' ? Colors.green : Colors.red,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, dd MMMM yyyy').format(date),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 14,
                          color: status == 'Present' ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            if (checkInTime != null) _DetailRow(label: 'Check In Time', value: checkInTime),
            if (checkOutTime != null) _DetailRow(label: 'Check Out Time', value: checkOutTime),
            if (remark != null && remark.isNotEmpty) _DetailRow(label: 'Remark', value: remark),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Close'),
              ),
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
          Icon(Icons.calendar_today, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No attendance records found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Attendance history will appear here',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
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

class _StatsItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatsItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}