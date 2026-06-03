import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

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
  String _errorMessage = '';

  // Data storage
  Map<String, dynamic> _attendanceData = {};
  Map<String, dynamic> _feeData = {};
  Map<String, dynamic> _performanceData = {};

  // Performance data from Firebase
  List<Map<String, dynamic>> _studentsList = [];
  List<Map<String, dynamic>> _classesList = [];
  List<Map<String, dynamic>> _subjectsList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    await _loadStudentsAndClasses();
    await _loadAllAnalytics();

    setState(() => _isLoading = false);
  }

  Future<void> _loadStudentsAndClasses() async {
    try {
      // Load students
      final studentsSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('students')
              .get();

      _studentsList =
          studentsSnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'name': data['name'] ?? 'Unknown',
              'className': data['class'] ?? data['className'] ?? 'Unknown',
              'section': data['section'] ?? '',
              'rollNo': data['rollNo'] ?? '',
            };
          }).toList();

      // Extract unique classes
      Set<String> uniqueClasses = {};
      for (var student in _studentsList) {
        String className = student['className'].toString();
        String section = student['section'].toString();
        String fullClass =
            section.isNotEmpty ? "$className-$section" : className;
        uniqueClasses.add(fullClass);
      }

      _classesList = uniqueClasses.map((c) => {'name': c}).toList();
      _classesList.sort((a, b) => a['name'].compareTo(b['name']));

      // Load subjects
      final subjectsSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('subjects')
              .get();

      if (subjectsSnapshot.docs.isNotEmpty) {
        _subjectsList =
            subjectsSnapshot.docs.map((doc) {
              final data = doc.data();
              return {'id': doc.id, 'name': data['name'] ?? 'Unknown'};
            }).toList();
      } else {
        _subjectsList = [
          {'id': '1', 'name': 'Mathematics'},
          {'id': '2', 'name': 'Science'},
          {'id': '3', 'name': 'English'},
          {'id': '4', 'name': 'Social Studies'},
          {'id': '5', 'name': 'Computer Science'},
        ];
      }
    } catch (e) {
      debugPrint('Error loading students/subjects: $e');
      setState(() => _errorMessage = 'Failed to load student data: $e');
    }
  }

  Future<void> _loadAllAnalytics() async {
    try {
      await Future.wait([
        _loadAttendanceAnalytics(),
        _loadFeeAnalytics(),
        _loadPerformanceAnalytics(),
      ]);
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      setState(() => _errorMessage = 'Failed to load analytics: $e');
    }
  }

  int _sumMapValues(Map<String, int>? map) {
    if (map == null || map.isEmpty) return 0;
    int sum = 0;
    for (var value in map.values) {
      sum += value;
    }
    return sum;
  }

  Future<void> _loadAttendanceAnalytics() async {
    try {
      final attendanceRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('attendance');

      final snapshot = await attendanceRef.get();

      Map<String, int> dailyPresent = {};
      Map<String, int> dailyAbsent = {};
      Map<String, int> dailyLate = {};
      Map<String, double> classWiseAttendance = {};
      Map<String, int> classTotalStudents = {};
      Map<String, Map<int, int>> heatmapData = {};

      for (var dateDoc in snapshot.docs) {
        final date = dateDoc.id;

        // Get records subcollection
        final recordsSnapshot =
            await dateDoc.reference.collection('records').get();

        for (var recordDoc in recordsSnapshot.docs) {
          final recordData = recordDoc.data();
          final status = recordData['status'] as String? ?? 'Absent';
          final className =
              recordData['className'] as String? ??
              recordData['class'] as String? ??
              'Unknown';
          final studentId = recordData['studentId'] as String? ?? '';

          // Daily counts
          if (status == 'Present') {
            dailyPresent[date] = (dailyPresent[date] ?? 0) + 1;
          } else if (status == 'Late') {
            dailyLate[date] = (dailyLate[date] ?? 0) + 1;
          } else if (status == 'Absent') {
            dailyAbsent[date] = (dailyAbsent[date] ?? 0) + 1;
          }

          // Class-wise unique students
          if (studentId.isNotEmpty && className != 'Unknown') {
            Set<String>? classStudents =
                classTotalStudents.containsKey(className) ? null : null;
            classTotalStudents[className] =
                (classTotalStudents[className] ?? 0) + 1;
          }

          // Class-wise attendance (count present as 1, late as 0.5)
          if (className != 'Unknown') {
            if (!classWiseAttendance.containsKey(className)) {
              classWiseAttendance[className] = 0.0;
            }
            if (status == 'Present') {
              classWiseAttendance[className] =
                  (classWiseAttendance[className] ?? 0) + 1;
            } else if (status == 'Late') {
              classWiseAttendance[className] =
                  (classWiseAttendance[className] ?? 0) + 0.5;
            }
          }

          // Heatmap data
          try {
            final dateObj = DateTime.parse(date);
            final dayOfMonth = dateObj.day;
            final month = date.substring(0, 7);
            if (!heatmapData.containsKey(month)) {
              heatmapData[month] = {};
            }
            if (status == 'Present' || status == 'Late') {
              heatmapData[month]![dayOfMonth] =
                  (heatmapData[month]![dayOfMonth] ?? 0) + 1;
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

      // Calculate weekly trends
      Map<String, double> weeklyTrends = _calculateWeeklyTrends(
        dailyPresent,
        dailyAbsent,
        dailyLate,
      );

      setState(() {
        _attendanceData['dailyPresent'] = dailyPresent;
        _attendanceData['dailyAbsent'] = dailyAbsent;
        _attendanceData['dailyLate'] = dailyLate;
        _attendanceData['classWise'] = classWisePercentage;
        _attendanceData['heatmap'] = currentMonthHeatmap;
        _attendanceData['weeklyTrends'] = weeklyTrends;
      });
    } catch (e) {
      debugPrint('Error loading attendance analytics: $e');
    }
  }

  Map<String, double> _calculateWeeklyTrends(
    Map<String, int> present,
    Map<String, int> absent,
    Map<String, int> late,
  ) {
    Map<String, double> weeklyRates = {
      'Monday': 0.0,
      'Tuesday': 0.0,
      'Wednesday': 0.0,
      'Thursday': 0.0,
      'Friday': 0.0,
      'Saturday': 0.0,
    };
    Map<String, int> weeklyTotal = {
      'Monday': 0,
      'Tuesday': 0,
      'Wednesday': 0,
      'Thursday': 0,
      'Friday': 0,
      'Saturday': 0,
    };
    Map<String, int> weeklyPresent = {
      'Monday': 0,
      'Tuesday': 0,
      'Wednesday': 0,
      'Thursday': 0,
      'Friday': 0,
      'Saturday': 0,
    };

    Set<String> allDates = {...present.keys, ...absent.keys, ...late.keys};
    for (var date in allDates) {
      try {
        final dateObj = DateTime.parse(date);
        final dayName = DateFormat('EEEE').format(dateObj);
        if (weeklyRates.containsKey(dayName)) {
          int p = present[date] ?? 0;
          int a = absent[date] ?? 0;
          int l = late[date] ?? 0;
          int total = p + a + l;
          weeklyTotal[dayName] = (weeklyTotal[dayName] ?? 0) + total;
          weeklyPresent[dayName] =
              (weeklyPresent[dayName] ?? 0) + p + (l * 0.5).round();
        }
      } catch (e) {}
    }

    for (var day in weeklyRates.keys) {
      int total = weeklyTotal[day] ?? 0;
      int presentCount = weeklyPresent[day] ?? 0;
      weeklyRates[day] = total > 0 ? (presentCount / total) * 100 : 0;
    }

    return weeklyRates;
  }

  Future<void> _loadFeeAnalytics() async {
    try {
      final feesRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('student_fees');

      final snapshot = await feesRef.get();

      Map<String, double> monthlyCollected = {};
      Map<String, double> monthlyPending = {};
      Map<String, double> classWiseCollection = {};
      double totalCollected = 0;
      double totalPending = 0;
      List<Map<String, dynamic>> outstandingList = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final dueDate = data['dueDate'] as String?;
        final amount = (data['amount'] as num?)?.toDouble() ?? 0;
        final status = data['status'] as String?;
        final studentName = data['studentName'] ?? 'Unknown';
        final className = data['className'] ?? 'Unknown';
        final feeType = data['feeType'] ?? 'Fee';

        if (dueDate != null && dueDate.length >= 7) {
          final month = dueDate.substring(0, 7);

          if (status == 'paid') {
            monthlyCollected[month] = (monthlyCollected[month] ?? 0) + amount;
            totalCollected += amount;
            classWiseCollection[className] =
                (classWiseCollection[className] ?? 0) + amount;
          } else if (status == 'pending') {
            monthlyPending[month] = (monthlyPending[month] ?? 0) + amount;
            totalPending += amount;
            outstandingList.add({
              'studentName': studentName,
              'amount': amount,
              'dueDate': dueDate,
              'status': status,
              'className': className,
              'feeType': feeType,
            });
          }
        }
      }

      // Sort outstanding by amount (highest first)
      outstandingList.sort((a, b) => b['amount'].compareTo(a['amount']));

      double collectionRate =
          totalCollected + totalPending > 0
              ? (totalCollected / (totalCollected + totalPending)) * 100
              : 0;

      setState(() {
        _feeData['monthlyCollected'] = monthlyCollected;
        _feeData['monthlyPending'] = monthlyPending;
        _feeData['totalCollected'] = totalCollected;
        _feeData['totalPending'] = totalPending;
        _feeData['collectionRate'] = collectionRate;
        _feeData['outstandingList'] = outstandingList;
        _feeData['classWiseCollection'] = classWiseCollection;
      });
    } catch (e) {
      debugPrint('Error loading fee analytics: $e');
    }
  }

  Future<void> _loadPerformanceAnalytics() async {
    try {
      final resultsRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('exam_results');

      final snapshot = await resultsRef.get();

      Map<String, List<double>> subjectScores = {};
      Map<String, List<double>> studentScores = {};
      Map<String, Map<String, double>> classSubjectAverages = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final subject = data['subject'] ?? 'Unknown';
        final score = (data['marksObtained'] as num?)?.toDouble() ?? 0;
        final maxMarks = (data['maxMarks'] as num?)?.toDouble() ?? 100;
        final studentId = data['studentId'] ?? '';
        final className = data['className'] ?? 'Unknown';

        double percentage = maxMarks > 0 ? (score / maxMarks) * 100 : 0;

        if (percentage > 0) {
          // Subject-wise scores
          if (!subjectScores.containsKey(subject)) {
            subjectScores[subject] = [];
          }
          subjectScores[subject]!.add(percentage);

          // Student-wise scores
          if (!studentScores.containsKey(studentId)) {
            studentScores[studentId] = [];
          }
          studentScores[studentId]!.add(percentage);

          // Class-wise subject averages
          if (!classSubjectAverages.containsKey(className)) {
            classSubjectAverages[className] = {};
          }
          if (!classSubjectAverages[className]!.containsKey(subject)) {
            classSubjectAverages[className]![subject] = 0.0;
          }
          classSubjectAverages[className]![subject] =
              (classSubjectAverages[className]![subject] ?? 0) + percentage;
        }
      }

      // Calculate subject averages
      Map<String, double> subjectAverages = {};
      subjectScores.forEach((subject, scores) {
        if (scores.isNotEmpty) {
          subjectAverages[subject] =
              scores.reduce((a, b) => a + b) / scores.length;
        }
      });

      // Calculate student averages and get top performers
      List<Map<String, dynamic>> studentAverages = [];
      studentScores.forEach((studentId, scores) {
        if (scores.isNotEmpty) {
          double avg = scores.reduce((a, b) => a + b) / scores.length;
          studentAverages.add({'studentId': studentId, 'average': avg});
        }
      });

      // Sort and get top 10
      studentAverages.sort((a, b) => b['average'].compareTo(a['average']));
      List<Map<String, dynamic>> topStudents =
          studentAverages.take(10).toList();

      // Calculate grade distribution
      Map<String, int> gradeDistribution = {
        'A+ (90-100)': 0,
        'A (80-89)': 0,
        'B (70-79)': 0,
        'C (60-69)': 0,
        'D (Below 60)': 0,
      };

      for (var student in studentAverages) {
        double avg = student['average'];
        if (avg >= 90)
          gradeDistribution['A+ (90-100)'] =
              (gradeDistribution['A+ (90-100)'] ?? 0) + 1;
        else if (avg >= 80)
          gradeDistribution['A (80-89)'] =
              (gradeDistribution['A (80-89)'] ?? 0) + 1;
        else if (avg >= 70)
          gradeDistribution['B (70-79)'] =
              (gradeDistribution['B (70-79)'] ?? 0) + 1;
        else if (avg >= 60)
          gradeDistribution['C (60-69)'] =
              (gradeDistribution['C (60-69)'] ?? 0) + 1;
        else
          gradeDistribution['D (Below 60)'] =
              (gradeDistribution['D (Below 60)'] ?? 0) + 1;
      }

      // Calculate class average
      double classAverage =
          studentAverages.isNotEmpty
              ? studentAverages
                      .map((s) => s['average'] as double)
                      .reduce((a, b) => a + b) /
                  studentAverages.length
              : 0;

      // Calculate pass rate
      int passedCount =
          studentAverages.where((s) => (s['average'] as double) >= 60).length;
      double passRate =
          studentAverages.isNotEmpty
              ? (passedCount / studentAverages.length) * 100
              : 0;
      double topScore =
          studentAverages.isNotEmpty
              ? studentAverages.first['average'] as double
              : 0;

      setState(() {
        _performanceData['subjectAverages'] = subjectAverages;
        _performanceData['topStudents'] = topStudents;
        _performanceData['gradeDistribution'] = gradeDistribution;
        _performanceData['classAverage'] = classAverage;
        _performanceData['passRate'] = passRate;
        _performanceData['topScore'] = topScore;
        _performanceData['totalStudents'] = studentAverages.length;
        _performanceData['classSubjectAverages'] = classSubjectAverages;
      });
    } catch (e) {
      debugPrint('Error loading performance analytics: $e');
      _setDefaultPerformanceData();
    }
  }

  void _setDefaultPerformanceData() {
    setState(() {
      _performanceData['subjectAverages'] = {};
      _performanceData['topStudents'] = [];
      _performanceData['gradeDistribution'] = {
        'A+ (90-100)': 0,
        'A (80-89)': 0,
        'B (70-79)': 0,
        'C (60-69)': 0,
        'D (Below 60)': 0,
      };
      _performanceData['classAverage'] = 0;
      _performanceData['passRate'] = 0;
      _performanceData['topScore'] = 0;
      _performanceData['classSubjectAverages'] = {};
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
              : _errorMessage.isNotEmpty
              ? _buildErrorWidget()
              : Column(
                children: [
                  _buildTopSummary(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAttendanceTab(),
                        _buildFeesTab(),
                        _buildPerformanceTab(),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            "Error Loading Analytics",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _initializeData,
            icon: const Icon(Icons.refresh),
            label: const Text("Retry"),
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
          onPressed: _initializeData,
          tooltip: "Refresh",
        ),
      ],
    );
  }

  Widget _buildTopSummary() {
    int totalStudents = _studentsList.length;
    double totalCollected = _feeData['totalCollected'] ?? 0;
    int totalPresent = _sumMapValues(_attendanceData['dailyPresent'] ?? {});
    int totalAbsent = _sumMapValues(_attendanceData['dailyAbsent'] ?? {});
    int totalLate = _sumMapValues(_attendanceData['dailyLate'] ?? {});
    int totalAttendanceDays = totalPresent + totalAbsent + totalLate;

    double attendanceRate =
        totalAttendanceDays > 0
            ? ((totalPresent + (totalLate * 0.5)) / totalAttendanceDays) * 100
            : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _miniCard(
            "Students",
            totalStudents.toString(),
            Icons.people,
            Colors.blue,
          ),
          _miniCard(
            "Attendance",
            "${attendanceRate.toStringAsFixed(0)}%",
            Icons.check_circle,
            Colors.green,
          ),
          _miniCard(
            "Revenue",
            "₹${(totalCollected / 1000).toStringAsFixed(0)}K",
            Icons.currency_rupee,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _miniCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color,
                ),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= ATTENDANCE TAB =================
  Widget _buildAttendanceTab() {
    return RefreshIndicator(
      onRefresh: _initializeData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAttendanceSummaryCards(),
            const SizedBox(height: 24),
            _buildWeeklyTrendChart(),
            const SizedBox(height: 24),
            _buildClassWiseAttendance(),
            const SizedBox(height: 24),
            _buildAttendanceHeatmap(),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceSummaryCards() {
    int totalPresent = _sumMapValues(_attendanceData['dailyPresent'] ?? {});
    int totalAbsent = _sumMapValues(_attendanceData['dailyAbsent'] ?? {});
    int totalLate = _sumMapValues(_attendanceData['dailyLate'] ?? {});
    int totalDays = totalPresent + totalAbsent + totalLate;
    double attendanceRate =
        totalDays > 0 ? (totalPresent / totalDays) * 100 : 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _buildSummaryCard(
          "Attendance Rate",
          "${attendanceRate.toStringAsFixed(1)}%",
          Icons.trending_up,
          Colors.green,
          "Overall",
        ),
        _buildSummaryCard(
          "Present Days",
          totalPresent.toString(),
          Icons.check_circle,
          Colors.blue,
          "Total present",
        ),
        _buildSummaryCard(
          "Absent Days",
          totalAbsent.toString(),
          Icons.cancel,
          Colors.red,
          "Total absent",
        ),
        _buildSummaryCard(
          "Late Arrivals",
          totalLate.toString(),
          Icons.access_time,
          Colors.orange,
          "Late students",
        ),
      ],
    );
  }

  Widget _buildWeeklyTrendChart() {
    Map<String, double> weeklyTrends = _attendanceData['weeklyTrends'] ?? {};

    if (weeklyTrends.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: const Center(child: Text("No weekly data available")),
      );
    }

    List<String> days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    List<double> rates = days.map((day) => weeklyTrends[day] ?? 0).toList();

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < days.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: rates[i],
              color:
                  rates[i] >= 75
                      ? Colors.green
                      : (rates[i] >= 50 ? Colors.orange : Colors.red),
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
            "Weekly Attendance Trend",
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
                      getTitlesWidget:
                          (value, meta) => Text(
                            '${value.toInt()}%',
                            style: const TextStyle(fontSize: 10),
                          ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              days[index].substring(0, 3),
                              style: const TextStyle(fontSize: 10),
                            ),
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassWiseAttendance() {
    Map<String, double> classData =
        _attendanceData['classWise'] != null
            ? Map<String, double>.from(_attendanceData['classWise'])
            : {};

    if (classData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: const Center(child: Text("No class attendance data available")),
      );
    }

    List<MapEntry<String, double>> sortedEntries = classData.entries.toList();
    sortedEntries.sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Class-wise Attendance",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedEntries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final entry = sortedEntries[index];
              final rate = entry.value;
              final color =
                  rate >= 75
                      ? Colors.green
                      : (rate >= 50 ? Colors.orange : Colors.red);

              return Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            LinearProgressIndicator(
                              value: rate / 100,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 45,
                        child: Text(
                          "${rate.toStringAsFixed(1)}%",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceHeatmap() {
    Map<int, int> heatmapData = _attendanceData['heatmap'] ?? {};
    DateTime now = DateTime.now();
    int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    int totalStudents = _studentsList.length;
    if (totalStudents == 0) totalStudents = 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Attendance Calendar",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemCount: daysInMonth,
            itemBuilder: (context, index) {
              int day = index + 1;
              int? presentCount = heatmapData[day];
              double attendanceRate = (presentCount ?? 0) / totalStudents * 100;

              Color getColor() {
                if (attendanceRate >= 90) return Colors.green.shade700;
                if (attendanceRate >= 75) return Colors.green.shade400;
                if (attendanceRate >= 50) return Colors.orange.shade400;
                return Colors.red.shade400;
              }

              return Container(
                decoration: BoxDecoration(
                  color:
                      presentCount != null ? getColor() : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$day',
                  style: TextStyle(
                    color:
                        presentCount != null
                            ? Colors.white
                            : Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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
    return RefreshIndicator(
      onRefresh: _initializeData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFeeSummaryCards(),
            const SizedBox(height: 24),
            _buildClassWiseCollection(),
            const SizedBox(height: 24),
            _buildOutstandingFees(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeSummaryCards() {
    double collected = _feeData['totalCollected'] ?? 0;
    double pending = _feeData['totalPending'] ?? 0;
    double rate = _feeData['collectionRate'] ?? 0;
    double perStudentAvg =
        _studentsList.isNotEmpty
            ? (collected + pending) / _studentsList.length
            : 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _buildSummaryCard(
          "Total Collected",
          "₹${(collected / 1000).toStringAsFixed(0)}K",
          Icons.account_balance_wallet,
          Colors.green,
          "Overall",
        ),
        _buildSummaryCard(
          "Pending Amount",
          "₹${(pending / 1000).toStringAsFixed(0)}K",
          Icons.pending_actions,
          Colors.orange,
          "Due",
        ),
        _buildSummaryCard(
          "Collection Rate",
          "${rate.toStringAsFixed(1)}%",
          Icons.trending_up,
          Colors.blue,
          "Success rate",
        ),
        _buildSummaryCard(
          "Avg per Student",
          "₹${perStudentAvg.toStringAsFixed(0)}",
          Icons.people,
          Colors.purple,
          "Per student",
        ),
      ],
    );
  }

  Widget _buildClassWiseCollection() {
    Map<String, double> classWise = _feeData['classWiseCollection'] ?? {};

    if (classWise.isEmpty) {
      return const SizedBox();
    }

    List<MapEntry<String, double>> sorted = classWise.entries.toList();
    sorted.sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Class-wise Collection",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final entry = sorted[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: Text(
                    entry.key.substring(0, 1),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(entry.key),
                trailing: Text(
                  "₹${(entry.value / 1000).toStringAsFixed(0)}K",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOutstandingFees() {
    List<Map<String, dynamic>> outstandingList = List.from(
      _feeData['outstandingList'] ?? [],
    );

    if (outstandingList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: _cardDecoration(),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 48),
              SizedBox(height: 12),
              Text(
                "No outstanding payments!",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                "All fees are up to date",
                style: TextStyle(color: Colors.grey),
              ),
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
          const Text(
            "Outstanding Payments",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: outstandingList.length > 8 ? 8 : outstandingList.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final item = outstandingList[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red.shade50,
                  child: Text(
                    "${index + 1}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  item['studentName'] ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text("${item['feeType']} - Due: ${item['dueDate']}"),
                trailing: Text(
                  "₹${(item['amount'] ?? 0).toStringAsFixed(0)}",
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
          if (outstandingList.length > 8)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "+ ${outstandingList.length - 8} more students",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  // ================= PERFORMANCE TAB =================
  Widget _buildPerformanceTab() {
    return RefreshIndicator(
      onRefresh: _initializeData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPerformanceSummary(),
            const SizedBox(height: 24),
            _buildSubjectWisePerformance(),
            const SizedBox(height: 24),
            _buildTopPerformers(),
            const SizedBox(height: 24),
            _buildGradeDistribution(),
          ],
        ),
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
        _buildSummaryCard(
          "Class Average",
          "${classAverage.toStringAsFixed(1)}%",
          Icons.show_chart,
          Colors.blue,
          "Overall",
        ),
        _buildSummaryCard(
          "Top Score",
          "${topScore.toStringAsFixed(1)}%",
          Icons.emoji_events,
          Colors.orange,
          "Highest",
        ),
        _buildSummaryCard(
          "Pass Rate",
          "${passRate.toStringAsFixed(1)}%",
          Icons.check_circle,
          Colors.green,
          "Students passed",
        ),
      ],
    );
  }

  Widget _buildSubjectWisePerformance() {
    Map<String, double> subjectAverages =
        _performanceData['subjectAverages'] ?? {};

    if (subjectAverages.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: const Center(
          child: Text("No subject performance data available"),
        ),
      );
    }

    List<MapEntry<String, double>> sortedSubjects =
        subjectAverages.entries.toList();
    sortedSubjects.sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Subject-wise Performance",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedSubjects.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final entry = sortedSubjects[index];
              final rate = entry.value;
              final color =
                  rate >= 75
                      ? Colors.green
                      : (rate >= 60 ? Colors.orange : Colors.red);

              return Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: rate / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 45,
                        child: Text(
                          "${rate.toStringAsFixed(1)}%",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformers() {
    List<Map<String, dynamic>> topStudents = List.from(
      _performanceData['topStudents'] ?? [],
    );

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
          const Text(
            "Top Performers",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
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
                leading: CircleAvatar(
                  backgroundColor: Colors.amber.shade100,
                  child: Text(
                    "${index + 1}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  studentInfo['name'] ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(studentInfo['className'] ?? 'Unknown'),
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
                    "${(student['average'] as double).toStringAsFixed(1)}%",
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
    Map<String, int> gradeDist = _performanceData['gradeDistribution'] ?? {};
    int total = gradeDist.values.fold(0, (a, b) => a + b);

    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: const Center(
          child: Text("No grade distribution data available"),
        ),
      );
    }

    List<MapEntry<String, int>> sortedGrades = gradeDist.entries.toList();
    sortedGrades.sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Grade Distribution",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedGrades.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = sortedGrades[index];
              double percentage = total > 0 ? (entry.value / total) * 100 : 0;
              Color color =
                  entry.key.contains('A')
                      ? Colors.green
                      : (entry.key.contains('B') ? Colors.orange : Colors.red);

              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key, style: const TextStyle(fontSize: 12)),
                      Text(
                        "${entry.value} students",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ================= HELPER WIDGETS =================
  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            maxLines: 1,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 9, color: Colors.grey),
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Future<void> _exportAnalytics() async {
    if (_attendanceData.isEmpty &&
        _feeData.isEmpty &&
        _performanceData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No data to export"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final pdf = pw.Document();

    // Add cover page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build:
            (context) => pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'School Analytics Report',
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    DateFormat('dd MMMM yyyy').format(DateTime.now()),
                    style: pw.TextStyle(fontSize: 16, color: PdfColors.grey),
                  ),
                  pw.SizedBox(height: 40),
                  pw.Text(
                    'Generated by School ERP System',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                  ),
                ],
              ),
            ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Report exported successfully"),
          backgroundColor: Colors.green,
        ),
      );
    }
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
