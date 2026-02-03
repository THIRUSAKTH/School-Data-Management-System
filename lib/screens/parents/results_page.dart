import 'package:flutter/material.dart';

class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key});

  // Mock result data (later from Firebase)
  List<Map<String, dynamic>> get subjects => [
    {"name": "Maths", "marks": 85},
    {"name": "Science", "marks": 88},
    {"name": "English", "marks": 78},
    {"name": "Social", "marks": 82},
    {"name": "Tamil", "marks": 90},
  ];

  @override
  Widget build(BuildContext context) {
    final total = subjects.fold<int>(0, (sum, s) => sum + s["marks"] as int);
    final percentage = (total / (subjects.length * 100) * 100).round();
    final passed = percentage >= 35;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text("Results"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// STUDENT INFO + SUMMARY
            _summaryCard(total, percentage, passed),

            const SizedBox(height: 24),

            const Text(
              "Subject-wise Marks",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            /// SUBJECT LIST
            ...subjects.map((s) => _subjectTile(s)).toList(),
          ],
        ),
      ),
    );
  }

  /* =========================================================
     SUMMARY CARD
     ========================================================= */

  Widget _summaryCard(int total, int percentage, bool passed) {
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
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: passed ? Colors.green : Colors.red,
            child: Icon(
              passed ? Icons.check_circle : Icons.cancel,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Student Name",
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Class 10 - A | Roll No: 12",
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 8),
                Text(
                  "Result: ${passed ? "PASS" : "FAIL"}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: passed ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                "$percentage%",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: passed ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Percentage",
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /* =========================================================
     SUBJECT TILE
     ========================================================= */

  Widget _subjectTile(Map<String, dynamic> subject) {
    final marks = subject["marks"] as int;
    final passed = marks >= 35;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: passed ? Colors.green : Colors.red,
          child: Text(
            marks.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          subject["name"],
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