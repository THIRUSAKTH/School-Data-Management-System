import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:schoolprojectjan/app_config.dart';
import 'package:schoolprojectjan/screens/teacher/teacher_exam_schedule.dart';
import 'package:schoolprojectjan/screens/teacher/teacher_notice_view_page.dart';
import 'package:schoolprojectjan/screens/teacher/teacher_upload_marks.dart';
import 'package:schoolprojectjan/screens/teacher/teacher_homework_dashboard.dart';
import 'select_class_attendance_page.dart';
import 'attendance_report_page.dart';
import 'teacher_homework_post_page.dart';

// ✅ NEW: Import leave pages
import 'teacher_leave_application.dart';
import 'teacher_leave_history.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  String? _teacherName;
  int _todayClasses = 0;
  int _totalStudents = 0;
  int _pendingSubmissions = 0;
  int _pendingLeaveRequests = 0; // ✅ NEW: For leave badge
  List<Map<String, dynamic>> _todaySchedule = [];
  List<Map<String, dynamic>> _assignedClasses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
    _loadTodaySchedule();
    _loadPendingSubmissions();
    _loadPendingLeaveRequests(); // ✅ NEW: Load pending leaves
  }

  // ✅ NEW: Load pending leave requests
  Future<void> _loadPendingLeaveRequests() async {
    try {
      final teacherUid = FirebaseAuth.instance.currentUser!.uid;

      final leaveSnapshot =
          await FirebaseFirestore.instance
              .collection('leave_requests')
              .where('teacherId', isEqualTo: teacherUid)
              .where('status', isEqualTo: 'pending')
              .get();

      setState(() {
        _pendingLeaveRequests = leaveSnapshot.docs.length;
      });
    } catch (e) {
      debugPrint('Error loading pending leaves: $e');
    }
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

  Future<void> _loadPendingSubmissions() async {
    try {
      final teacherUid = FirebaseAuth.instance.currentUser!.uid;

      final homeworkSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('homework')
              .where('teacherId', isEqualTo: teacherUid)
              .where('isActive', isEqualTo: true)
              .get();

      int pending = 0;

      for (var doc in homeworkSnapshot.docs) {
        final data = doc.data();
        final className = data['className'] ?? '';
        final section = data['section'] ?? '';

        final studentsSnapshot =
            await FirebaseFirestore.instance
                .collection('schools')
                .doc(AppConfig.schoolId)
                .collection('students')
                .where('class', isEqualTo: className)
                .where('section', isEqualTo: section)
                .get();

        final totalStudents = studentsSnapshot.docs.length;
        final submittedBy = List<String>.from(data['submittedBy'] ?? []);
        final pendingCount = totalStudents - submittedBy.length;
        pending += pendingCount;
      }

      setState(() {
        _pendingSubmissions = pending;
      });
    } catch (e) {
      debugPrint('Error loading pending submissions: $e');
    }
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

  void _navigateToHomeworkDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TeacherHomeworkDashboard()),
    ).then((_) {
      _loadPendingSubmissions();
    });
  }

  void _navigateToPostHomework() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TeacherHomeworkPostPage()),
    ).then((_) {
      _loadPendingSubmissions();
    });
  }

  // ✅ NEW: Navigate to Leave Application
  void _navigateToLeaveApplication() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TeacherLeaveApplication()),
    ).then((_) {
      _loadPendingLeaveRequests();
    });
  }

  // ✅ NEW: Navigate to Leave History
  void _navigateToLeaveHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TeacherLeaveHistory()),
    ).then((_) {
      _loadPendingLeaveRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now());

    return RefreshIndicator(
      onRefresh: () async {
        await _loadTeacherData();
        await _loadTodaySchedule();
        await _loadPendingSubmissions();
        await _loadPendingLeaveRequests();
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
                    const SizedBox(height: 30),
                    _buildHeaderCard(today),
                    const SizedBox(height: 20),
                    _buildQuickStatsRow(),
                    const SizedBox(height: 20),
                    _buildHomeworkSummaryCard(),
                    const SizedBox(height: 20),
                    _buildLeaveSummaryCard(), // ✅ NEW: Leave Summary Card
                    const SizedBox(height: 20),
                    _buildActionGrid(),
                    const SizedBox(height: 24),
                    _buildTodaySchedule(),
                  ],
                ),
      ),
    );
  }

  // ✅ NEW: Leave Summary Card
  Widget _buildLeaveSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.orange, Colors.deepOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.event_note,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Leave Management",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_pendingLeaveRequests > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${_pendingLeaveRequests} Pending",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _leaveStat(
                  Icons.add,
                  "Apply Leave",
                  Colors.white,
                  _navigateToLeaveApplication,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _leaveStat(
                  Icons.history,
                  "View History",
                  Colors.white,
                  _navigateToLeaveHistory,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _leaveStat(
                  Icons.pending_actions,
                  "Status",
                  Colors.white,
                  _navigateToLeaveHistory,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _leaveStat(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeworkSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.deepPurple, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Homework Management",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _pendingSubmissions > 0 ? Colors.red : Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _pendingSubmissions > 0
                      ? "${_pendingSubmissions} Pending"
                      : "All Submitted",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _homeworkStat(
                  Icons.assignment,
                  "Post Homework",
                  Colors.white,
                  _navigateToPostHomework,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _homeworkStat(
                  Icons.assignment_turned_in,
                  "View Submissions",
                  Colors.white,
                  _navigateToHomeworkDashboard,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _homeworkStat(
                  Icons.grade,
                  "Grade",
                  Colors.white,
                  _navigateToHomeworkDashboard,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _homeworkStat(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 10),
              textAlign: TextAlign.center,
            ),
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
              // ✅ NEW: Pending Leave Stat
              _headerStat(
                Icons.event_note,
                "Leave Requests",
                _pendingLeaveRequests.toString(),
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
          const SizedBox(width: 12),
          _quickStat(
            Icons.assignment,
            "Homework",
            Colors.deepPurple,
            _navigateToHomeworkDashboard,
          ),
          // ✅ NEW: Leave Quick Stat
          const SizedBox(width: 12),
          _quickStat(
            Icons.event_note,
            "Leave",
            Colors.orange,
            _navigateToLeaveApplication,
          ),
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
      crossAxisCount: 3,
      // ✅ Changed from 2 to 3
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
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
          onTap: _navigateToPostHomework,
        ),
        _ActionCard(
          title: "Homework Dashboard",
          icon: Icons.assignment,
          color: Colors.deepPurple,
          onTap: _navigateToHomeworkDashboard,
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
        // ✅ NEW: Apply for Leave Button
        _ActionCard(
          title: "Apply Leave",
          icon: Icons.event_note,
          color: Colors.orange,
          onTap: _navigateToLeaveApplication,
        ),
        // ✅ NEW: Leave History Button
        _ActionCard(
          title: "Leave History",
          icon: Icons.history,
          color: Colors.brown,
          onTap: _navigateToLeaveHistory,
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
