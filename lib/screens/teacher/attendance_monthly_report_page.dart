import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceMonthlyReportPage extends StatefulWidget {
  final String schoolId;

  const AttendanceMonthlyReportPage({
    super.key,
    required this.schoolId,
  });

  @override
  State<AttendanceMonthlyReportPage> createState() =>
      _AttendanceMonthlyReportPageState();
}

class _AttendanceMonthlyReportPageState
    extends State<AttendanceMonthlyReportPage> {
  String selectedClass = "10";
  String selectedSection = "A";
  DateTime selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Monthly Attendance Report"),
        backgroundColor: Colors.indigo,
      ),
      body: FutureBuilder(
        future: _generateReport(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final report =
          snapshot.data as Map<String, dynamic>;

          if (report.isEmpty) {
            return const Center(
                child: Text("No data found"));
          }

          return ListView(
            children: report.entries.map((entry) {
              final data =
              entry.value as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(data['name']),
                  subtitle: Text(
                      "Present: ${data['present']} / ${data['total']}"),
                  trailing: Text(
                    "${data['percentage']}%",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _generateReport() async {
    final Map<String, dynamic> report = {};

    final attendanceCollection = FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('attendance');

    final monthString =
        "${selectedMonth.year}-${selectedMonth.month.toString().padLeft(2, '0')}";

    final snapshot = await attendanceCollection.get();

    for (var doc in snapshot.docs) {
      if (doc.id.startsWith(monthString)) {
        final data = doc.data();

        final key =
            "class_${selectedClass}_${selectedSection}";

        if (data.containsKey(key)) {
          final students =
          data[key] as Map<String, dynamic>;

          for (var entry in students.entries) {
            final student =
            entry.value as Map<String, dynamic>;

            final id = entry.key;

            report.putIfAbsent(id, () {
              return {
                'name': student['name'],
                'present': 0,
                'total': 0
              };
            });

            report[id]['total']++;

            if (student['present'] == true) {
              report[id]['present']++;
            }
          }
        }
      }
    }

    for (var entry in report.entries) {
      final present = entry.value['present'];
      final total = entry.value['total'];

      entry.value['percentage'] =
      total == 0 ? 0 : ((present / total) * 100).round();
    }

    return report;
  }
}
