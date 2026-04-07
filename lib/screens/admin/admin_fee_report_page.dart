import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AdminAnalyticsPage extends StatefulWidget {
  final String schoolId;

  const AdminAnalyticsPage({super.key, required this.schoolId});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = "This Month";
  String _selectedClass = "All Classes";
  bool _isLoading = true;

  // Data storage
  Map<String, dynamic> _attendanceData = {};
  Map<String, dynamic> _feeData = {};
  Map<String, dynamic> _performanceData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllAnalytics() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadAttendanceAnalytics(),
      _loadFeeAnalytics(),
      _loadPerformanceAnalytics(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadAttendanceAnalytics() async {
    final attendanceRef = FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('attendance');

    final snapshot = await attendanceRef.get();

    Map<String, int> dailyPresent = {};
    Map<String, int> dailyAbsent = {};
    Map<String, double> monthlyAverage = {};
    Map<String, double> classWiseAttendance = {};
    Map<String, int> classTotalStudents = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final date = data['date'] as String?;
      final status = data['status'] as String?;
      final className = data['className'] as String? ?? 'Unknown';
      final studentId = data['studentId'] as String?;

      if (date != null && status != null) {
        // Daily breakdown
        if (status == 'Present') {
          dailyPresent[date] = (dailyPresent[date] ?? 0) + 1;
        } else {
          dailyAbsent[date] = (dailyAbsent[date] ?? 0) + 1;
        }

        // Track total students per class for accurate percentage
        if (studentId != null && className != 'Unknown') {
          classTotalStudents[className] =
              (classTotalStudents[className] ?? 0) + 1;
        }

        // Class-wise attendance (count present)
        if (!classWiseAttendance.containsKey(className)) {
          classWiseAttendance[className] = 0.0;
        }
        if (status == 'Present') {
          classWiseAttendance[className] =
              (classWiseAttendance[className] ?? 0) + 1;
        }

        // Monthly average
        final month = date.substring(0, 7);
        if (!monthlyAverage.containsKey(month)) {
          monthlyAverage[month] = 0.0;
        }
        monthlyAverage[month] =
            (monthlyAverage[month] ?? 0) + (status == 'Present' ? 1 : 0);
      }
    }

    // Convert class-wise counts to percentages
    Map<String, double> classWisePercentage = {};
    classWiseAttendance.forEach((className, presentCount) {
      int totalStudents = classTotalStudents[className] ?? 1;
      classWisePercentage[className] = (presentCount / totalStudents) * 100;
    });

    setState(() {
      _attendanceData['dailyPresent'] = dailyPresent;
      _attendanceData['dailyAbsent'] = dailyAbsent;
      _attendanceData['monthlyAverage'] = monthlyAverage;
      _attendanceData['classWise'] = classWisePercentage;
      _attendanceData['classWiseCount'] = classWiseAttendance;
    });
  }

  Future<void> _loadFeeAnalytics() async {
    final feesRef = FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('fees');

    final snapshot = await feesRef.get();

    Map<String, double> monthlyCollected = {};
    Map<String, double> monthlyPending = {};
    double totalCollected = 0;
    double totalPending = 0;
    double collectionRate = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final date = data['date'] as String?;
      final amount = (data['amount'] as num?)?.toDouble() ?? 0;
      final status = data['status'] as String?;

      if (date != null) {
        final month = date.substring(0, 7);

        if (status == 'Paid') {
          monthlyCollected[month] = (monthlyCollected[month] ?? 0) + amount;
          totalCollected += amount;
        } else {
          monthlyPending[month] = (monthlyPending[month] ?? 0) + amount;
          totalPending += amount;
        }
      }
    }

    collectionRate =
    totalCollected + totalPending > 0
        ? (totalCollected / (totalCollected + totalPending)) * 100
        : 0;

    setState(() {
      _feeData['monthlyCollected'] = monthlyCollected;
      _feeData['monthlyPending'] = monthlyPending;
      _feeData['totalCollected'] = totalCollected;
      _feeData['totalPending'] = totalPending;
      _feeData['collectionRate'] = collectionRate;
    });
  }

  Future<void> _loadPerformanceAnalytics() async {
    setState(() {
      _performanceData['topStudents'] = [];
      _performanceData['subjectWise'] = {};
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: _buildAppBar(),
      body:
      _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      title: const Text(
        "Analytics Dashboard",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: const [
          Tab(icon: Icon(Icons.calendar_today), text: "Attendance"),
          Tab(icon: Icon(Icons.currency_rupee), text: "Fees"),
          Tab(icon: Icon(Icons.insights), text: "Performance"),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.download),
          onPressed: _exportAnalytics,
          tooltip: "Export Report",
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadAllAnalytics,
          tooltip: "Refresh",
        ),
      ],
    );
  }

  Widget _buildBody() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildAttendanceTab(),
        _buildFeesTab(),
        _buildPerformanceTab(),
      ],
    );
  }

  // ================= ATTENDANCE TAB =================
  Widget _buildAttendanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodFilter(),
          const SizedBox(height: 16),
          _buildAttendanceSummaryCards(),
          const SizedBox(height: 24),
          _buildAttendanceTrendChart(),
          const SizedBox(height: 24),
          _buildEnhancedClassWiseAttendance(),
          const SizedBox(height: 24),
          _buildAttendanceHeatmap(),
        ],
      ),
    );
  }

  // Helper method to safely sum map values
  int _sumMapValues(Map<String, int>? map) {
    if (map == null || map.isEmpty) return 0;
    return map.values.reduce((a, b) => a + b);
  }

  Widget _buildAttendanceSummaryCards() {
    // Safely get the maps with proper type checking
    Map<String, int> presentMap = {};
    Map<String, int> absentMap = {};

    if (_attendanceData['dailyPresent'] != null &&
        _attendanceData['dailyPresent'] is Map) {
      presentMap = Map<String, int>.from(_attendanceData['dailyPresent']);
    }

    if (_attendanceData['dailyAbsent'] != null &&
        _attendanceData['dailyAbsent'] is Map) {
      absentMap = Map<String, int>.from(_attendanceData['dailyAbsent']);
    }

    int totalPresent = _sumMapValues(presentMap);
    int totalAbsent = _sumMapValues(absentMap);

    double attendanceRate =
    totalPresent + totalAbsent > 0
        ? (totalPresent / (totalPresent + totalAbsent)) * 100
        : 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildSummaryCard(
          "Attendance Rate",
          "${attendanceRate.toStringAsFixed(1)}%",
          Icons.trending_up,
          Colors.green,
          _getAttendanceTrend(),
        ),
        _buildSummaryCard(
          "Present",
          totalPresent.toString(),
          Icons.check_circle,
          Colors.blue,
          "Total present days",
        ),
        _buildSummaryCard(
          "Absent",
          totalAbsent.toString(),
          Icons.cancel,
          Colors.red,
          "Total absent days",
        ),
        _buildSummaryCard(
          "Best Day",
          _getBestAttendanceDay(),
          Icons.emoji_events,
          Colors.orange,
          "Highest attendance",
        ),
      ],
    );
  }

  Widget _buildAttendanceTrendChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Attendance Trend",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                "Last 7 Days",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(height: 250, child: LineChart(_buildLineChartData())),
          const SizedBox(height: 16),
          _buildChartLegend(),
        ],
      ),
    );
  }

  LineChartData _buildLineChartData() {
    List<FlSpot> spots = [];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final attendanceData = [85, 88, 92, 87, 90, 84, 82];

    for (int i = 0; i < days.length; i++) {
      spots.add(FlSpot(i.toDouble(), attendanceData[i].toDouble()));
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 20,
        getDrawingHorizontalLine: (value) {
          return FlLine(color: Colors.grey.shade300, strokeWidth: 1);
        },
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 20,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}%',
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (value, meta) {
              int index = value.toInt();
              if (index >= 0 && index < days.length) {
                return Text(days[index], style: const TextStyle(fontSize: 10));
              }
              return const Text('');
            },
          ),
        ),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.shade300),
      ),
      minX: 0,
      maxX: 6,
      minY: 0,
      maxY: 100,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.blue,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.blue.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }

  // ENHANCED CLASS-WISE ATTENDANCE BAR CHART
  Widget _buildEnhancedClassWiseAttendance() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Class-wise Attendance",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                "Current Month",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Attendance percentage by class with target line",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: BarChart(_buildEnhancedAttendanceBarChart()),
          ),
          const SizedBox(height: 16),
          _buildAttendanceLegend(),
        ],
      ),
    );
  }

  BarChartData _buildEnhancedAttendanceBarChart() {
    // Get real data from Firestore or use sample data
    final Map<String, double> classData =
    _attendanceData['classWise'] != null &&
        _attendanceData['classWise'] is Map
        ? Map<String, double>.from(_attendanceData['classWise'])
        : {};

    List<String> classes = [];
    List<double> attendanceRates = [];

    if (classData.isNotEmpty) {
      classes = classData.keys.toList();
      attendanceRates = classData.values.map((v) => v.toDouble()).toList();
    } else {
      // Sample data for preview
      classes = [
        'Class 1',
        'Class 2',
        'Class 3',
        'Class 4',
        'Class 5',
        'Class 6',
      ];
      attendanceRates = [92.5, 88.3, 85.7, 90.2, 94.1, 87.6];
    }

    final targetRate = 90.0;

    List<BarChartGroupData> barGroups = [];

    for (int i = 0; i < classes.length; i++) {
      final rate = attendanceRates[i];
      final color =
      rate >= targetRate ? Colors.green.shade600 : Colors.orange.shade600;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: rate,
              color: color,
              width: 35,
              borderRadius: BorderRadius.circular(6),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 100,
                color: Colors.grey.shade200,
              ),
            ),
          ],
          showingTooltipIndicators: [0],
        ),
      );
    }

    return BarChartData(
      barGroups: barGroups,
      alignment: BarChartAlignment.spaceAround,
      maxY: 100,
      minY: 0,
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            interval: 20,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              int index = value.toInt();
              if (index >= 0 && index < classes.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    classes[index],
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
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
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 20,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.shade300,
            strokeWidth: 1,
            dashArray: [5, 5],
          );
        },
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            return BarTooltipItem(
              '${attendanceRates[groupIndex].toStringAsFixed(1)}%',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAttendanceLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 20,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.green.shade600,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        const Text("Above 90%", style: TextStyle(fontSize: 11)),
        const SizedBox(width: 20),
        Container(
          width: 20,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.orange.shade600,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        const Text("Below 90%", style: TextStyle(fontSize: 11)),
        const SizedBox(width: 20),
        Container(width: 20, height: 2, color: Colors.grey.shade400),
        const SizedBox(width: 6),
        const Text("Target Line", style: TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _buildAttendanceHeatmap() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Attendance Calendar",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Green = High attendance, Red = Low attendance",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: 28,
            itemBuilder: (context, index) {
              final attendance =
              [
                85,
                90,
                92,
                78,
                88,
                95,
                82,
                87,
                91,
                93,
                76,
                89,
                94,
                86,
                88,
                92,
                84,
                87,
                90,
                93,
                85,
                88,
                91,
                82,
                87,
                90,
                94,
                89,
              ][index];

              Color getColor() {
                if (attendance >= 90) return Colors.green.shade700;
                if (attendance >= 80) return Colors.green.shade400;
                if (attendance >= 70) return Colors.orange.shade400;
                return Colors.red.shade400;
              }

              return Container(
                decoration: BoxDecoration(
                  color: getColor(),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ================= FEES TAB =================
  Widget _buildFeesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeeSummaryCards(),
          const SizedBox(height: 24),
          _buildEnhancedFeeCollectionChart(),
          const SizedBox(height: 24),
          _buildFeeBreakdown(),
          const SizedBox(height: 24),
          _buildOutstandingFees(),
        ],
      ),
    );
  }

  Widget _buildFeeSummaryCards() {
    double collected = _feeData['totalCollected'] ?? 0;
    double pending = _feeData['totalPending'] ?? 0;
    double rate = _feeData['collectionRate'] ?? 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildSummaryCard(
          "Total Collected",
          "₹${collected.toStringAsFixed(0)}",
          Icons.account_balance_wallet,
          Colors.green,
          "Overall collection",
        ),
        _buildSummaryCard(
          "Pending Amount",
          "₹${pending.toStringAsFixed(0)}",
          Icons.pending_actions,
          Colors.orange,
          "Due payments",
        ),
        _buildSummaryCard(
          "Collection Rate",
          "${rate.toStringAsFixed(1)}%",
          Icons.trending_up,
          Colors.blue,
          "Success rate",
        ),
        _buildSummaryCard(
          "Average per Student",
          "₹${((collected + pending) / 100).toStringAsFixed(0)}",
          Icons.people,
          Colors.purple,
          "Per student total",
        ),
      ],
    );
  }

  // ENHANCED FEE COLLECTION BAR CHART
  Widget _buildEnhancedFeeCollectionChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Fee Collection Overview",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                "Monthly Trend",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Collected vs Pending fees by month",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 20),
          SizedBox(height: 340, child: BarChart(_buildEnhancedFeeBarChart())),
          const SizedBox(height: 16),
          _buildFeeLegend(),
        ],
      ),
    );
  }

  BarChartData _buildEnhancedFeeBarChart() {
    // Get real data from Firestore or use sample data
    final Map<String, double> monthlyCollected =
    _feeData['monthlyCollected'] != null &&
        _feeData['monthlyCollected'] is Map
        ? Map<String, double>.from(_feeData['monthlyCollected'])
        : {};
    final Map<String, double> monthlyPending =
    _feeData['monthlyPending'] != null && _feeData['monthlyPending'] is Map
        ? Map<String, double>.from(_feeData['monthlyPending'])
        : {};

    List<String> months = [];
    List<double> collected = [];
    List<double> pending = [];

    if (monthlyCollected.isNotEmpty) {
      months = monthlyCollected.keys.toList();
      collected = monthlyCollected.values.map((v) => v.toDouble()).toList();
      pending = monthlyPending.values.map((v) => v.toDouble()).toList();
    } else {
      // Sample data for preview
      months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
      collected = [45000, 52000, 48000, 55000, 58000, 62000];
      pending = [5000, 3000, 4000, 2000, 2500, 1800];
    }

    List<BarChartGroupData> barGroups = [];

    for (int i = 0; i < months.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: collected[i],
              color: Colors.green.shade600,
              width: 20,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
              ),
            ),
            BarChartRodData(
              toY: pending[i],
              color: Colors.orange.shade600,
              width: 20,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
              ),
            ),
          ],
          barsSpace: 4,
        ),
      );
    }

    return BarChartData(
      barGroups: barGroups,
      alignment: BarChartAlignment.spaceAround,
      maxY: 70000,
      minY: 0,
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 55,
            interval: 10000,
            getTitlesWidget: (value, meta) {
              return Text(
                '₹${(value / 1000).toInt()}k',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
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
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    months[index],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
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
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 10000,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.shade300,
            strokeWidth: 1,
            dashArray: [5, 5],
          );
        },
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final month = months[groupIndex];
            final collectedAmount = collected[groupIndex];
            final pendingAmount = pending[groupIndex];
            final totalAmount = collectedAmount + pendingAmount;

            return BarTooltipItem(
              '$month\nCollected: ₹${collectedAmount.toStringAsFixed(0)}\nPending: ₹${pendingAmount.toStringAsFixed(0)}\nTotal: ₹${totalAmount.toStringAsFixed(0)}',
              const TextStyle(color: Colors.white, fontSize: 11),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeeLegend() {
    double totalCollected = _feeData['totalCollected'] ?? 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 20,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.green.shade600,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        const Text("Collected", style: TextStyle(fontSize: 11)),
        const SizedBox(width: 20),
        Container(
          width: 20,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.orange.shade600,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        const Text("Pending", style: TextStyle(fontSize: 11)),
        const SizedBox(width: 20),
        Container(width: 3, height: 12, color: Colors.grey.shade400),
        const SizedBox(width: 6),
        Text(
          "Total collected: ₹${totalCollected.toStringAsFixed(0)}",
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildFeeBreakdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Fee Structure Breakdown",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildBreakdownItem("Tuition Fee", "₹25,000", "65%"),
          const Divider(),
          _buildBreakdownItem("Transport", "₹8,000", "21%"),
          const Divider(),
          _buildBreakdownItem("Library", "₹3,000", "8%"),
          const Divider(),
          _buildBreakdownItem("Sports", "₹2,500", "6%"),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(String title, String amount, String percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(flex: 1, child: Text(amount, textAlign: TextAlign.right)),
          Expanded(
            flex: 1,
            child: Text(
              percentage,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutstandingFees() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Outstanding Payments",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red.shade50,
                  child: Text("${index + 1}"),
                ),
                title: Text("Student ${index + 1}"),
                subtitle: const Text("Due since Feb 2026"),
                trailing: const Text(
                  "₹5,000",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ================= PERFORMANCE TAB =================
  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPerformanceFilters(),
          const SizedBox(height: 16),
          _buildPerformanceSummary(),
          const SizedBox(height: 24),
          _buildSubjectWisePerformance(),
          const SizedBox(height: 24),
          _buildTopPerformers(),
          const SizedBox(height: 24),
          _buildGradeDistribution(),
        ],
      ),
    );
  }

  Widget _buildPerformanceFilters() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedClass,
              decoration: const InputDecoration(
                labelText: "Select Class",
                border: OutlineInputBorder(),
              ),
              items:
              [
                'All Classes',
                'Class 1',
                'Class 2',
                'Class 3',
                'Class 4',
                'Class 5',
              ]
                  .map(
                    (className) => DropdownMenuItem(
                  value: className,
                  child: Text(className),
                ),
              )
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedClass = value!);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedPeriod,
              decoration: const InputDecoration(
                labelText: "Select Period",
                border: OutlineInputBorder(),
              ),
              items:
              ['This Month', 'Last Month', 'This Semester', 'This Year']
                  .map(
                    (period) => DropdownMenuItem(
                  value: period,
                  child: Text(period),
                ),
              )
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedPeriod = value!);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSummary() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12, // Reduced from 16
      mainAxisSpacing: 12,  // Reduced from 16
      childAspectRatio: 1.1, // Adjusted aspect ratio
      children: [
        _buildSummaryCard(
          "Class Average",
          "85%",
          Icons.show_chart,
          Colors.blue,
          "Overall performance",
        ),
        _buildSummaryCard(
          "Top Score",
          "98%",
          Icons.emoji_events,
          Colors.orange,
          "Highest in class",
        ),
        _buildSummaryCard(
          "Pass Rate",
          "94%",
          Icons.check_circle,
          Colors.green,
          "Students passed",
        ),
      ],
    );
  }
  Widget _buildSubjectWisePerformance() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Subject-wise Performance",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(height: 250, child: BarChart(_buildSubjectBarChart())),
        ],
      ),
    );
  }

  BarChartData _buildSubjectBarChart() {
    final subjects = ['Math', 'Science', 'English', 'History', 'Geography'];
    final scores = [82, 88, 85, 79, 84];

    List<BarChartGroupData> barGroups = [];

    for (int i = 0; i < subjects.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: scores[i].toDouble(),
              color: Colors.blue,
              width: 25,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return BarChartData(
      barGroups: barGroups,
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}%',
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              int index = value.toInt();
              if (index >= 0 && index < subjects.length) {
                return Text(
                  subjects[index],
                  style: const TextStyle(fontSize: 10),
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
    );
  }

  Widget _buildTopPerformers() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Top Performers",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: Text(
                    "${index + 1}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text("Student ${index + 1}"),
                subtitle: Text("Class ${index + 1}"),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${95 - index * 2}%",
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGradeDistribution() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Grade Distribution",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildGradeBar("A+ (90-100)", 25),
          const SizedBox(height: 8),
          _buildGradeBar("A (80-89)", 35),
          const SizedBox(height: 8),
          _buildGradeBar("B (70-79)", 20),
          const SizedBox(height: 8),
          _buildGradeBar("C (60-69)", 12),
          const SizedBox(height: 8),
          _buildGradeBar("D (Below 60)", 8),
        ],
      ),
    );
  }

  Widget _buildGradeBar(String grade, int percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(grade, style: const TextStyle(fontSize: 12)),
            Text("$percentage%", style: const TextStyle(fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(
            percentage >= 80
                ? Colors.green
                : percentage >= 60
                ? Colors.orange
                : Colors.red,
          ),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  // ================= HELPER WIDGETS =================
  Widget _buildPeriodFilter() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: _cardDecoration(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _periodChip("Today", "Today"),
            const SizedBox(width: 8),
            _periodChip("This Week", "This Week"),
            const SizedBox(width: 8),
            _periodChip("This Month", "This Month"),
            const SizedBox(width: 8),
            _periodChip("This Year", "This Year"),
          ],
        ),
      ),
    );
  }
  Widget _periodChip(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPeriod = value);
        _loadAttendanceAnalytics();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      String title,
      String value,
      IconData icon,
      Color color,
      String subtitle,
      ) {
    return Container(
      constraints: const BoxConstraints(minHeight: 80), // Add minimum height constraint
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Use minimum vertical space
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  Widget _buildChartLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 20, height: 3, color: Colors.blue),
        const SizedBox(width: 8),
        const Text("Attendance Rate", style: TextStyle(fontSize: 12)),
        const SizedBox(width: 20),
        Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        const Text("Target (90%)", style: TextStyle(fontSize: 12)),
      ],
    );
  }

  String _getAttendanceTrend() {
    return "+5% vs last month";
  }

  String _getBestAttendanceDay() {
    return "Wednesday (92%)";
  }

  Future<void> _exportAnalytics() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Export feature coming soon")),
      );
    }
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
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