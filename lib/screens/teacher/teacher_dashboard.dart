import 'package:flutter/material.dart';
import 'select_class_attendance_page.dart';
import 'attendance_report_page.dart'; // you will create next

class TeacherDashboard extends StatelessWidget {
  final String schoolId;

  const TeacherDashboard({
    super.key,
    required this.schoolId,
  });

  @override
  Widget build(BuildContext context) {
    final today =
        "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Teacher Dashboard",
          style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold),
        ),centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {},
          )
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome Teacher 👋",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(today, style: TextStyle(color: Colors.grey.shade600)),

            const SizedBox(height: 22),

            /// ===== ACTION GRID =====
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.15,
              ),
              children: [
                _ActionCard(
                  title: "Mark Attendance",
                  icon: Icons.fact_check,
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SelectClassAttendancePage(schoolId: schoolId),
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
                        builder: (_) =>
                            AttendanceReportPage(schoolId: schoolId),
                      ),
                    );
                  },
                ),

                _ActionCard(
                  title: "Post Homework",
                  icon: Icons.menu_book,
                  color: Colors.green,
                  onTap: () {},
                ),

                _ActionCard(
                  title: "Announcements",
                  icon: Icons.notifications,
                  color: Colors.orange,
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 26),

            /// ===== SCHEDULE (OPTIONAL) =====
            const Text(
              "Today's Classes",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _scheduleTile("08:00", "Math", "10-A"),
            _scheduleTile("09:00", "Math", "10-B"),
            _scheduleTile("11:00", "Algebra", "9-A"),
          ],
        ),
      ),
    );
  }

  Widget _scheduleTile(String time, String subject, String className) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple.withOpacity(.15),
          child: Text(time,
              style: const TextStyle(fontSize: 12, color: Colors.deepPurple)),
        ),
        title: Text(subject, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text("Class $className"),
      ),
    );
  }
}

/// ================= ACTION CARD =================

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
              color: color.withOpacity(.3),
              blurRadius: 8,
              offset: const Offset(0, 5),
            )
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
