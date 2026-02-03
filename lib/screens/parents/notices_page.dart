import 'package:flutter/material.dart';

class NoticesPage extends StatelessWidget {
  const NoticesPage({super.key});

  // Mock notices (later from Firebase)
  List<Map<String, dynamic>> get notices => [
    {
      "title": "Holiday Announcement",
      "message": "School will remain closed on Friday.",
      "priority": "Normal",
      "date": "2026-01-05",
    },
    {
      "title": "Exam Schedule",
      "message": "Mid-term exams start from Jan 15.",
      "priority": "Important",
      "date": "2026-01-03",
    },
    {
      "title": "Emergency Meeting",
      "message": "Parents must attend meeting tomorrow.",
      "priority": "Urgent",
      "date": "2026-01-02",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text("Notices"),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notices.length,
        itemBuilder: (_, index) {
          final notice = notices[index];
          return _noticeCard(notice);
        },
      ),
    );
  }

  Widget _noticeCard(Map<String, dynamic> notice) {
    final Color color = notice["priority"] == "Urgent"
        ? Colors.red
        : notice["priority"] == "Important"
        ? Colors.orange
        : Colors.blue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    notice["priority"],
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  notice["date"],
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              notice["title"],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              notice["message"],
              style: const TextStyle(color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}