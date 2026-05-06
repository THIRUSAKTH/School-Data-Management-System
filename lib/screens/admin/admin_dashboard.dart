import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:schoolprojectjan/app_config.dart';
import 'package:schoolprojectjan/screens/admin/admin_academic_year_page.dart';
import 'package:schoolprojectjan/screens/admin/admin_complaints_page.dart';
import 'package:schoolprojectjan/screens/admin/admin_create_timetable_page.dart';
import 'package:schoolprojectjan/screens/admin/exam_management_page.dart';
import 'package:schoolprojectjan/screens/admin/admin_notice_post_page.dart';
import 'package:schoolprojectjan/screens/admin/school_settings_page.dart';
import 'package:schoolprojectjan/screens/admin/select_class_for_attendance_page.dart';
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
  String _selectedPeriod = "week";
  Map<String, dynamic> _cachedChartData = {};
  DateTime _lastFetchTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchChartData();
  }

  void _logout(BuildContext context) async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchChartData() async {
    if (DateTime.now().difference(_lastFetchTime).inMinutes < 5 &&
        _cachedChartData.isNotEmpty) {
      return;
    }

    setState(() {
      _lastFetchTime = DateTime.now();
    });

    try {
      final attendanceSnapshot =
      await FirebaseFirestore.instance.collectionGroup('records').get();

      final feeSnapshot =
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('student_fees')
          .get();

      Map<String, int> dailyAttendance = {};
      int totalPresent = 0;
      int totalAbsent = 0;

      for (var doc in attendanceSnapshot.docs) {
        final data = doc.data();
        final parentDoc = doc.reference.parent.parent;
        final date = parentDoc?.id ?? '';
        final status = data['status'] as String?;

        if (date.isNotEmpty && status != null) {
          if (status == 'Present') {
            totalPresent++;
            dailyAttendance[date] = (dailyAttendance[date] ?? 0) + 1;
          } else if (status == 'Absent') {
            totalAbsent++;
          }
        }
      }

      double totalCollected = 0;
      double totalPending = 0;
      Map<String, double> monthlyFee = {};

      for (var doc in feeSnapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0;
        final status = data['status'] as String?;
        final dueDate = data['dueDate'] as Timestamp?;

        if (dueDate != null) {
          final month = DateFormat('yyyy-MM').format(dueDate.toDate());
          if (status == 'paid') {
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
          'totalCollected': totalCollected,
          'totalPending': totalPending,
          'monthlyFee': monthlyFee,
          'attendanceRate':
          totalPresent + totalAbsent > 0
              ? (totalPresent / (totalPresent + totalAbsent)) * 100
              : 0,
        };
      });
    } catch (e) {
      debugPrint('Error fetching chart data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      drawer: _buildDrawer(context),
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _fetchChartData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsGrid(),
              const SizedBox(height: 20),
              _buildTodayOverview(),
              const SizedBox(height: 20),
              _buildPeriodSelector(),
              const SizedBox(height: 16),
              _buildAttendanceChart(),
              const SizedBox(height: 20),
              _buildFeeChart(),
              const SizedBox(height: 20),
              _buildQuickActions(),
              const SizedBox(height: 80),
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
        stream:
        FirebaseFirestore.instance
            .collection('schools')
            .doc(AppConfig.schoolId)
            .snapshots(),
        builder: (context, snapshot) {
          String schoolName = "Smart School";
          if (snapshot.hasData && snapshot.data!.exists) {
            schoolName = snapshot.data!['schoolName'] ?? "Smart School";
          }
          return Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: Icon(Icons.school, size: 22, color: Colors.blue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  schoolName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _fetchChartData,
          tooltip: "Refresh",
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => _logout(context),
          tooltip: "Logout",
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
      childAspectRatio: 1.1,
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
          "Fees Collected",
          Icons.currency_rupee,
          Colors.green,
          null,
          customValue: _cachedChartData['totalCollected']?.toInt() ?? 0,
          isCurrency: true,
        ),
        _buildLiveCard(
          "Attendance Rate",
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
      future:
      FirebaseFirestore.instance
          .collectionGroup('records')
          .where(
        'date',
        isEqualTo: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      )
          .get(),
      builder: (context, snapshot) {
        int presentToday = 0;
        int absentToday = 0;
        int lateToday = 0;

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? '';
            if (status == 'Present') {
              presentToday++;
            } else if (status == 'Late') {
              lateToday++;
            } else if (status == 'Absent') {
              absentToday++;
            }
          }
        }

        final total = presentToday + absentToday + lateToday;
        final rate = total > 0 ? (presentToday / total) * 100 : 0;

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
                  if (lateToday > 0)
                    _OverviewItem(
                      title: "Late",
                      value: lateToday.toString(),
                      color: Colors.orange,
                      icon: Icons.access_time,
                    ),
                  _OverviewItem(
                    title: "Absent",
                    value: absentToday.toString(),
                    color: Colors.red,
                    icon: Icons.cancel,
                  ),
                  _OverviewItem(
                    title: "Rate",
                    value: "${rate.toStringAsFixed(1)}%",
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
      padding: const EdgeInsets.all(8),
      decoration: _cardDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _PeriodChip(
            label: "Week",
            value: "week",
            selected: _selectedPeriod == "week",
            onTap: () => setState(() => _selectedPeriod = "week"),
          ),
          _PeriodChip(
            label: "Month",
            value: "month",
            selected: _selectedPeriod == "month",
            onTap: () => setState(() => _selectedPeriod = "month"),
          ),
          _PeriodChip(
            label: "Year",
            value: "year",
            selected: _selectedPeriod == "year",
            onTap: () => setState(() => _selectedPeriod = "year"),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceChart() {
    final dailyData = _cachedChartData['dailyAttendance'] ?? {};
    List<FlSpot> spots = [];
    List<String> last7Days = [];

    for (int i = 6; i >= 0; i--) {
      final date = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.now().subtract(Duration(days: i)));
      last7Days.add(date);
      spots.add(FlSpot(i.toDouble(), (dailyData[date] ?? 0).toDouble()));
    }

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
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget:
                          (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
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
                            style: const TextStyle(fontSize: 10),
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
                borderData: FlBorderData(show: true),
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

    List<String> months = [];
    for (var key in monthlyFee.keys) {
      months.add(key.toString());
    }
    months.sort();

    if (months.isEmpty) {
      for (int i = 5; i >= 0; i--) {
        months.add(
          DateFormat(
            'yyyy-MM',
          ).format(DateTime.now().subtract(Duration(days: 30 * i))),
        );
      }
    }

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
    double interval = maxY / 5;
    if (interval == 0) interval = 10000;

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
            height: 200,
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
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        if (value >= 1000) {
                          return Text(
                            '₹${(value / 1000).toInt()}k',
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return Text(
                          '₹${value.toInt()}',
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
                        if (index >= 0 && index < months.length) {
                          String month = months[index];
                          DateTime date = DateTime.parse('$month-01');
                          return Text(
                            DateFormat('MMM').format(date),
                            style: const TextStyle(fontSize: 10),
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
                      return BarTooltipItem(
                        '₹${rod.toY.toInt()}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
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
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _QuickActionCard(
              icon: Icons.person_add,
              label: "Add Student",
              color: Colors.blue,
              onTap:
                  () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => StudentManagementPage(
                    schoolId: AppConfig.schoolId,
                  ),
                ),
              ),
            ),
            _QuickActionCard(
              icon: Icons.school,
              label: "Add Teacher",
              color: Colors.purple,
              onTap:
                  () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => TeacherManagementPage(
                    schoolId: AppConfig.schoolId,
                  ),
                ),
              ),
            ),
            _QuickActionCard(
              icon: Icons.currency_rupee,
              label: "Upload Fees",
              color: Colors.green,
              onTap:
                  () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) =>
                      AdminFeeUploadPage(schoolId: AppConfig.schoolId),
                ),
              ),
            ),
            _QuickActionCard(
              icon: Icons.analytics,
              label: "Analytics",
              color: Colors.orange,
              onTap:
                  () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) =>
                      AdminAnalyticsPage(schoolId: AppConfig.schoolId),
                ),
              ),
            ),
            // NEW: Academic Year Management
            _QuickActionCard(
              icon: Icons.calendar_today,
              label: "Academic Year",
              color: Colors.teal,
              onTap:
                  () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminAcademicYearPage(),
                ),
              ),
            ),
            // NEW: Create Timetable
            _QuickActionCard(
              icon: Icons.schedule,
              label: "Timetable",
              color: Colors.cyan,
              onTap:
                  () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => AdminCreateTimetablePage(
                    schoolId: AppConfig.schoolId,
                  ),
                ),
              ),
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
            height: 140,
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
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.admin_panel_settings,
                      size: 40,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Admin Panel",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _drawerItem(
            context,
            Icons.dashboard,
            "Dashboard",
            null,
            isDashboard: true,
          ),
          const Divider(),
          _drawerItem(
            context,
            Icons.add_box,
            "Create Class",
            CreateClassPage(schoolId: AppConfig.schoolId),
          ),
          _drawerItem(
            context,
            Icons.class_,
            "Manage Classes",
            ClassManagementPage(schoolId: AppConfig.schoolId),
          ),
          _drawerItem(
            context,
            Icons.school,
            "Teachers",
            TeacherManagementPage(schoolId: AppConfig.schoolId),
          ),
          _drawerItem(
            context,
            Icons.people,
            "Students",
            StudentManagementPage(schoolId: AppConfig.schoolId),
          ),
          const Divider(),
          _drawerItem(
            context,
            Icons.fact_check,
            "Attendance Overview",
            AdminAttendanceOverviewPage(schoolId: AppConfig.schoolId),
          ),
          _drawerItem(
            context,
            Icons.bar_chart,
            "Attendance Reports",
            SelectClassForAttendancePage(schoolId: AppConfig.schoolId),
          ),
          _drawerItem(
            context,
            Icons.announcement,
            "Upload Notice",
            const AdminNoticePostPage(),
          ),
          _drawerItem(
            context,
            Icons.feedback,
            "Complaints",
            const AdminComplaintsPage(),
          ),
          const Divider(),
          _drawerItem(
            context,
            Icons.currency_rupee,
            "Upload Fees",
            AdminFeeUploadPage(schoolId: AppConfig.schoolId),
          ),
          _drawerItem(
            context,
            FontAwesomeIcons.bookOpen,
            "Exam Management",
            ExamManagementPage(schoolId: AppConfig.schoolId),
          ),
          _drawerItem(
            context,
            Icons.analytics,
            "Analytics",
            AdminAnalyticsPage(schoolId: AppConfig.schoolId),
          ),
          const Divider(),
          _drawerItem(
            context,
            Icons.business,
            "School Settings",
            SchoolSettingsPage(schoolId: AppConfig.schoolId),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(
      BuildContext context,
      IconData icon,
      String title,
      Widget? page, {
        bool isDashboard = false,
      }) {
    return ListTile(
      leading: Icon(icon, color: isDashboard ? Colors.blue : Colors.blueGrey),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isDashboard ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: isDashboard ? Colors.blue.withValues(alpha: 0.1) : null,
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

// Helper Widgets
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
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
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
            fontSize: 13,
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
            Icon(icon, color: color, size: 28),
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