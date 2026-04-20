import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:schoolprojectjan/app_config.dart';
import 'package:schoolprojectjan/screens/admin/exam_management_page.dart';
import 'package:schoolprojectjan/screens/admin/school_settings_page.dart';
import 'package:schoolprojectjan/screens/admin/select_class_for_attendance_page.dart';
import 'package:schoolprojectjan/screens/common/profile_page.dart';
import 'package:schoolprojectjan/screens/common/settings_page.dart';
import 'admin_analytics_page.dart';
import 'admin_attendance_overview.dart';
import 'admin_feeupload_page.dart';
import 'class_management_page.dart';
import 'create_class_page.dart';
import 'student_management_page.dart';
import 'teacher_management_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _selectedPeriod = "week"; // week, month, year

  // Cache for chart data to prevent excessive rebuilds
  Map<String, dynamic> _cachedChartData = {};
  DateTime _lastFetchTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchChartData();
  }

  Future<void> _fetchChartData() async {
    // Only fetch if data is older than 5 minutes
    if (DateTime.now().difference(_lastFetchTime).inMinutes < 5 && _cachedChartData.isNotEmpty) {
      return;
    }

    setState(() {
      _lastFetchTime = DateTime.now();
    });

    // Fetch attendance data for chart
    final attendanceSnapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(AppConfig.schoolId)
        .collection('attendance')
        .get();

    // Fetch fee data for chart
    final feeSnapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(AppConfig.schoolId)
        .collection('fees')
        .get();

    // Process attendance data
    Map<String, int> dailyAttendance = {};
    Map<String, int> classAttendance = {};
    int totalPresent = 0;
    int totalAbsent = 0;

    for (var doc in attendanceSnapshot.docs) {
      final data = doc.data();
      final date = data['date'] as String?;
      final status = data['status'] as String?;
      final className = data['className'] as String? ?? 'Unknown';

      if (date != null && status != null) {
        if (status == 'Present') {
          totalPresent++;
          dailyAttendance[date] = (dailyAttendance[date] ?? 0) + 1;
        } else if (status == 'Absent') {
          totalAbsent++;
        }

        classAttendance[className] = (classAttendance[className] ?? 0) + (status == 'Present' ? 1 : 0);
      }
    }

    // Process fee data
    double totalCollected = 0;
    double totalPending = 0;
    Map<String, double> monthlyFee = {};

    for (var doc in feeSnapshot.docs) {
      final data = doc.data();
      final amount = (data['amount'] as num?)?.toDouble() ?? 0;
      final status = data['status'] as String?;
      final date = data['date'] as String?;

      if (date != null) {
        final month = date.substring(0, 7);
        if (status == 'Paid') {
          totalCollected += amount;
          monthlyFee[month] = (monthlyFee[month] ?? 0) + amount;
        } else {
          totalPending += amount;
        }
      }
    }

    setState(() {
      _cachedChartData = {
        'totalPresent': totalPresent,
        'totalAbsent': totalAbsent,
        'dailyAttendance': dailyAttendance,
        'classAttendance': classAttendance,
        'totalCollected': totalCollected,
        'totalPending': totalPending,
        'monthlyFee': monthlyFee,
        'attendanceRate': totalPresent + totalAbsent > 0
            ? (totalPresent / (totalPresent + totalAbsent)) * 100
            : 0,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      drawer: _buildDrawer(context),
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchChartData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Cards
              _buildStatsGrid(),
              const SizedBox(height: 24),

              // Today's Overview
              _buildTodayOverview(),
              const SizedBox(height: 24),

              // Period Selector & Charts
              _buildPeriodSelector(),
              const SizedBox(height: 16),

              // Attendance Chart
              _buildAttendanceChart(),
              const SizedBox(height: 24),

              // Fee Collection Chart
              _buildFeeChart(),
              const SizedBox(height: 24),

              // Quick Actions
              _buildQuickActions(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 0,
      title: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('schools')
            .doc(AppConfig.schoolId)
            .snapshots(),
        builder: (context, snapshot) {
          String schoolName = "School";
          String logoUrl = "";

          if (snapshot.hasData && snapshot.data!.exists) {
            final school = snapshot.data!;
            schoolName = school['schoolName'] ?? "School";
            logoUrl = school['logoUrl'] ?? "";
          }

          return Row(
            children: [
              if (logoUrl.isNotEmpty)
                CircleAvatar(
                  backgroundImage: NetworkImage(logoUrl),
                  radius: 18,
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schoolName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "Admin Dashboard",
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () async {
            await _fetchChartData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dashboard refreshed')),
              );
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            // TODO: Navigate to notifications
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notifications coming soon')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildLiveCard(
          "Students",
          Icons.people,
          Colors.blue,
          FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('students')
              .snapshots(),
        ),
        _buildLiveCard(
          "Teachers",
          Icons.school,
          Colors.purple,
          FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('teachers')
              .snapshots(),
        ),
        _buildLiveCard(
          "Fees\nCollected",
          Icons.currency_rupee,
          Colors.green,
          null,
          customValue: _cachedChartData['totalCollected']?.toInt() ?? 0,
          isCurrency: true,
        ),
        _buildLiveCard(
          "Attendance\nRate",
          Icons.check_circle,
          Colors.orange,
          null,
          customValue: _cachedChartData['attendanceRate']?.toInt() ?? 0,
          suffix: '%',
        ),
      ],
    );
  }

  Widget _buildLiveCard(
      String title,
      IconData icon,
      Color color,
      Stream<QuerySnapshot>? stream, {
        int? customValue,
        bool isCurrency = false,
        String suffix = '',
      }) {
    if (stream != null) {
      return StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
          return _StatCard(
            title: title,
            value: count.toString(),
            icon: icon,
            color: color,
          );
        },
      );
    } else {
      String displayValue = customValue?.toString() ?? '0';
      if (isCurrency) {
        displayValue = '₹$displayValue';
      }
      if (suffix.isNotEmpty) {
        displayValue = '$displayValue$suffix';
      }
      return _StatCard(
        title: title,
        value: displayValue,
        icon: icon,
        color: color,
      );
    }
  }

  Widget _buildTodayOverview() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('attendance')
          .where('date', isEqualTo: DateFormat('yyyy-MM-dd').format(DateTime.now()))
          .get(),
      builder: (context, snapshot) {
        int presentToday = 0;
        int absentToday = 0;

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['status'] == 'Present') {
              presentToday++;
            } else if (data['status'] == 'Absent') {
              absentToday++;
            }
          }
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.today, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    "Today's Overview",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _OverviewItem(
                    title: "Present",
                    value: presentToday.toString(),
                    color: Colors.green,
                    icon: Icons.check_circle,
                  ),
                  _OverviewItem(
                    title: "Absent",
                    value: absentToday.toString(),
                    color: Colors.red,
                    icon: Icons.cancel,
                  ),
                  _OverviewItem(
                    title: "Attendance Rate",
                    value: presentToday + absentToday > 0
                        ? "${((presentToday / (presentToday + absentToday)) * 100).toStringAsFixed(1)}%"
                        : "0%",
                    color: Colors.orange,
                    icon: Icons.trending_up,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: _cardDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _PeriodChip(
            label: "Week",
            value: "week",
            selected: _selectedPeriod == "week",
            onTap: () {
              setState(() {
                _selectedPeriod = "week";
              });
            },
          ),
          _PeriodChip(
            label: "Month",
            value: "month",
            selected: _selectedPeriod == "month",
            onTap: () {
              setState(() {
                _selectedPeriod = "month";
              });
            },
          ),
          _PeriodChip(
            label: "Year",
            value: "year",
            selected: _selectedPeriod == "year",
            onTap: () {
              setState(() {
                _selectedPeriod = "year";
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceChart() {
    final dailyData = _cachedChartData['dailyAttendance'] ?? {};
    List<FlSpot> spots = [];

    // Get last 7 days
    List<String> last7Days = [];
    for (int i = 6; i >= 0; i--) {
      last7Days.add(DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: i))));
    }

    int maxValue = 0;
    for (int i = 0; i < last7Days.length; i++) {
      int count = dailyData[last7Days[i]] ?? 0;
      spots.add(FlSpot(i.toDouble(), count.toDouble()));
      if (count > maxValue) maxValue = count;
    }

    // Calculate interval - FIXED: ensure it's never zero
    double interval = (maxValue / 5).ceilToDouble();
    if (interval == 0) interval = 1; // Prevent zero interval

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                "Attendance Trend",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Last 7 days attendance count",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: interval, // FIXED: using safe interval
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
                borderData: FlBorderData(show: true),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: (maxValue + 5).toDouble(),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
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
        ],
      ),
    );
  }
  Widget _buildFeeChart() {
    final monthlyFee = _cachedChartData['monthlyFee'] ?? {};
    List<String> months = monthlyFee.keys.toList();
    months.sort();

    // If no data, show last 6 months
    if (months.isEmpty) {
      for (int i = 5; i >= 0; i--) {
        months.add(DateFormat('yyyy-MM').format(DateTime.now().subtract(Duration(days: 30 * i))));
      }
    }

    // Take last 6 months
    if (months.length > 6) {
      months = months.sublist(months.length - 6);
    }

    List<BarChartGroupData> barGroups = [];
    double maxY = 0;

    for (int i = 0; i < months.length; i++) {
      double amount = monthlyFee[months[i]] ?? 0;
      if (amount > maxY) maxY = amount;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: amount,
              color: Colors.green,
              width: 30,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    maxY = maxY > 0 ? maxY * 1.1 : 100000;

    // Calculate interval - FIXED: ensure it's never zero
    double interval = maxY / 5;
    if (interval == 0) interval = 10000; // Prevent zero interval

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.attach_money, color: Colors.green),
              SizedBox(width: 8),
              Text(
                "Fee Collection",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Monthly fee collection trend",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
                      reservedSize: 55,
                      interval: interval, // FIXED: using safe interval
                      getTitlesWidget: (value, meta) {
                        if (value >= 1000) {
                          return Text('₹${(value / 1000).toInt()}k', style: const TextStyle(fontSize: 10));
                        }
                        return Text('₹${value.toInt()}', style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < months.length) {
                          String month = months[index];
                          DateTime date = DateTime.parse('$month-01');
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
                      return BarTooltipItem(
                        '₹${rod.toY.toInt()}',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quick Actions",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.9,
          children: [
            _QuickActionCard(
              icon: Icons.person_add,
              label: "Add Student",
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentManagementPage(schoolId: AppConfig.schoolId),
                  ),
                );
              },
            ),
            _QuickActionCard(
              icon: Icons.school,
              label: "Add Teacher",
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TeacherManagementPage(schoolId: AppConfig.schoolId),
                  ),
                );
              },
            ),
            _QuickActionCard(
              icon: Icons.analytics,
              label: "Analytics",
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminAnalyticsPage(schoolId: AppConfig.schoolId),
                  ),
                );
              },
            ),
            _QuickActionCard(
              icon: Icons.currency_rupee,
              label: "Upload Fees",
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminFeeUploadPage(schoolId: AppConfig.schoolId),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 120,
            decoration: const BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.admin_panel_settings, size: 35, color: Colors.blue),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Admin Panel",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          _drawerItem(context, Icons.dashboard, "Dashboard", null, isDashboard: true),
          const Divider(),
          _drawerItem(context, Icons.school, "Teachers",
              TeacherManagementPage(schoolId: AppConfig.schoolId)),
          _drawerItem(context, Icons.groups, "Students",
              StudentManagementPage(schoolId: AppConfig.schoolId)),
          _drawerItem(context, Icons.add_box, "Create Class",
              CreateClassPage(schoolId: AppConfig.schoolId)),
          _drawerItem(context, Icons.class_, "Manage Classes",
              ClassManagementPage(schoolId: AppConfig.schoolId)),
          const Divider(),
          _drawerItem(context, Icons.fact_check, "Attendance Overview",
              AdminAttendanceOverviewPage(schoolId: AppConfig.schoolId)),
          _drawerItem(context, Icons.bar_chart, "Attendance Reports",
              SelectClassForAttendancePage(schoolId: AppConfig.schoolId)),
          const Divider(),
          _drawerItem(context, Icons.currency_rupee, "Upload Fees",
              AdminFeeUploadPage(schoolId: AppConfig.schoolId)),
          _drawerItem(context, FontAwesomeIcons.bookOpen, "Exam Management",
              ExamManagementPage(schoolId: AppConfig.schoolId)),
          _drawerItem(context, Icons.analytics, "Analytics",
              AdminAnalyticsPage(schoolId: AppConfig.schoolId)),
          const Divider(),
          _drawerItem(context, Icons.person, "Profile", const ProfilePage()),
          _drawerItem(context, Icons.settings, "Settings", const SettingsPage()),
          _drawerItem(context, Icons.business, "School Settings",
              SchoolSettingsPage(schoolId: AppConfig.schoolId)),
        ],
      ),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String title, Widget? page, {bool isDashboard = false}) {
    return ListTile(
      leading: Icon(icon, color: isDashboard ? Colors.blue : Colors.blueGrey),
      title: Text(title, style: TextStyle(fontWeight: isDashboard ? FontWeight.bold : FontWeight.normal)),
      tileColor: isDashboard ? Colors.blue.shade50 : null,
      onTap: () {
        Navigator.pop(context);
        if (page != null && !isDashboard) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        }
      },
    );
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

// ================= HELPER WIDGETS =================

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OverviewItem extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _OverviewItem({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
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
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.blue : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade700,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}