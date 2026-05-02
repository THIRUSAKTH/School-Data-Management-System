import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:schoolprojectjan/app_config.dart';

class ParentAttendanceViewPage extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String className;
  final String section;

  const ParentAttendanceViewPage({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.section,
  });

  @override
  State<ParentAttendanceViewPage> createState() =>
      _ParentAttendanceViewPageState();
}

class _ParentAttendanceViewPageState extends State<ParentAttendanceViewPage>
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

  // OPTIMIZED: Fetch all records in a single query using collection group
  Future<void> _fetchAttendance() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Use collection group query to get all records for this student
      final recordsSnapshot =
          await FirebaseFirestore.instance
              .collectionGroup('records')
              .where('studentId', isEqualTo: widget.studentId)
              .get();

      final records =
          recordsSnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'date': data['date'] ?? '',
              'status': data['status'] ?? 'Absent',
              'remark': data['remark'] ?? '',
              'checkInTime': data['checkInTime'] ?? '',
              'checkOutTime': data['checkOutTime'] ?? '',
              'className': data['className'] ?? widget.className,
              'section': data['section'] ?? widget.section,
            };
          }).toList();

      // Sort by date (newest first)
      records.sort((a, b) => b['date'].compareTo(a['date']));

      if (mounted) {
        setState(() {
          _attendanceRecords = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching attendance: $e');

      // Fallback method if collection group index is not created yet
      await _fetchAttendanceFallback();
    }
  }

  // FALLBACK: If collection group index is missing, use this method
  Future<void> _fetchAttendanceFallback() async {
    try {
      // Get all attendance date documents
      final attendanceDocs =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('attendance')
              .get();

      List<Map<String, dynamic>> records = [];

      // Fetch records in parallel for better performance
      final futures = attendanceDocs.docs.map((dateDoc) async {
        try {
          final recordSnapshot =
              await dateDoc.reference
                  .collection('records')
                  .doc(widget.studentId)
                  .get();

          if (recordSnapshot.exists) {
            final data = recordSnapshot.data()!;
            return {
              'date': dateDoc.id,
              'status': data['status'] ?? 'Absent',
              'remark': data['remark'] ?? '',
              'checkInTime': data['checkInTime'] ?? '',
              'checkOutTime': data['checkOutTime'] ?? '',
              'className': data['className'] ?? widget.className,
              'section': data['section'] ?? widget.section,
            };
          }
        } catch (e) {
          debugPrint('Error fetching record for ${dateDoc.id}: $e');
        }
        return null;
      });

      final results = await Future.wait(futures);

      for (var result in results) {
        if (result != null) {
          records.add(result);
        }
      }

      records.sort((a, b) => b['date'].compareTo(a['date']));

      if (mounted) {
        setState(() {
          _attendanceRecords = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error in fallback attendance fetch: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error loading attendance: ${e.toString().substring(0, 100)}',
            ),
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
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _attendanceRecords.isEmpty
              ? _buildEmptyState()
              : TabBarView(
                controller: _tabController,
                children: [_buildSummaryTab(), _buildRecordsTab()],
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    int present =
        _attendanceRecords.where((r) => r['status'] == 'Present').length;
    int absent =
        _attendanceRecords.where((r) => r['status'] == 'Absent').length;
    int late = _attendanceRecords.where((r) => r['status'] == 'Late').length;
    int total = present + absent + late;
    double percentage = total > 0 ? (present / total) * 100 : 0;

    var monthlyRecords =
        _attendanceRecords
            .where(
              (r) => r['date'].toString().substring(0, 7) == _selectedMonth,
            )
            .toList();
    int monthlyPresent =
        monthlyRecords.where((r) => r['status'] == 'Present').length;
    int monthlyTotal = monthlyRecords.length;
    double monthlyPercentage =
        monthlyTotal > 0 ? (monthlyPresent / monthlyTotal) * 100 : 0;

    return RefreshIndicator(
      onRefresh: _fetchAttendance,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatsCard(present, absent, late, percentage, total),
            const SizedBox(height: 20),
            _buildMonthSelector(),
            if (monthlyTotal > 0) ...[
              const SizedBox(height: 20),
              _buildMonthlyStatsCard(
                monthlyPresent,
                monthlyTotal,
                monthlyPercentage,
              ),
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

  Widget _buildStatsCard(
    int present,
    int absent,
    int late,
    double percentage,
    int total,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.orange, Colors.deepOrange],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Overall Attendance',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            total == 0 ? 'No Data' : '${percentage.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (total > 0) ...[
            const SizedBox(height: 4),
            Text(
              '$present out of $total days present',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat(
                'Present',
                present.toString(),
                Colors.green,
                Icons.check_circle,
              ),
              if (late > 0)
                _buildMiniStat(
                  'Late',
                  late.toString(),
                  Colors.orange,
                  Icons.access_time,
                ),
              _buildMiniStat(
                'Absent',
                absent.toString(),
                Colors.red,
                Icons.cancel,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    Set<String> monthSet = {};
    for (var record in _attendanceRecords) {
      if (record['date'].toString().length >= 7) {
        monthSet.add(record['date'].toString().substring(0, 7));
      }
    }
    List<String> availableMonths =
        monthSet.toList()..sort((a, b) => b.compareTo(a));
    if (availableMonths.isEmpty) availableMonths = [_selectedMonth];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const Icon(Icons.calendar_month, color: Colors.orange, size: 18),
          const SizedBox(width: 8),
          const Text(
            'Month:',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              value:
                  availableMonths.contains(_selectedMonth)
                      ? _selectedMonth
                      : availableMonths.first,
              items:
                  availableMonths.map((month) {
                    return DropdownMenuItem(
                      value: month,
                      child: Text(
                        DateFormat(
                          'MMMM yyyy',
                        ).format(DateTime.parse('$month-01')),
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedMonth = value);
              },
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyStatsCard(int present, int total, double percentage) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Monthly Attendance',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      percentage >= 75
                          ? Colors.green.shade100
                          : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: percentage >= 75 ? Colors.green : Colors.orange,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: total > 0 ? present / total : 0,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(
              percentage >= 75 ? Colors.green : Colors.orange,
            ),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$present days present',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'out of $total days',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
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
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: const Center(
          child: Text('No data to display', style: TextStyle(fontSize: 12)),
        ),
      );
    }

    List<String> last7Days = [];
    for (int i = 6; i >= 0; i--) {
      last7Days.add(
        DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime.now().subtract(Duration(days: i))),
      );
    }

    Map<String, String> statusMap = {};
    for (var record in _attendanceRecords) {
      statusMap[record['date']] = record['status'];
    }

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < last7Days.length; i++) {
      String status = statusMap[last7Days[i]] ?? 'Absent';
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: status == 'Present' ? 100 : (status == 'Late' ? 50 : 0),
              color:
                  status == 'Present'
                      ? Colors.green
                      : (status == 'Late' ? Colors.orange : Colors.red),
              width: 25,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const Text(
            'Last 7 Days',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                barGroups: barGroups,
                maxY: 100,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 25,
                      getTitlesWidget:
                          (value, meta) => Text(
                            '${value.toInt()}%',
                            style: const TextStyle(fontSize: 8),
                          ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < last7Days.length) {
                          return Text(
                            DateFormat(
                              'E',
                            ).format(DateTime.parse(last7Days[index])),
                            style: const TextStyle(fontSize: 8),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: true),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem(Colors.green, 'Present'),
              const SizedBox(width: 12),
              _legendItem(Colors.orange, 'Late'),
              const SizedBox(width: 12),
              _legendItem(Colors.red, 'Absent'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRecords() {
    var recentRecords = _attendanceRecords.take(5).toList();
    if (recentRecords.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Records',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...recentRecords.map((record) {
            DateTime date = DateTime.parse(record['date']);
            String status = record['status'];
            String? checkInTime = record['checkInTime'];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor:
                    status == 'Present'
                        ? Colors.green.shade100
                        : (status == 'Late'
                            ? Colors.orange.shade100
                            : Colors.red.shade100),
                child: Icon(
                  status == 'Present'
                      ? Icons.check_circle
                      : (status == 'Late' ? Icons.access_time : Icons.cancel),
                  size: 16,
                  color:
                      status == 'Present'
                          ? Colors.green
                          : (status == 'Late' ? Colors.orange : Colors.red),
                ),
              ),
              title: Text(
                DateFormat('dd MMM yyyy').format(date),
                style: const TextStyle(fontSize: 12),
              ),
              subtitle:
                  checkInTime != null && checkInTime.isNotEmpty
                      ? Text(
                        'Check In: $checkInTime',
                        style: const TextStyle(fontSize: 10),
                      )
                      : null,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      status == 'Present'
                          ? Colors.green.shade100
                          : (status == 'Late'
                              ? Colors.orange.shade100
                              : Colors.red.shade100),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color:
                        status == 'Present'
                            ? Colors.green
                            : (status == 'Late' ? Colors.orange : Colors.red),
                    fontSize: 10,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecordsTab() {
    Map<String, List<Map<String, dynamic>>> groupedRecords = {};
    for (var record in _attendanceRecords) {
      String month = record['date'].substring(0, 7);
      if (!groupedRecords.containsKey(month)) groupedRecords[month] = [];
      groupedRecords[month]!.add(record);
    }
    var sortedMonths =
        groupedRecords.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: sortedMonths.length,
      itemBuilder: (context, monthIndex) {
        final month = sortedMonths[monthIndex];
        final records = groupedRecords[month]!;
        final monthDate = DateTime.parse('$month-01');
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                DateFormat('MMMM yyyy').format(monthDate),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ...records.map((record) => _buildRecordCard(record)),
          ],
        );
      },
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record) {
    final date = DateTime.parse(record['date']);
    final status = record['status'];
    final remark = record['remark'];
    final checkInTime = record['checkInTime'];
    final checkOutTime = record['checkOutTime'];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor:
              status == 'Present'
                  ? Colors.green.shade100
                  : (status == 'Late'
                      ? Colors.orange.shade100
                      : Colors.red.shade100),
          child: Icon(
            status == 'Present'
                ? Icons.check_circle
                : (status == 'Late' ? Icons.access_time : Icons.cancel),
            size: 18,
            color:
                status == 'Present'
                    ? Colors.green
                    : (status == 'Late' ? Colors.orange : Colors.red),
          ),
        ),
        title: Text(
          DateFormat('dd MMM yyyy').format(date),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          status,
          style: TextStyle(
            color:
                status == 'Present'
                    ? Colors.green
                    : (status == 'Late' ? Colors.orange : Colors.red),
            fontSize: 11,
          ),
        ),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (checkInTime != null && checkInTime.isNotEmpty)
                _infoRow('Check In Time', checkInTime),
              if (checkOutTime != null && checkOutTime.isNotEmpty)
                _infoRow('Check Out Time', checkOutTime),
              if (remark.isNotEmpty) _infoRow('Remark', remark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
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

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 11))),
        ],
      ),
    );
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
