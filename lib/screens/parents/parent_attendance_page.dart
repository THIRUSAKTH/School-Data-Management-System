import 'package:flutter/material.dart';

class ParentAttendancePage extends StatelessWidget {
  const ParentAttendancePage({super.key});

  static const attendanceList = [
    {"date": "01 Jan 2026", "status": "present"},
    {"date": "02 Jan 2026", "status": "absent"},
    {"date": "03 Jan 2026", "status": "present"},
    {"date": "04 Jan 2026", "status": "present"},
  ];

  @override
  Widget build(BuildContext context) {
    final total = attendanceList.length;
    final present =
        attendanceList.where((e) => e["status"] == "present").length;
    final percent = ((present / total) * 100).round();

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                _summaryCard(percent),
                const SizedBox(height: 24),
                const Text(
                  "Daily Attendance",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...attendanceList.map(_attendanceTile).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// ✅ NO Column + Spacer
  Widget _summaryCard(int percent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.deepPurple,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 16),

          /// Student info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // 🔥 VERY IMPORTANT
            children: const [
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

          const SizedBox(width: 16),

          /// Percentage (NO Spacer)
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "$percent%",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: percent >= 75 ? Colors.green : Colors.red,
                    ),
                  ),
                  const Text(
                    "Attendance",
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _attendanceTile(Map<String, dynamic> data) {
    final isPresent = data["status"] == "present";

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPresent ? Colors.green : Colors.red,
          child: Icon(
            isPresent ? Icons.check : Icons.close,
            color: Colors.white,
          ),
        ),
        title: Text(data["date"]),
        trailing: Text(
          isPresent ? "Present" : "Absent",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isPresent ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }
}