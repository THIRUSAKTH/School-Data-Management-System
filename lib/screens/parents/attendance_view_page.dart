import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../app_config.dart';

class AttendanceViewPage extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String className;
  final String section;

  const AttendanceViewPage({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.section,
  });

  @override
  State<AttendanceViewPage> createState() => _AttendanceViewPageState();
}

class _AttendanceViewPageState extends State<AttendanceViewPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _attendanceRecords = [];
  bool _isLoading = true;
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAttendance();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAttendance() async {
    setState(() => _isLoading = true);

    try {
      // Get all attendance documents
      final attendanceSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('attendance')
          .get();

      List<Map<String, dynamic>> records = [];

      for (var doc in attendanceSnapshot.docs) {
        final date = doc.id;
        final data = doc.data() as Map<String, dynamic>;

        // Check if this student has attendance record for this date
        if (data.containsKey(widget.studentId)) {
          final studentRecord = data[widget.studentId] as Map<String, dynamic>;
          records.add({
            'date': date,
            'status': studentRecord['status'] ?? 'Absent',
            'checkInTime': studentRecord['checkInTime'],
            'checkOutTime': studentRecord['checkOutTime'],
            'remark': studentRecord['remark'],
          });
        }
      }

      // Sort by date (newest first)
      records.sort((a, b) => b['date'].compareTo(a['date']));

      setState(() {
        _attendanceRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching attendance: $e');
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
        title: Text('Attendance - ${widget.studentName}'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Summary'),
            Tab(icon: Icon(Icons.list_alt), text: 'Records'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAttendance,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryTab(),
          _buildRecordsTab(),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    // Calculate statistics
    int present = _attendanceRecords.where((r) => r['status'] == 'Present').length;
    int absent = _attendanceRecords.where((r) => r['status'] == 'Absent').length;
    int late = _attendanceRecords.where((r) => r['status'] == 'Late').length;
    int total = present + absent;
    double percentage = total > 0 ? (present / total) * 100 : 0;

    // Filter by selected month
    var monthlyRecords = _attendanceRecords.where((r) {
      return r['date'].substring(0, 7) == _selectedMonth;
    }).toList();

    int monthlyPresent = monthlyRecords.where((r) => r['status'] == 'Present').length;
    int monthlyTotal = monthlyRecords.length;
    double monthlyPercentage = monthlyTotal > 0 ? (monthlyPresent / monthlyTotal) * 100 : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Overall Stats Card
          _buildStatsCard(present, absent, late, percentage),
          const SizedBox(height: 20),

          // Month Selector
          _buildMonthSelector(),
          const SizedBox(height: 20),

          // Monthly Stats
          _buildMonthlyStatsCard(monthlyPresent, monthlyTotal, monthlyPercentage),
          const SizedBox(height: 20),

          // Recent Attendance Chart
          _buildRecentAttendanceChart(),
          const SizedBox(height: 20),

          // Recent Records
          _buildRecentRecords(),
        ],
      ),
    );
  }

  Widget _buildStatsCard(int present, int absent, int late, double percentage) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.orange, Colors.deepOrange],
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
            '${percentage.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat('Present', present.toString(), Colors.green, Icons.check_circle),
              _buildMiniStat('Absent', absent.toString(), Colors.red, Icons.cancel),
              if (late > 0) _buildMiniStat('Late', late.toString(), Colors.orange, Icons.access_time),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    // Get unique months from records - FIXED: Convert to List<String> properly
    Set<String> monthSet = {};
    for (var record in _attendanceRecords) {
      String month = record['date'].substring(0, 7);
      monthSet.add(month);
    }

    List<String> availableMonths = monthSet.toList();
    availableMonths.sort();

    if (availableMonths.isEmpty) {
      availableMonths = [_selectedMonth];
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const Icon(Icons.calendar_month, color: Colors.orange),
          const SizedBox(width: 12),
          const Text('Select Month:'),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedMonth,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: availableMonths.map((month) {
                DateTime date = DateTime.parse('$month-01');
                return DropdownMenuItem<String>(
                  value: month,
                  child: Text(DateFormat('MMMM yyyy').format(date)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMonth = value!;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyStatsCard(int present, int total, double percentage) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Monthly Attendance',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: percentage >= 75 ? Colors.green.shade100 : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: percentage >= 75 ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: total > 0 ? present / total : 0,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage >= 75 ? Colors.green : Colors.orange,
            ),
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$present days present'),
              Text('out of $total days'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAttendanceChart() {
    // Get last 7 days
    List<String> last7Days = [];
    for (int i = 6; i >= 0; i--) {
      last7Days.add(DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: i))));
    }

    Map<String, String> statusMap = {};
    for (var record in _attendanceRecords) {
      statusMap[record['date']] = record['status'];
    }

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < last7Days.length; i++) {
      String status = statusMap[last7Days[i]] ?? 'No Data';
      Color color;
      double value;

      if (status == 'Present') {
        color = Colors.green;
        value = 100;
      } else if (status == 'Late') {
        color = Colors.orange;
        value = 50;
      } else if (status == 'Absent') {
        color = Colors.red;
        value = 0;
      } else {
        color = Colors.grey;
        value = 0;
      }

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: value,
              color: color,
              width: 30,
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
            'Last 7 Days',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
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
                        if (index >= 0 && index < last7Days.length) {
                          DateTime date = DateTime.parse(last7Days[index]);
                          return Text(DateFormat('E').format(date), style: const TextStyle(fontSize: 10));
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
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem(Colors.green, 'Present'),
              const SizedBox(width: 16),
              _legendItem(Colors.orange, 'Late'),
              const SizedBox(width: 16),
              _legendItem(Colors.red, 'Absent'),
              const SizedBox(width: 16),
              _legendItem(Colors.grey, 'No Data'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRecords() {
    var recentRecords = _attendanceRecords.take(5).toList();

    if (recentRecords.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: _cardDecoration(),
        child: const Center(child: Text('No recent records')),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Records',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...recentRecords.map((record) {
            DateTime date = DateTime.parse(record['date']);
            String status = record['status'];
            Color statusColor = status == 'Present' ? Colors.green : (status == 'Late' ? Colors.orange : Colors.red);

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: statusColor.withValues(alpha: 0.1),
                child: Icon(
                  status == 'Present' ? Icons.check_circle : Icons.cancel,
                  color: statusColor,
                ),
              ),
              title: Text(DateFormat('EEEE, dd MMM').format(date)),
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
          }).toList(),
          if (_attendanceRecords.length > 5)
            TextButton(
              onPressed: () {
                _tabController.animateTo(1);
              },
              child: const Text('View All Records'),
            ),
        ],
      ),
    );
  }

  Widget _buildRecordsTab() {
    if (_attendanceRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No attendance records found', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _attendanceRecords.length,
      itemBuilder: (context, index) {
        final record = _attendanceRecords[index];
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
        } else if (status == 'Late') {
          statusColor = Colors.orange;
          statusIcon = Icons.access_time;
        } else {
          statusColor = Colors.red;
          statusIcon = Icons.cancel;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: statusColor.withValues(alpha: 0.1),
              child: Icon(statusIcon, color: statusColor),
            ),
            title: Text(
              DateFormat('EEEE, dd MMMM yyyy').format(date),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(status, style: TextStyle(color: statusColor)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (checkInTime != null && checkInTime.isNotEmpty)
                      _infoRow('Check In', checkInTime),
                    if (checkOutTime != null && checkOutTime.isNotEmpty)
                      _infoRow('Check Out', checkOutTime),
                    if (remark != null && remark.isNotEmpty)
                      _infoRow('Remark', remark),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniStat(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value)),
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