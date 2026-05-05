import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../app_config.dart';

class AttendanceHistoryPage extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String? className;
  final String? section;

  const AttendanceHistoryPage({
    super.key,
    required this.studentId,
    this.studentName = '',
    this.className,
    this.section,
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
  bool _isExporting = false;

  Future<void> _debugCheckAttendance() async {
    // Check if attendance collection exists
    final attendanceCheck = await FirebaseFirestore.instance
        .collection('schools')
        .doc(AppConfig.schoolId)
        .collection('attendance')
        .limit(1)
        .get();

    print('Attendance collection exists: ${attendanceCheck.docs.isNotEmpty}');

    // Check if student has any records
    final recordCheck = await FirebaseFirestore.instance
        .collectionGroup('records')
        .where('studentId', isEqualTo: widget.studentId)
        .limit(1)
        .get();

    print('Student has records: ${recordCheck.docs.isNotEmpty}');
    if (recordCheck.docs.isNotEmpty) {
      print('Sample record: ${recordCheck.docs.first.data()}');
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAttendanceData();
    _debugCheckAttendance(); // Add this line
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAttendanceData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Use collection group query for better performance
      final recordsSnapshot = await FirebaseFirestore.instance
          .collectionGroup('records')
          .where('studentId', isEqualTo: widget.studentId)
          .get();

      Map<String, List<Map<String, dynamic>>> monthlyRecords = {};
      Map<String, int> monthlyPresent = {};
      Map<String, int> monthlyAbsent = {};
      Map<String, int> monthlyLate = {};
      List<Map<String, dynamic>> allRecords = [];

      for (var doc in recordsSnapshot.docs) {
        final data = doc.data();
        final date = data['date'] ?? '';

        if (date.isEmpty || date.length < 7) continue;

        final status = data['status'] ?? 'Absent';
        final month = date.substring(0, 7);

        if (!monthlyRecords.containsKey(month)) {
          monthlyRecords[month] = [];
          monthlyPresent[month] = 0;
          monthlyAbsent[month] = 0;
          monthlyLate[month] = 0;
        }

        final recordData = {
          'date': date,
          'status': status,
          'checkInTime': data['checkInTime'] ?? '',
          'checkOutTime': data['checkOutTime'] ?? '',
          'remark': data['remark'] ?? '',
          'className': data['className'] ?? widget.className ?? '',
          'section': data['section'] ?? widget.section ?? '',
        };

        monthlyRecords[month]!.add(recordData);
        allRecords.add(recordData);

        if (status == 'Present') {
          monthlyPresent[month] = (monthlyPresent[month] ?? 0) + 1;
        } else if (status == 'Absent') {
          monthlyAbsent[month] = (monthlyAbsent[month] ?? 0) + 1;
        } else if (status == 'Late') {
          monthlyLate[month] = (monthlyLate[month] ?? 0) + 1;
        }
      }

      // Sort records by date (newest first)
      allRecords.sort((a, b) => b['date'].compareTo(a['date']));

      if (mounted) {
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
      }
    } catch (e) {
      debugPrint('Error loading attendance: $e');
      // Use fallback method
      await _loadAttendanceDataFallback();
    }
  }

// Fallback method (your original implementation)
  Future<void> _loadAttendanceDataFallback() async {
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

      for (var dateDoc in attendanceSnapshot.docs) {
        final date = dateDoc.id;
        if (date.length < 7) continue;

        final recordDoc = await dateDoc.reference
            .collection('records')
            .doc(widget.studentId)
            .get();

        if (recordDoc.exists) {
          final studentRecord = recordDoc.data()!;
          final status = studentRecord['status'] ?? 'Absent';
          final month = date.substring(0, 7);

          if (!monthlyRecords.containsKey(month)) {
            monthlyRecords[month] = [];
            monthlyPresent[month] = 0;
            monthlyAbsent[month] = 0;
            monthlyLate[month] = 0;
          }

          final recordData = {
            'date': date,
            'status': status,
            'checkInTime': studentRecord['checkInTime'] ?? '',
            'checkOutTime': studentRecord['checkOutTime'] ?? '',
            'remark': studentRecord['remark'] ?? '',
            'className': studentRecord['className'] ?? widget.className ?? '',
            'section': studentRecord['section'] ?? widget.section ?? '',
          };

          monthlyRecords[month]!.add(recordData);
          allRecords.add(recordData);

          if (status == 'Present') {
            monthlyPresent[month] = (monthlyPresent[month] ?? 0) + 1;
          } else if (status == 'Absent') {
            monthlyAbsent[month] = (monthlyAbsent[month] ?? 0) + 1;
          } else if (status == 'Late') {
            monthlyLate[month] = (monthlyLate[month] ?? 0) + 1;
          }
        }
      }

      allRecords.sort((a, b) => b['date'].compareTo(a['date']));

      if (mounted) {
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
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.studentName.isNotEmpty
                  ? 'Attendance - ${widget.studentName}'
                  : 'Attendance History',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (widget.className != null && widget.section != null)
              Text(
                '${widget.className} - ${widget.section}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: false,
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
            tooltip: "Refresh",
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'export') {
                await _exportToPDF();
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.download, size: 18),
                        SizedBox(width: 12),
                        Text('Export Report'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [_buildMonthlyView(), _buildAllRecordsView()],
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
          _buildOverallStatsCard(
            totalPresent,
            totalAbsent,
            totalLate,
            overallRate,
          ),
          const SizedBox(height: 20),
          _buildAttendanceChart(
            monthlyPresent,
            monthlyAbsent,
            monthlyLate,
            months,
          ),
          const SizedBox(height: 20),
          _buildMonthlyBreakdown(
            months,
            monthlyPresent,
            monthlyAbsent,
            monthlyLate,
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStatsCard(
    int present,
    int absent,
    int late,
    double rate,
  ) {
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
      final lateCount = late[month]?.toDouble() ?? 0;

      List<BarChartRodData> rods = [];

      if (presentCount > 0) {
        rods.add(
          BarChartRodData(
            toY: presentCount,
            color: Colors.green,
            width: 18,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }

      if (absentCount > 0) {
        rods.add(
          BarChartRodData(
            toY: absentCount,
            color: Colors.red,
            width: 18,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }

      if (lateCount > 0) {
        rods.add(
          BarChartRodData(
            toY: lateCount,
            color: Colors.orange,
            width: 18,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }

      barGroups.add(BarChartGroupData(x: i, barRods: rods, barsSpace: 2));
    }

    double maxY = 0;
    for (var month in months) {
      final total =
          (present[month] ?? 0) + (absent[month] ?? 0) + (late[month] ?? 0);
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Green: Present | Red: Absent | Orange: Late',
            style: TextStyle(fontSize: 11, color: Colors.grey),
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
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 9),
                        );
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
                          return Text(
                            DateFormat('MMM').format(date),
                            style: const TextStyle(fontSize: 9),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
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
                      final lateCount = late[month] ?? 0;
                      return BarTooltipItem(
                        '$month\nPresent: $presentCount\nAbsent: $absentCount\nLate: $lateCount',
                        const TextStyle(color: Colors.white, fontSize: 10),
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      rate >= 75
                          ? Colors.green.shade100
                          : Colors.orange.shade100,
                  child: Text(
                    '${presentCount + absentCount}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: rate >= 75 ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
                title: Text(
                  monthName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Present: $presentCount | Absent: $absentCount',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${rate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: rate >= 75 ? Colors.green : Colors.orange,
                      ),
                    ),
                    if (lateCount > 0)
                      Text(
                        '$lateCount late',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.orange,
                        ),
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
    final allRecords = List<Map<String, dynamic>>.from(
      _attendanceData['allRecords'] ?? [],
    );

    if (allRecords.isEmpty) {
      return _buildEmptyState();
    }

    // Group by year for sections
    Map<String, List<Map<String, dynamic>>> groupedByYear = {};
    for (var record in allRecords) {
      String year = record['date'].substring(0, 4);
      if (!groupedByYear.containsKey(year)) {
        groupedByYear[year] = [];
      }
      groupedByYear[year]!.add(record);
    }

    List<String> years =
        groupedByYear.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: years.length,
      itemBuilder: (context, yearIndex) {
        final year = years[yearIndex];
        final records = groupedByYear[year]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Year $year',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade700,
                ),
              ),
            ),
            ...records.map((record) => _buildRecordCard(record)),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record) {
    final date = DateTime.parse(record['date']);
    final status = record['status'];
    final checkInTime = record['checkInTime'];
    final checkOutTime = record['checkOutTime'];
    final remark = record['remark'];

    Color getStatusColor() {
      switch (status) {
        case 'Present':
          return Colors.green;
        case 'Absent':
          return Colors.red;
        case 'Late':
          return Colors.orange;
        default:
          return Colors.grey;
      }
    }

    IconData getStatusIcon() {
      switch (status) {
        case 'Present':
          return Icons.check_circle;
        case 'Absent':
          return Icons.cancel;
        case 'Late':
          return Icons.access_time;
        default:
          return Icons.help_outline;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showRecordDetails(record),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: getStatusColor().withOpacity(0.1),
                    child: Icon(
                      getStatusIcon(),
                      color: getStatusColor(),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, dd MMMM yyyy').format(date),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: getStatusColor().withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: getStatusColor(),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (record['className'] != null &&
                                record['className'].isNotEmpty)
                              Text(
                                '${record['className']} - ${record['section']}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
                ],
              ),
              if (checkInTime != null && checkInTime.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      Icon(Icons.login, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Check In: $checkInTime',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      if (checkOutTime != null && checkOutTime.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        Icon(Icons.logout, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Check Out: $checkOutTime',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
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
                        Icon(
                          Icons.comment,
                          size: 14,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            remark,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
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
                        color:
                            status == 'Present'
                                ? Colors.green.shade100
                                : (status == 'Late'
                                    ? Colors.orange.shade100
                                    : Colors.red.shade100),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        status == 'Present'
                            ? Icons.check_circle
                            : (status == 'Late'
                                ? Icons.access_time
                                : Icons.cancel),
                        color:
                            status == 'Present'
                                ? Colors.green
                                : (status == 'Late'
                                    ? Colors.orange
                                    : Colors.red),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
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
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  status == 'Present'
                                      ? Colors.green
                                      : (status == 'Late'
                                          ? Colors.orange
                                          : Colors.red),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                if (checkInTime != null && checkInTime.isNotEmpty)
                  _DetailRow(label: 'Check In Time', value: checkInTime),
                if (checkOutTime != null && checkOutTime.isNotEmpty)
                  _DetailRow(label: 'Check Out Time', value: checkOutTime),
                if (remark != null && remark.isNotEmpty)
                  _DetailRow(label: 'Remark', value: remark),
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Attendance history will appear here once marked by teacher',
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadAttendanceData,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToPDF() async {
    final allRecords = List<Map<String, dynamic>>.from(
      _attendanceData['allRecords'] ?? [],
    );

    if (allRecords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isExporting = true);

    // Calculate summary stats
    int present = 0, absent = 0, late = 0;
    for (var record in allRecords) {
      switch (record['status']) {
        case 'Present':
          present++;
          break;
        case 'Absent':
          absent++;
          break;
        case 'Late':
          late++;
          break;
      }
    }
    int total = present + absent;
    double percentage = total > 0 ? (present / total) * 100 : 0;

    // Show summary dialog (PDF generation placeholder)
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Attendance Report Summary'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Student: ${widget.studentName}'),
                const SizedBox(height: 8),
                Text('Total Days: ${allRecords.length}'),
                Text('Present: $present'),
                Text('Absent: $absent'),
                if (late > 0) Text('Late: $late'),
                const Divider(),
                Text(
                  'Attendance Rate: ${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: percentage >= 75 ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PDF export will be available soon'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                ),
                child: const Text('Export PDF'),
              ),
            ],
          ),
    );

    setState(() => _isExporting = false);
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
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
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
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
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
