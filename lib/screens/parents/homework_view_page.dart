import 'package:flutter/material.dart';

class HomeworkViewPage extends StatelessWidget {
  const HomeworkViewPage({super.key});

  // Temporary data (later from Firebase)
  final List<Map<String, dynamic>> homeworkList = const [
    {
      "subject": "Mathematics",
      "description": "Complete exercise 5.2 – Page 45",
      "dueDate": "20 Sep 2026",
      "status": "Pending",
    },
    {
      "subject": "Science",
      "description": "Draw and label the human heart diagram",
      "dueDate": "18 Sep 2026",
      "status": "Completed",
    },
    {
      "subject": "English",
      "description": "Write a paragraph on My School",
      "dueDate": "17 Sep 2026",
      "status": "Overdue",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text("Homework"),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: homeworkList.length,
        itemBuilder: (context, index) {
          final hw = homeworkList[index];
          return _HomeworkCard(
            subject: hw["subject"],
            description: hw["description"],
            dueDate: hw["dueDate"],
            status: hw["status"],
          );
        },
      ),
    );
  }
}

/* =========================================================
   HOMEWORK CARD
   ========================================================= */

class _HomeworkCard extends StatelessWidget {
  final String subject;
  final String description;
  final String dueDate;
  final String status;

  const _HomeworkCard({
    required this.subject,
    required this.description,
    required this.dueDate,
    required this.status,
  });

  Color getStatusColor() {
    switch (status) {
      case "Completed":
        return Colors.green;
      case "Overdue":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// SUBJECT + STATUS
            Row(
              children: [
                Text(
                  subject,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: getStatusColor().withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      color: getStatusColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            /// DESCRIPTION
            Text(
              description,
              style: const TextStyle(color: Colors.black87),
            ),

            const SizedBox(height: 10),

            /// DUE DATE
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14),
                const SizedBox(width: 6),
                Text(
                  "Due: $dueDate",
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}