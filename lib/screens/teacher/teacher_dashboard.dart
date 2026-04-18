import 'package:flutter/material.dart';
import 'package:schoolprojectjan/app_config.dart';

import 'select_class_attendance_page.dart';
import 'attendance_report_page.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {

    final today =
        "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// 🔥 HEADER CARD
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.green, Colors.teal],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Welcome Teacher",
                  style: TextStyle(
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
          ),

          const SizedBox(height: 20),

          /// 🔥 QUICK ACTIONS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _quickAction(Icons.check_circle, "Attendance"),
              _quickAction(Icons.bar_chart, "Reports"),
              _quickAction(Icons.notifications, "Notices"),
            ],
          ),

          const SizedBox(height: 20),

          /// 🔥 ACTION GRID
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Coming Soon")),
                  );
                },
              ),

              _ActionCard(
                title: "Announcements",
                icon: Icons.notifications,
                color: Colors.orange,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Coming Soon")),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          /// 🔥 TODAY CLASSES
          const Text(
            "Today's Classes",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          _scheduleTile("08:00", "Math", "Class 10-A"),
          _scheduleTile("09:00", "Math", "Class 10-B"),
          _scheduleTile("11:00", "Algebra", "Class 9-A"),
        ],
      ),
    );
  }

  /// 🔹 QUICK ACTION UI
  Widget _quickAction(IconData icon, String title) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  /// 🔹 CLASS TILE
  Widget _scheduleTile(String time, String subject, String className) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple.withValues(alpha: 0.1),
          child: Text(time, style: const TextStyle(fontSize: 12)),
        ),
        title: Text(subject,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(className),
      ),
    );
  }
}

/// 🔹 ACTION CARD
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