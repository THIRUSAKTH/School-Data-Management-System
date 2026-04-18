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

  String _selectedAttendancePeriod = "month";
  String _selectedPerformancePeriod = "month";
  String _selectedClass = "All Classes";
  bool _isLoading = true;

  // Data storage
  Map<String, dynamic> _attendanceData = {};
  Map<String, dynamic> _feeData = {};
  Map<String, dynamic> _performanceData = {};

  // Performance data from Firebase
  List<Map<String, dynamic>> _studentsList = [];
  List<Map<String, dynamic>> _subjectsList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllAnalytics();
    _loadStudentsAndSubjects();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentsAndSubjects() async {
    // Load students
    final studentsSnapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('students')
        .get();

    _studentsList = studentsSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? 'Unknown',
        'className': data['className'] ?? 'Unknown',
        'rollNo': data['rollNo'] ?? '',
      };
    }).toList();

    // Load subjects (you can store these in a 'subjects' collection)
    final subjectsSnapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('subjects')
        .get();

    if (subjectsSnapshot.docs.isNotEmpty) {
      _subjectsList = subjectsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
        };
      }).toList();
    } else {
      // Default subjects if none exist
      _subjectsList = [
        {'id': '1', 'name': 'Mathematics'},
        {'id': '2', 'name': 'Science'},
        {'id': '3', 'name': 'English'},
        {'id': '4', 'name': 'History'},
        {'id': '5', 'name': 'Geography'},
      ];
    }

    setState(() {});
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
    Map<String, Map<int, int>> heatmapData = {}; // date -> {dayOfMonth: presentCount}

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final date = data['date'] as String?;
      final status = data['status'] as String?;
      final className = data['className'] as String? ?? 'Unknown';
      final studentId = data['studentId'] as String?;

      if (date != null && status != null) {
        // Daily counts
        if (status == 'Present') {
          dailyPresent[date] = (dailyPresent[date] ?? 0) + 1;
        } else {
          dailyAbsent[date] = (dailyAbsent[date] ?? 0) + 1;
        }

        // Class-wise unique students
        if (studentId != null && className != 'Unknown') {
          classTotalStudents[className] = (classTotalStudents[className] ?? 0) + 1;
        }

        // Class-wise attendance
        if (!classWiseAttendance.containsKey(className)) {
          classWiseAttendance[className] = 0.0;
        }
        if (status == 'Present') {
          classWiseAttendance[className] = (classWiseAttendance[className] ?? 0) + 1;
        }

        // Monthly average
        final month = date.substring(0, 7);
        if (!monthlyAverage.containsKey(month)) {
          monthlyAverage[month] = 0.0;
        }
        monthlyAverage[month] = (monthlyAverage[month] ?? 0) + (status == 'Present' ? 1 : 0);

        // Heatmap data
        try {
          final dateObj = DateTime.parse(date);
          final dayOfMonth = dateObj.day;
          if (!heatmapData.containsKey(month)) {
            heatmapData[month] = {};
          }
          if (status == 'Present') {
            heatmapData[month]![dayOfMonth] = (heatmapData[month]![dayOfMonth] ?? 0) + 1;
          }
        } catch (e) {
          // Invalid date format
        }
      }
    }

    // Calculate class-wise percentages
    Map<String, double> classWisePercentage = {};
    classWiseAttendance.forEach((className, presentCount) {
      int totalStudents = classTotalStudents[className] ?? 1;
      classWisePercentage[className] = (presentCount / totalStudents) * 100;
    });

    // Get current month's heatmap
    String currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    Map<int, int> currentMonthHeatmap = heatmapData[currentMonth] ?? {};

    setState(() {
      _attendanceData['dailyPresent'] = dailyPresent;
      _attendanceData['dailyAbsent'] = dailyAbsent;
      _attendanceData['monthlyAverage'] = monthlyAverage;
      _attendanceData['classWise'] = classWisePercentage;
      _attendanceData['classWiseCount'] = classWiseAttendance;
      _attendanceData['heatmap'] = currentMonthHeatmap;
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
    List<Map<String, dynamic>> outstandingList = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final date = data['date'] as String?;
      final amount = (data['amount'] as num?)?.toDouble() ?? 0;
      final status = data['status'] as String?;
      final studentName = data['studentName'] ?? 'Unknown';
      final dueDate = data['dueDate'] ?? date ?? '';

      if (date != null) {
        final month = date.substring(0, 7);

        if (status == 'Paid') {
          monthlyCollected[month] = (monthlyCollected[month] ?? 0) + amount;
          totalCollected += amount;
        } else if (status == 'Pending') {
          monthlyPending[month] = (monthlyPending[month] ?? 0) + amount;
          totalPending += amount;
          outstandingList.add({
            'studentName': studentName,
            'amount': amount,
            'dueDate': dueDate,
            'status': status,
          });
        }
      }
    }

    collectionRate = totalCollected + totalPending > 0
        ? (totalCollected / (totalCollected + totalPending)) * 100
        : 0;

    setState(() {
      _feeData['monthlyCollected'] = monthlyCollected;
      _feeData['monthlyPending'] = monthlyPending;
      _feeData['totalCollected'] = totalCollected;
      _feeData['totalPending'] = totalPending;
      _feeData['collectionRate'] = collectionRate;
      _feeData['outstandingList'] = outstandingList;
    });
  }

  Future<void> _loadPerformanceAnalytics() async {
    // Load exam results from Firestore
    final resultsRef = FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('exam_results');

    final snapshot = await resultsRef.get();

    Map<String, List<double>> subjectScores = {};
    Map<String, List<double>> studentScores = {};
    List<Map<String, dynamic>> topStudents = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final subject = data['subject'] ?? 'Unknown';
      final score = (data['score'] as num?)?.toDouble() ?? 0;
      final studentId = data['studentId'] ?? '';
      final studentName = data['studentName'] ?? 'Unknown';
      final className = data['className'] ?? 'Unknown';

      // Subject-wise scores
      if (!subjectScores.containsKey(subject)) {
        subjectScores[subject] = [];
      }
      subjectScores[subject]!.add(score);

      // Student-wise scores
      if (!studentScores.containsKey(studentId)) {
        studentScores[studentId] = [];
      }
      studentScores[studentId]!.add(score);
    }

    // Calculate subject averages
    Map<String, double> subjectAverages = {};
    subjectScores.forEach((subject, scores) {
      subjectAverages[subject] = scores.reduce((a, b) => a + b) / scores.length;
    });

    // Calculate student averages and get top performers
    List<Map<String, dynamic>> studentAverages = [];
    studentScores.forEach((studentId, scores) {
      double avg = scores.reduce((a, b) => a + b) / scores.length;
      studentAverages.add({
        'studentId': studentId,
        'average': avg,
      });
    });

    // Sort and get top 5
    studentAverages.sort((a, b) => b['average'].compareTo(a['average']));
    topStudents = studentAverages.take(5).toList();

    // Calculate grade distribution
    Map<String, int> gradeDistribution = {
      'A+': 0,
      'A': 0,
      'B': 0,
      'C': 0,
      'D': 0,
    };

    for (var student in studentAverages) {
      double avg = student['average'];
      if (avg >= 90) gradeDistribution['A+'] = (gradeDistribution['A+'] ?? 0) + 1;
      else if (avg >= 80) gradeDistribution['A'] = (gradeDistribution['A'] ?? 0) + 1;
      else if (avg >= 70) gradeDistribution['B'] = (gradeDistribution['B'] ?? 0) + 1;
      else if (avg >= 60) gradeDistribution['C'] = (gradeDistribution['C'] ?? 0) + 1;
      else gradeDistribution['D'] = (gradeDistribution['D'] ?? 0) + 1;
    }

    // Calculate class average
    double classAverage = studentAverages.isNotEmpty
        ? studentAverages.map((s) => s['average']).reduce((a, b) => a + b) / studentAverages.length
        : 0;

    // Calculate pass rate (students with average >= 60)
    int passedCount = studentAverages.where((s) => s['average'] >= 60).length;
    double passRate = studentAverages.isNotEmpty
        ? (passedCount / studentAverages.length) * 100
        : 0;

    setState(() {
      _performanceData['subjectAverages'] = subjectAverages;
      _performanceData['topStudents'] = topStudents;
      _performanceData['gradeDistribution'] = gradeDistribution;
      _performanceData['classAverage'] = classAverage;
      _performanceData['passRate'] = passRate;
      _performanceData['topScore'] = studentAverages.isNotEmpty ? studentAverages.first['average'] : 0;
      _performanceData['totalStudents'] = studentAverages.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTopSummary(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildBody(),
          ),
        ],
      ),
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

  Widget _buildTopSummary() {
    double totalStudents = (_attendanceData['classWiseCount'] != null)
        ? (_attendanceData['classWiseCount'] as Map).values.fold(0, (a, b) => a + b)
        : 0;

    double totalCollected = _feeData['totalCollected'] ?? 0;

    // Calculate real attendance rate
    Map<String, int> presentMap = _attendanceData['dailyPresent'] ?? {};
    Map<String, int> absentMap = _attendanceData['dailyAbsent'] ?? {};
    int totalPresent = presentMap.values.fold(0, (a, b) => a + b);
    int totalAbsent = absentMap.values.fold(0, (a, b) => a + b);
    double attendanceRate = totalPresent + totalAbsent > 0
        ? (totalPresent / (totalPresent + totalAbsent)) * 100
        : 0;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _miniCard("Students", totalStudents.toInt().toString(), Icons.people),
          _miniCard("Attendance", "${attendanceRate.toStringAsFixed(0)}%", Icons.check_circle),
          _miniCard("Revenue", "₹${totalCollected.toInt()}", Icons.currency_rupee),
        ],
      ),
    );
  }

  Widget _miniCard(String title, String value, IconData icon) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(fontSize: 12)),
        ],
      ),
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

  int _sumMapValues(Map<String, int>? map) {
    if (map == null || map.isEmpty) return 0;
    return map.values.reduce((a, b) => a + b);
  }

  Widget _buildAttendanceSummaryCards() {
    Map<String, int> presentMap = _attendanceData['dailyPresent'] ?? {};
    Map<String, int> absentMap = _attendanceData['dailyAbsent'] ?? {};
    int totalPresent = _sumMapValues(presentMap);
    int totalAbsent = _sumMapValues(absentMap);
    double attendanceRate = totalPresent + totalAbsent > 0
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
          _getBestAttendanceDay(presentMap),
          Icons.emoji_events,
          Colors.orange,
          "Highest attendance",
        ),
      ],
    );
  }

  Widget _buildAttendanceTrendChart() {
    Map<String, int> presentMap = _attendanceData['dailyPresent'] ?? {};

    // Get last 7 days data
    List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    List<double> attendanceRates = List.filled(7, 0.0);

    // Calculate daily attendance rates
    DateTime now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      DateTime date = now.subtract(Duration(days: 6 - i));
      String dateStr = DateFormat('yyyy-MM-dd').format(date);
      int present = presentMap[dateStr] ?? 0;
      int absent = _attendanceData['dailyAbsent']?[dateStr] ?? 0;
      int total = present + absent;
      attendanceRates[i] = total > 0 ? (present / total) * 100 : 0;
    }

    List<FlSpot> spots = [];
    for (int i = 0; i < days.length; i++) {
      spots.add(FlSpot(i.toDouble(), attendanceRates[i]));
    }

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
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
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
                        return Text('${value.toInt()}%', style: const TextStyle(fontSize: 10));
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
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildChartLegend(),
        ],
      ),
    );
  }

  Widget _buildEnhancedClassWiseAttendance() {
    Map<String, double> classData = _attendanceData['classWise'] != null
        ? Map<String, double>.from(_attendanceData['classWise'])
        : {};

    List<String> classes = classData.isNotEmpty ? classData.keys.toList() : [];
    List<double> attendanceRates = classData.isNotEmpty
        ? classData.values.map((v) => v.toDouble()).toList()
        : [];

    if (classes.isEmpty) {
      classes = ['No Data'];
      attendanceRates = [0];
    }

    final targetRate = 90.0;

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < classes.length; i++) {
      final rate = attendanceRates[i];
      final color = rate >= targetRate ? Colors.green.shade600 : Colors.orange.shade600;

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
                      reservedSize: 45,
                      interval: 20,
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toInt()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500));
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
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
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
                    return FlLine(color: Colors.grey.shade300, strokeWidth: 1, dashArray: [5, 5]);
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
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildAttendanceLegend(),
        ],
      ),
    );
  }

  Widget _buildAttendanceLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 20, height: 12, decoration: BoxDecoration(color: Colors.green.shade600, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 6),
        const Text("Above 90%", style: TextStyle(fontSize: 11)),
        const SizedBox(width: 20),
        Container(width: 20, height: 12, decoration: BoxDecoration(color: Colors.orange.shade600, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 6),
        const Text("Below 90%", style: TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _buildAttendanceHeatmap() {
    Map<int, int> heatmapData = _attendanceData['heatmap'] ?? {};
    DateTime now = DateTime.now();
    int daysInMonth = DateTime(now.year, now.month + 1, 0).day;

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
          Text(
            DateFormat('MMMM yyyy').format(now),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: daysInMonth,
            itemBuilder: (context, index) {
              int day = index + 1;
              int? presentCount = heatmapData[day];

              // Calculate attendance rate for this day (simplified)
              // You would need total students count for accurate percentage
              double attendanceRate = presentCount != null && presentCount > 0 ? 85.0 : 65.0;
              if (presentCount != null) {
                int totalStudents = _studentsList.length;
                attendanceRate = totalStudents > 0 ? (presentCount / totalStudents) * 100 : 0;
              }

              Color getColor() {
                if (attendanceRate >= 90) return Colors.green.shade700;
                if (attendanceRate >= 80) return Colors.green.shade400;
                if (attendanceRate >= 70) return Colors.orange.shade400;
                return Colors.red.shade400;
              }

              return Container(
                decoration: BoxDecoration(
                  color: getColor(),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$day',
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
          _buildOutstandingFees(),
        ],
      ),
    );
  }

  Widget _buildFeeSummaryCards() {
    double collected = _feeData['totalCollected'] ?? 0;
    double pending = _feeData['totalPending'] ?? 0;
    double rate = _feeData['collectionRate'] ?? 0;
    double perStudentAvg = _studentsList.isNotEmpty ? (collected + pending) / _studentsList.length : 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildSummaryCard("Total Collected", "₹${collected.toStringAsFixed(0)}", Icons.account_balance_wallet, Colors.green, "Overall collection"),
        _buildSummaryCard("Pending Amount", "₹${pending.toStringAsFixed(0)}", Icons.pending_actions, Colors.orange, "Due payments"),
        _buildSummaryCard("Collection Rate", "${rate.toStringAsFixed(1)}%", Icons.trending_up, Colors.blue, "Success rate"),
        _buildSummaryCard("Average per Student", "₹${perStudentAvg.toStringAsFixed(0)}", Icons.people, Colors.purple, "Per student total"),
      ],
    );
  }

  Widget _buildEnhancedFeeCollectionChart() {
    Map<String, double> monthlyCollected = _feeData['monthlyCollected'] != null
        ? Map<String, double>.from(_feeData['monthlyCollected'])
        : {};
    Map<String, double> monthlyPending = _feeData['monthlyPending'] != null
        ? Map<String, double>.from(_feeData['monthlyPending'])
        : {};

    List<String> months = monthlyCollected.isNotEmpty ? monthlyCollected.keys.toList() : [];
    List<double> collected = monthlyCollected.isNotEmpty ? monthlyCollected.values.map((v) => v).toList() : [];
    List<double> pending = monthlyPending.isNotEmpty ? monthlyPending.values.map((v) => v).toList() : [];

    if (months.isEmpty) {
      months = ['Jan', 'Feb', 'Mar'];
      collected = [0, 0, 0];
      pending = [0, 0, 0];
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
            BarChartRodData(
              toY: pending[i],
              color: Colors.orange.shade600,
              width: 20,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ],
          barsSpace: 4,
        ),
      );
    }

    double maxY = 0;
    for (int i = 0; i < collected.length; i++) {
      double total = collected[i] + pending[i];
      if (total > maxY) maxY = total;
    }
    maxY = maxY > 0 ? maxY * 1.1 : 100000;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Fee Collection Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("Monthly Trend", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 340,
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
                      reservedSize: 55,
                      interval: maxY / 5,
                      getTitlesWidget: (value, meta) {
                        return Text('₹${(value / 1000).toInt()}k', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500));
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
                            child: Text(months[index], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
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
                  horizontalInterval: maxY / 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey.shade300, strokeWidth: 1, dashArray: [5, 5]);
                  },
                ),
                borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300, width: 1)),
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
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildFeeLegend(),
        ],
      ),
    );
  }

  Widget _buildFeeLegend() {
    double totalCollected = _feeData['totalCollected'] ?? 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 20, height: 12, decoration: BoxDecoration(color: Colors.green.shade600, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 6),
        const Text("Collected", style: TextStyle(fontSize: 11)),
        const SizedBox(width: 20),
        Container(width: 20, height: 12, decoration: BoxDecoration(color: Colors.orange.shade600, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 6),
        const Text("Pending", style: TextStyle(fontSize: 11)),
        const SizedBox(width: 20),
        Text("Total collected: ₹${totalCollected.toStringAsFixed(0)}", style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _buildOutstandingFees() {
    List<Map<String, dynamic>> outstandingList = List.from(_feeData['outstandingList'] ?? []);

    if (outstandingList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 48),
              SizedBox(height: 12),
              Text("No outstanding payments!", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text("All fees are up to date", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Outstanding Payments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: outstandingList.length > 10 ? 10 : outstandingList.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final item = outstandingList[index];
              return ListTile(
                leading: CircleAvatar(backgroundColor: Colors.red.shade50, child: Text("${index + 1}")),
                title: Text(item['studentName'] ?? 'Unknown'),
                subtitle: Text("Due since ${item['dueDate'] ?? 'Unknown'}"),
                trailing: Text("₹${(item['amount'] ?? 0).toStringAsFixed(0)}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              );
            },
          ),
          if (outstandingList.length > 10)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text("+ ${outstandingList.length - 10} more students", style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
    final List<String> periodValues = ['month', 'quarter', 'year'];
    final Map<String, String> periodLabels = {
      'month': 'This Month',
      'quarter': 'This Quarter',
      'year': 'This Year'
    };

    // Get unique class names from students list
    Set<String> uniqueClasses = _studentsList
        .map((student) => student['className'] as String)
        .toSet();

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
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem<String>(value: 'All Classes', child: Text('All Classes')),
                ...uniqueClasses.map((className) {
                  return DropdownMenuItem<String>(
                    value: className,
                    child: Text(className),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedClass = value!;
                  _loadPerformanceAnalytics(); // Reload data when class changes
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedPerformancePeriod,
              decoration: const InputDecoration(
                labelText: "Select Period",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: periodValues.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(periodLabels[value]!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPerformancePeriod = value!;
                  _loadPerformanceAnalytics(); // Reload data when period changes
                });
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildPerformanceSummary() {
    double classAverage = _performanceData['classAverage'] ?? 0;
    double topScore = _performanceData['topScore'] ?? 0;
    double passRate = _performanceData['passRate'] ?? 0;

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _buildSummaryCard("Class Average", "${classAverage.toStringAsFixed(1)}%", Icons.show_chart, Colors.blue, "Overall performance"),
        _buildSummaryCard("Top Score", "${topScore.toStringAsFixed(1)}%", Icons.emoji_events, Colors.orange, "Highest in class"),
        _buildSummaryCard("Pass Rate", "${passRate.toStringAsFixed(1)}%", Icons.check_circle, Colors.green, "Students passed"),
      ],
    );
  }

  Widget _buildSubjectWisePerformance() {
    Map<String, double> subjectAverages = _performanceData['subjectAverages'] ?? {};

    List<String> subjects = subjectAverages.isNotEmpty ? subjectAverages.keys.toList() : ['No Data'];
    List<double> scores = subjectAverages.isNotEmpty ? subjectAverages.values.map((v) => v).toList() : [0];

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < subjects.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(toY: scores[i], color: Colors.blue, width: 25, borderRadius: BorderRadius.circular(4))],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Subject-wise Performance", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                barGroups: barGroups,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) => Text('${value.toInt()}%', style: const TextStyle(fontSize: 10)))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                    int index = value.toInt();
                    if (index >= 0 && index < subjects.length) return Text(subjects[index], style: const TextStyle(fontSize: 10));
                    return const Text('');
                  })),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: true),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformers() {
    List<Map<String, dynamic>> topStudents = List.from(_performanceData['topStudents'] ?? []);

    if (topStudents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: const Center(child: Text("No performance data available")),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Top Performers", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topStudents.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final student = topStudents[index];
              final studentInfo = _studentsList.firstWhere(
                    (s) => s['id'] == student['studentId'],
                orElse: () => {'name': 'Unknown', 'className': 'Unknown'},
              );
              return ListTile(
                leading: CircleAvatar(backgroundColor: Colors.blue.shade50, child: Text("${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold))),
                title: Text(studentInfo['name'] ?? 'Unknown'),
                subtitle: Text(studentInfo['className'] ?? 'Unknown'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Text("${student['average'].toStringAsFixed(1)}%", style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGradeDistribution() {
    Map<String, int> gradeDist = _performanceData['gradeDistribution'] ?? {'A+': 0, 'A': 0, 'B': 0, 'C': 0, 'D': 0};
    int total = gradeDist.values.fold(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Grade Distribution", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildGradeBar("A+ (90-100)", gradeDist['A+'] ?? 0, total),
          const SizedBox(height: 8),
          _buildGradeBar("A (80-89)", gradeDist['A'] ?? 0, total),
          const SizedBox(height: 8),
          _buildGradeBar("B (70-79)", gradeDist['B'] ?? 0, total),
          const SizedBox(height: 8),
          _buildGradeBar("C (60-69)", gradeDist['C'] ?? 0, total),
          const SizedBox(height: 8),
          _buildGradeBar("D (Below 60)", gradeDist['D'] ?? 0, total),
        ],
      ),
    );
  }

  Widget _buildGradeBar(String grade, int count, int total) {
    double percentage = total > 0 ? (count / total) * 100 : 0;
    Color color = grade.contains('A+') || grade.contains('A') ? Colors.green : (grade.contains('B') ? Colors.orange : Colors.red);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(grade, style: const TextStyle(fontSize: 12)), Text("$count students (${percentage.toStringAsFixed(1)}%)", style: const TextStyle(fontSize: 12))]),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: percentage / 100, backgroundColor: Colors.grey.shade200, valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 8, borderRadius: BorderRadius.circular(4)),
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
            _periodChip("Today", "today"),
            const SizedBox(width: 8),
            _periodChip("This Week", "week"),
            const SizedBox(width: 8),
            _periodChip("This Month", "month"),
            const SizedBox(width: 8),
            _periodChip("This Year", "year"),
          ],
        ),
      ),
    );
  }

  Widget _periodChip(String label, String value) {
    final isSelected = _selectedAttendancePeriod == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedAttendancePeriod = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade700, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis)), Icon(icon, color: color, size: 18)]),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 9, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
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
      ],
    );
  }

  String _getAttendanceTrend() {
    Map<String, int> presentMap = _attendanceData['dailyPresent'] ?? {};
    if (presentMap.isEmpty) return "No data yet";

    List<int> values = presentMap.values.toList();
    if (values.length < 2) return "Insufficient data";

    int lastWeekAvg = values.sublist(values.length > 7 ? values.length - 7 : 0, values.length).reduce((a, b) => a + b) ~/ (values.length > 7 ? 7 : values.length);
    int previousAvg = values.sublist(0, values.length > 7 ? values.length - 7 : values.length).reduce((a, b) => a + b) ~/ (values.length > 7 ? values.length - 7 : values.length);

    double change = ((lastWeekAvg - previousAvg) / previousAvg) * 100;
    return change >= 0 ? "+${change.toStringAsFixed(1)}% vs last month" : "${change.toStringAsFixed(1)}% vs last month";
  }

  String _getBestAttendanceDay(Map<String, int> presentMap) {
    if (presentMap.isEmpty) return "No data";

    String bestDay = "";
    int maxPresent = 0;

    presentMap.forEach((date, present) {
      if (present > maxPresent) {
        maxPresent = present;
        bestDay = date;
      }
    });

    if (bestDay.isNotEmpty) {
      try {
        DateTime date = DateTime.parse(bestDay);
        return DateFormat('EEEE').format(date);
      } catch (e) {
        return "Best Day";
      }
    }
    return "No data";
  }

  Future<void> _exportAnalytics() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Export feature coming soon")));
    }
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
    );
  }
}