import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

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
  String? _schoolId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getSchoolIdAndFetchAttendance();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _getSchoolIdAndFetchAttendance() async {
    // Get schoolId from the current user's parent document
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final parentDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (parentDoc.exists) {
          _schoolId = parentDoc.data()?['schoolId'];
        }
      }
    } catch (e) {
      debugPrint('Error getting schoolId: $e');
    }

    await _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    setState(() => _isLoading = true);

    try {
      if (_schoolId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // CORRECTED: Fetch attendance from the correct path
      // Path: schools/{schoolId}/attendance/{date}/records/{studentId}
      final attendanceSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(_schoolId)
          .collection('attendance')
          .get();

      List<Map<String, dynamic>> records = [];

      for (var dateDoc in attendanceSnapshot.docs) {
        final date = dateDoc.id; // The document ID is the date (YYYY-MM-DD)

        // Get the records subcollection for this date
        final recordsSnapshot = await dateDoc.reference
            .collection('records')
            .where('studentId', isEqualTo: widget.studentId)
            .get();

        for (var recordDoc in recordsSnapshot.docs) {
          final data = recordDoc.data();

          records.add({
            'date': date,
            'status': data['status'] ?? 'Absent',
            'checkInTime': data['checkInTime'],
            'checkOutTime': data['checkOutTime'],
            'remark': data['remark'],
            'markedBy': data['markedBy'],
            'markedAt': data['markedAt'],
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
          SnackBar(
            content: Text('Error loading attendance: $e'),
            backgroundColor: Colors.red,
          ),
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
            tooltip: "Refresh",
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportPDF,
            tooltip: "Export PDF",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _attendanceRecords.isEmpty
          ? _buildEmptyState()
          : TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryTab(),
          _buildRecordsTab(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Attendance Records Found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Attendance has not been marked for this student yet.',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchAttendance,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    // Calculate statistics
    int present = _attendanceRecords.where((r) => r['status'] == 'Present').length;
    int absent = _attendanceRecords.where((r) => r['status'] == 'Absent').length;
    int late = _attendanceRecords.where((r) => r['status'] == 'Late').length;
    int total = present + absent + late;
    double percentage = total > 0 ? (present / total) * 100 : 0;

    // Filter by selected month
    var monthlyRecords = _attendanceRecords.where((r) {
      return r['date'].substring(0, 7) == _selectedMonth;
    }).toList();

    int monthlyPresent = monthlyRecords.where((r) => r['status'] == 'Present').length;
    int monthlyTotal = monthlyRecords.length;
    double monthlyPercentage = monthlyTotal > 0 ? (monthlyPresent / monthlyTotal) * 100 : 0;

    return RefreshIndicator(
      onRefresh: _fetchAttendance,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatsCard(present, absent, late, percentage, total),
            const SizedBox(height: 20),
            _buildMonthSelector(),
            if (monthlyTotal > 0) ...[
              const SizedBox(height: 20),
              _buildMonthlyStatsCard(monthlyPresent, monthlyTotal, monthlyPercentage),
            ],
            const SizedBox(height: 20),
            _buildRecentAttendanceChart(),
            const SizedBox(height: 20),
            _buildRecentRecords(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(int present, int absent, int late, double percentage, int total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.orange, Colors.deepOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Overall Attendance',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            total == 0 ? 'No Data' : '${percentage.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (total > 0) ...[
            const SizedBox(height: 8),
            Text(
              '$present out of $total days present',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat('Present', present.toString(), Colors.green, Icons.check_circle),
              _buildMiniStat('Absent', absent.toString(), Colors.red, Icons.cancel),
              if (late > 0)
                _buildMiniStat('Late', late.toString(), Colors.orange, Icons.access_time),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    // Get unique months from records
    Set<String> monthSet = {};
    for (var record in _attendanceRecords) {
      if (record['date'].length >= 7) {
        String month = record['date'].substring(0, 7);
        monthSet.add(month);
      }
    }

    List<String> availableMonths = monthSet.toList();
    availableMonths.sort((a, b) => b.compareTo(a)); // Newest first

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
          const Text(
            'Select Month:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: availableMonths.contains(_selectedMonth) ? _selectedMonth : availableMonths.first,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              items: availableMonths.map<DropdownMenuItem<String>>((month) {
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
              Text(
                '$present days present',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                'out of $total days',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAttendanceChart() {
    if (_attendanceRecords.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: _cardDecoration(),
        child: const Center(child: Text('No data to display')),
      );
    }

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
      String status = statusMap[last7Days[i]] ?? 'Absent';
      Color color;
      double value;

      switch (status) {
        case 'Present':
          color = Colors.green;
          value = 100;
          break;
        case 'Late':
          color = Colors.orange;
          value = 50;
          break;
        default:
          color = Colors.red;
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
                        if (index >= 0 && index < last7Days.length) {
                          DateTime date = DateTime.parse(last7Days[index]);
                          return Text(DateFormat('E').format(date), style: const TextStyle(fontSize: 10));
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
                      final date = last7Days[groupIndex];
                      final status = statusMap[date] ?? 'Absent';
                      return BarTooltipItem(
                        '${DateFormat('E').format(DateTime.parse(date))}\n$status',
                        const TextStyle(color: Colors.white, fontSize: 11),
                      );
                    },
                  ),
                ),
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRecords() {
    var recentRecords = _attendanceRecords.take(5).toList();

    if (recentRecords.isEmpty) {
      return const SizedBox();
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
            Color statusColor = status == 'Present'
                ? Colors.green
                : (status == 'Late' ? Colors.orange : Colors.red);

            return GestureDetector(
              onTap: () => _showRecordDetail(record),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: statusColor.withValues(alpha: 0.1),
                  child: Icon(
                    status == 'Present' ? Icons.check_circle :
                    (status == 'Late' ? Icons.access_time : Icons.cancel),
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
              ),
            );
          }),
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
    // Group records by month
    Map<String, List<Map<String, dynamic>>> groupedRecords = {};
    for (var record in _attendanceRecords) {
      if (record['date'].length >= 7) {
        String month = record['date'].substring(0, 7);
        if (!groupedRecords.containsKey(month)) {
          groupedRecords[month] = [];
        }
        groupedRecords[month]!.add(record);
      }
    }

    // Sort months descending
    var sortedMonths = groupedRecords.keys.toList()..sort((a, b) => b.compareTo(a));

    return RefreshIndicator(
      onRefresh: _fetchAttendance,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: sortedMonths.length,
        itemBuilder: (context, monthIndex) {
          final month = sortedMonths[monthIndex];
          final records = groupedRecords[month]!;
          final monthDate = DateTime.parse('$month-01');

          // Calculate month statistics
          int monthPresent = records.where((r) => r['status'] == 'Present').length;
          int monthTotal = records.length;
          double monthRate = monthTotal > 0 ? (monthPresent / monthTotal) * 100 : 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 12, left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('MMMM yyyy').format(monthDate),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: monthRate >= 75 ? Colors.green.shade100 : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${monthRate.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: monthRate >= 75 ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...records.map((record) => _buildRecordCard(record)),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record) {
    final date = DateTime.parse(record['date']);
    final status = record['status'];
    final checkInTime = record['checkInTime'];
    final checkOutTime = record['checkOutTime'];
    final remark = record['remark'];
    final markedBy = record['markedBy'];
    final markedAt = record['markedAt'];

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'Present':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'Late':
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        break;
      default:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          DateFormat('EEEE, dd MMMM yyyy').format(date),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (checkInTime != null && checkInTime.isNotEmpty)
                  _infoRow('Check In Time', checkInTime),
                if (checkOutTime != null && checkOutTime.isNotEmpty)
                  _infoRow('Check Out Time', checkOutTime),
                if (remark != null && remark.isNotEmpty)
                  _infoRow('Remark', remark),
                if (markedBy != null && markedBy.isNotEmpty)
                  _infoRow('Marked By', markedBy),
                if (markedAt != null)
                  _infoRow('Marked At', _formatTimestamp(markedAt)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRecordDetail(Map<String, dynamic> record) {
    final date = DateTime.parse(record['date']);
    final status = record['status'];
    final checkInTime = record['checkInTime'];
    final checkOutTime = record['checkOutTime'];
    final remark = record['remark'];
    final markedBy = record['markedBy'];
    final markedAt = record['markedAt'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                    color: status == 'Present'
                        ? Colors.green.shade100
                        : (status == 'Late' ? Colors.orange.shade100 : Colors.red.shade100),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    status == 'Present'
                        ? Icons.check_circle
                        : (status == 'Late' ? Icons.access_time : Icons.cancel),
                    color: status == 'Present'
                        ? Colors.green
                        : (status == 'Late' ? Colors.orange : Colors.red),
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
                          color: status == 'Present'
                              ? Colors.green
                              : (status == 'Late' ? Colors.orange : Colors.red),
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
            if (checkInTime != null && checkInTime.isNotEmpty)
              _infoRow('Check In Time', checkInTime),
            if (checkOutTime != null && checkOutTime.isNotEmpty)
              _infoRow('Check Out Time', checkOutTime),
            if (remark != null && remark.isNotEmpty)
              _infoRow('Remark', remark),
            if (markedBy != null && markedBy.isNotEmpty)
              _infoRow('Marked By', markedBy),
            if (markedAt != null)
              _infoRow('Marked At', _formatTimestamp(markedAt)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Close"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      return DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate());
    }
    return timestamp.toString();
  }

  Future<void> _exportPDF() async {
    // TODO: Implement full PDF export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("PDF Export will be available soon"),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
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