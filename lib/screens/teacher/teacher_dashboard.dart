import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:schoolprojectjan/app_config.dart';
import 'package:schoolprojectjan/screens/admin/notice_post_page.dart';
import 'select_class_attendance_page.dart';
import 'attendance_report_page.dart';
import 'homework_post_page.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  String? _teacherName;
  int _todayClasses = 0;
  int _totalStudents = 0;
  List<Map<String, dynamic>> _todaySchedule = [];

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
    _loadTodaySchedule();
  }

  Future<void> _loadTeacherData() async {
    try {
      final teacherUid = FirebaseAuth.instance.currentUser!.uid;
      final teacherDoc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('teachers')
          .where('uid', isEqualTo: teacherUid)
          .limit(1)
          .get();

      if (teacherDoc.docs.isNotEmpty) {
        setState(() {
          _teacherName = teacherDoc.docs.first['name'] ?? "Teacher";
        });
      }
    } catch (e) {
      debugPrint('Error loading teacher: $e');
    }
  }

  Future<void> _loadTodaySchedule() async {
    // Demo schedule - in production, load from Firestore
    setState(() {
      _todaySchedule = [
        {'time': '08:00 AM', 'subject': 'Mathematics', 'class': 'Class 10-A'},
        {'time': '09:00 AM', 'subject': 'Mathematics', 'class': 'Class 10-B'},
        {'time': '11:00 AM', 'subject': 'Algebra', 'class': 'Class 9-A'},
      ];
      _todayClasses = _todaySchedule.length;
      _totalStudents = 45; // Demo count
    });
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                      (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now());

    return RefreshIndicator(
      onRefresh: () async {
        await _loadTeacherData();
        await _loadTodaySchedule();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header Card with Logout
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.green, Colors.teal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome, ${_teacherName ?? 'Teacher'}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            today,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          onPressed: () => _logout(context),
                          tooltip: "Logout",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _headerStat(Icons.class_, "Today's Classes", _todayClasses.toString()),
                      _headerStat(Icons.people, "My Students", _totalStudents.toString()),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// Quick Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _quickStat(Icons.check_circle, "Attendance", Colors.green),
                _quickStat(Icons.bar_chart, "Reports", Colors.indigo),
                _quickStat(Icons.notifications, "Notices", Colors.orange),
              ],
            ),

            const SizedBox(height: 20),

            /// Action Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _ActionCard(
                  title: "Mark Attendance",
                  icon: Icons.fact_check,
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SelectClassAttendancePage(
                          schoolId: AppConfig.schoolId,
                        ),
                      ),
                    );
                  },
                ),
                _ActionCard(
                  title: "Attendance Report",
                  icon: Icons.bar_chart,
                  color: Colors.indigo,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AttendanceReportPage(
                          schoolId: AppConfig.schoolId,
                        ),
                      ),
                    );
                  },
                ),
                _ActionCard(
                  title: "Post Homework",
                  icon: Icons.menu_book,
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HomeworkPostPage(),
                      ),
                    );
                  },
                ),
                _ActionCard(
                  title: "View Notices",
                  icon: Icons.notifications_active,
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NoticePostPage(),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            /// Today's Schedule
            const Text(
              "Today's Schedule",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (_todaySchedule.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text("No classes scheduled for today"),
                ),
              )
            else
              ..._todaySchedule.map((classItem) => _scheduleTile(
                classItem['time'],
                classItem['subject'],
                classItem['class'],
              )),
          ],
        ),
      ),
    );
  }

  Widget _headerStat(IconData icon, String label, String value) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _quickStat(IconData icon, String label, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _scheduleTile(String time, String subject, String className) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: Text(
            time.replaceAll(' AM', '').replaceAll(' PM', ''),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
        ),
        title: Text(
          subject,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(className),
        trailing: const Icon(Icons.access_time, size: 16, color: Colors.grey),
      ),
    );
  }
}

/// Action Card Widget
class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}