import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminMonthlyAttendancePage extends StatelessWidget {
  final String schoolId;
  final String classId;
  final int month;
  final int year;

  const AdminMonthlyAttendancePage({
    super.key,
    required this.schoolId,
    required this.classId,
    required this.month,
    required this.year,
  });

  Future<Map<String, double>> calculate() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('attendance')
        .doc(classId)
        .collection('records')
        .get();

    Map<String, int> present = {};
    int totalDays = 0;

    for (var doc in snapshot.docs) {
      final date = (doc['date'] as Timestamp).toDate();
      if (date.month == month && date.year == year) {
        totalDays++;
        doc.data().forEach((k, v) {
          if (v == true) {
            present[k] = (present[k] ?? 0) + 1;
          }
        });
      }
    }

    return {
      for (var e in present.entries)
        e.key: totalDays == 0 ? 0 : (e.value / totalDays) * 100
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Monthly Report - $classId")),
      body: FutureBuilder<Map<String, double>>(
        future: calculate(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.isEmpty) {
            return const Center(child: Text("No attendance data"));
          }

          return ListView(
            children: snapshot.data!.entries.map((e) {
              return ListTile(
                title: Text("Student ID: ${e.key}"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${e.value.toStringAsFixed(1)}%"),
                    LinearProgressIndicator(value: e.value / 100),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}