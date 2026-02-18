import 'package:flutter/material.dart';
import 'select_class_attendance_page.dart';

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
          "Welcome back,",
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
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
              "Prof. Anderson",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              today,
              style: TextStyle(color: Colors.grey.shade600),
            ),

            const SizedBox(height: 20),

            /// ACTION GRID
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
                          schoolId: schoolId,
                        ),
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
                  title: "View Timetable",
                  icon: Icons.calendar_month,
                  color: Colors.orange,
                  onTap: () {},
                ),
                _ActionCard(
                  title: "Announcements",
                  icon: Icons.notifications,
                  color: Colors.blue,
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              "Today's Schedule",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _scheduleTile("08:00", "Mathematics", "10-A", "Room 201"),
            _scheduleTile("09:00", "Mathematics", "10-B", "Room 201"),
            _scheduleTile("11:00", "Algebra", "9-A", "Room 105"),
          ],
        ),
      ),
    );
  }

  Widget _scheduleTile(
      String time, String subject, String className, String room) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              time,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ),
        ),
        title: Text(subject, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text("$className • $room"),
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
