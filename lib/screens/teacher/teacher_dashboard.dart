import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:schoolprojectjan/app_config.dart';
import 'package:schoolprojectjan/screens/teacher/teacher_exam_schedule.dart';
import 'package:schoolprojectjan/screens/teacher/teacher_notice_view_page.dart';
import 'package:schoolprojectjan/screens/teacher/teacher_upload_marks.dart';
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
  List<Map<String, dynamic>> _assignedClasses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
    _loadTodaySchedule();
  }

  Future<void> _loadTeacherData() async {
    setState(() => _isLoading = true);

    try {
      final teacherUid = FirebaseAuth.instance.currentUser!.uid;
      final teacherDoc =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('teachers')
              .where('uid', isEqualTo: teacherUid)
              .limit(1)
              .get();

      if (teacherDoc.docs.isNotEmpty) {
        final data = teacherDoc.docs.first.data();
        setState(() {
          _teacherName = data['name'] ?? "Teacher";
          _assignedClasses = List<Map<String, dynamic>>.from(
            data['assignedClasses'] ?? [],
          );
        });

        int totalStudents = 0;
        for (var classInfo in _assignedClasses) {
          final studentsSnapshot =
              await FirebaseFirestore.instance
                  .collection('schools')
                  .doc(AppConfig.schoolId)
                  .collection('students')
                  .where('class', isEqualTo: classInfo['className'])
                  .where('section', isEqualTo: classInfo['section'])
                  .get();
          totalStudents += studentsSnapshot.docs.length;
        }

        setState(() {
          _totalStudents = totalStudents;
        });
      }
    } catch (e) {
      debugPrint('Error loading teacher: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadTodaySchedule() async {
    try {
      final teacherUid = FirebaseAuth.instance.currentUser!.uid;
      final today = DateFormat('EEEE').format(DateTime.now()).toLowerCase();

      final scheduleSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('timetable')
              .where('teacherId', isEqualTo: teacherUid)
              .where('day', isEqualTo: today)
              .get();

      if (scheduleSnapshot.docs.isNotEmpty) {
        final List<Map<String, dynamic>> schedule = [];
        for (var doc in scheduleSnapshot.docs) {
          final data = doc.data();
          schedule.add({
            'time': data['period']?.toString() ?? '',
            'subject': data['subject'] ?? '',
            'class': "${data['className'] ?? ''} - ${data['section'] ?? ''}",
          });
        }
        setState(() {
          _todaySchedule = schedule;
          _todayClasses = schedule.length;
        });
      } else {
        setState(() {
          _todaySchedule = [];
          _todayClasses = 0;
        });
      }
    } catch (e) {
      debugPrint('Error loading schedule: $e');
      setState(() {
        _todaySchedule = [];
        _todayClasses = 0;
      });
    }
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 30),
                    _buildHeaderCard(today),
                    const SizedBox(height: 20),
                    _buildQuickStatsRow(),
                    const SizedBox(height: 20),
                    _buildActionGrid(),
                    const SizedBox(height: 24),
                    _buildTodaySchedule(),
                  ],
                ),
      ),
    );
  }

  Widget _buildHeaderCard(String today) {
    return Container(
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
            color: Colors.green.withOpacity(0.3),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome, ${_teacherName ?? 'Teacher'}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      today,
                      style: const TextStyle(color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
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
          Wrap(
            spacing: 20,
            runSpacing: 10,
            alignment: WrapAlignment.spaceAround,
            children: [
              _headerStat(
                Icons.class_,
                "Today's Classes",
                _todayClasses.toString(),
              ),
              _headerStat(
                Icons.people,
                "My Students",
                _totalStudents.toString(),
              ),
              _headerStat(
                Icons.assignment,
                "Classes",
                _assignedClasses.length.toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStat(IconData icon, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(height: 4),
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

  Widget _buildQuickStatsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _quickStat(Icons.check_circle, "Attendance", Colors.green, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) =>
                        SelectClassAttendancePage(schoolId: AppConfig.schoolId),
              ),
            );
          }),
          const SizedBox(width: 12),
          _quickStat(Icons.bar_chart, "Reports", Colors.indigo, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => AttendanceReportPage(schoolId: AppConfig.schoolId),
              ),
            );
          }),
          const SizedBox(width: 12),
          _quickStat(Icons.calendar_month, "Exam Schedule", Colors.purple, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TeacherExamSchedulePage(),
              ),
            );
          }),
          const SizedBox(width: 12),
          _quickStat(Icons.notifications, "Notices", Colors.orange, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TeacherNoticeViewPage()),
            );
          }),
        ],
      ),
    );
  }

  Widget _quickStat(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _ActionCard(
          title: "Mark Attendance",
          icon: Icons.fact_check,
          color: Colors.purple,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) =>
                        SelectClassAttendancePage(schoolId: AppConfig.schoolId),
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
                builder:
                    (_) => AttendanceReportPage(schoolId: AppConfig.schoolId),
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
              MaterialPageRoute(builder: (_) => const HomeworkPostPage()),
            );
          },
        ),
        _ActionCard(
          title: "Upload Marks",
          icon: Icons.assignment_turned_in,
          color: Colors.teal,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TeacherUploadMarksPage()),
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
              MaterialPageRoute(builder: (_) => const TeacherNoticeViewPage()),
            );
          },
        ),
        _ActionCard(
          title: "Exam Schedule",
          icon: Icons.calendar_month,
          color: Colors.deepPurple,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TeacherExamSchedulePage(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTodaySchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            child: const Center(child: Text("No classes scheduled for today")),
          )
        else
          ..._todaySchedule.map(
            (classItem) => _scheduleTile(
              classItem['time'],
              classItem['subject'],
              classItem['class'],
            ),
          ),
      ],
    );
  }

  Widget _scheduleTile(String time, String subject, String className) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: Colors.green.shade100,
          child: Text(
            time.isEmpty
                ? "P"
                : (time.length > 2 ? time.substring(0, 2) : time),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
        ),
        title: Text(
          subject,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          className,
          style: const TextStyle(fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.access_time, size: 14, color: Colors.grey),
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
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
