import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceDailyReportPage extends StatefulWidget {
  final String schoolId;

  const AttendanceDailyReportPage({
    super.key,
    required this.schoolId,
  });

  @override
  State<AttendanceDailyReportPage> createState() =>
      _AttendanceDailyReportPageState();
}

class _AttendanceDailyReportPageState
    extends State<AttendanceDailyReportPage> {
  String selectedClass = "10";
  String selectedSection = "A";

  String get today =>
      DateTime.now().toIso8601String().split("T")[0];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Attendance Report"),
        backgroundColor: Colors.indigo,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolId)
            .collection('attendance')
            .doc(today)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final data =
          snapshot.data!.data() as Map<String, dynamic>?;

          if (data == null) {
            return const Center(
                child: Text("No attendance recorded"));
          }

          final key =
              "class_${selectedClass}_${selectedSection}";

          if (!data.containsKey(key)) {
            return const Center(
                child: Text("No records for this class"));
          }

          final students =
          data[key] as Map<String, dynamic>;

          return ListView(
            children: students.entries.map((entry) {
              final student =
              entry.value as Map<String, dynamic>;

              return ListTile(
                title: Text(student['name']),
                trailing: Icon(
                  student['present']
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: student['present']
                      ? Colors.green
                      : Colors.red,
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
