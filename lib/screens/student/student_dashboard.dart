import 'package:flutter/material.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text("Student Dashboard"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// STUDENT INFO
            _studentInfoCard(),

            const SizedBox(height: 24),

            /// QUICK STATS
            Row(
              children:[
                Expanded(
                  child: _StatCard(
                    title: "Attendance",
                    value: "95%",
                    icon: Icons.fact_check,
                    color: Colors.green,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: "Rank",
                    value: "5",
                    icon: Icons.emoji_events,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              "Subject Performance",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            _subjectCard("Maths", 82),
            _subjectCard("Science", 88),
            _subjectCard("English", 78),
            _subjectCard("Social", 85),
          ],
        ),
      ),
    );
  }

  /* =========================================================
     STUDENT INFO CARD
     ========================================================= */

  Widget _studentInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: const [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.deepPurple,
            child: Icon(Icons.person, color: Colors.white),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Student Name",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                "Class 10 - A | Roll No: 12",
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /* =========================================================
     STAT CARD
     ========================================================= */

  Widget _StatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  /* =========================================================
     SUBJECT CARD
     ========================================================= */

  Widget _subjectCard(String subject, int marks) {
    final passed = marks >= 35;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: passed ? Colors.green : Colors.red,
          child: Text(
            "$marks%",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          subject,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: Text(
          passed ? "PASS" : "FAIL",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: passed ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }
}