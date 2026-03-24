import 'package:flutter/material.dart';

class AdminAttendanceOverviewPage extends StatelessWidget {
  const AdminAttendanceOverviewPage({super.key});

  // Mock data (later from Firebase)
  Map<String, dynamic> get overview => {
    "totalStudents": 520,
    "present": 489,
    "absent": 31,
  };

  final List<Map<String, dynamic>> classWiseAttendance = const [
    {"class": "6-A", "present": 28, "total": 30},
    {"class": "6-B", "present": 27, "total": 30},
    {"class": "7-A", "present": 29, "total": 32},
    {"class": "7-B", "present": 30, "total": 31},
    {"class": "8-A", "present": 26, "total": 29},
  ];

  @override
  Widget build(BuildContext context) {
    final percentage =
    ((overview["present"] / overview["totalStudents"]) * 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text("Attendance Overview"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TOP SUMMARY
            _summaryCard(percentage),

            const SizedBox(height: 24),

            const Text(
              "Class-wise Attendance",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12.1),

            /// CLASS LIST
            ...classWiseAttendance.map(_classAttendanceTile).toList(),
          ],
        ),
      ),
    );
  }

  /* =========================================================
     SUMMARY CARD
     ========================================================= */

  Widget _summaryCard(int percentage) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

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
          child: isWide
              ? Row(children: _summaryChildren(percentage))
              : Column(children: _summaryChildren(percentage)),
        );
      },
    );
  }

  List<Widget> _summaryChildren(int percentage) => [
    _summaryItem(
      "Total Students",
      overview["totalStudents"].toString(),
      Icons.groups,
      Colors.blue,
    ),
    _summaryItem(
      "Present",
      overview["present"].toString(),
      Icons.check_circle,
      Colors.green,
    ),
    _summaryItem(
      "Absent",
      overview["absent"].toString(),
      Icons.cancel,
      Colors.red,
    ),

    const SizedBox(height: 16), // ✅ instead of Spacer

    Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            "$percentage%",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: percentage >= 75 ? Colors.green : Colors.red,
            ),
          ),
          const Text("Today"),
        ],
      ),
    ),
  ];

  Widget _summaryItem(
      String title, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 20, bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Text(title, style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }

  /* =========================================================
     CLASS TILE
     ========================================================= */

  Widget _classAttendanceTile(Map<String, dynamic> data) {
    final percent = ((data["present"] / data["total"]) * 100).round();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.class_),
        title: Text("Class ${data["class"]}"),
        subtitle: Text(
            "Present: ${data["present"]} / ${data["total"]}"),
        trailing: Text(
          "$percent%",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: percent >= 75 ? Colors.green : Colors.red,
          ),
        ),
        onTap: () {
          // Later: open student-wise attendance
          debugPrint("Open attendance for ${data["class"]}");
        },
      ),
    );
  }
}
