import 'package:flutter/material.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
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
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.black),
                onPressed: () {},
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  height: 8,
                  width: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            ],
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TEACHER NAME + DATE
            const Text(
              "Prof. Anderson",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Friday, January 2, 2026",
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
              children: const [
                _ActionCard(
                  title: "Mark Attendance",
                  icon: Icons.fact_check,
                  color: Colors.purple,
                ),
                _ActionCard(
                  title: "Post Homework",
                  icon: Icons.menu_book,
                  color: Colors.green,
                ),
                _ActionCard(
                  title: "View Timetable",
                  icon: Icons.calendar_month,
                  color: Colors.orange,
                ),
                _ActionCard(
                  title: "Announcements",
                  icon: Icons.notifications,
                  color: Colors.blue,
                ),
              ],
            ),

            const SizedBox(height: 24),

            /// TODAY SCHEDULE
            const Text(
              "Today's Schedule",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            _scheduleTile(
              time: "08:00",
              subject: "Mathematics",
              className: "Grade 10-A",
              room: "Room 201",
            ),
            _scheduleTile(
              time: "09:00",
              subject: "Mathematics",
              className: "Grade 10-B",
              room: "Room 201",
            ),
            _scheduleTile(
              time: "11:00",
              subject: "Algebra",
              className: "Grade 9-A",
              room: "Room 105",
            ),
          ],
        ),
      ),
    );
  }

  /// SCHEDULE TILE
  Widget _scheduleTile({
    required String time,
    required String subject,
    required String className,
    required String room,
  }) {
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

/// ACTION CARD
class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}