import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app_config.dart';

class AttendanceHistoryPage extends StatelessWidget {
  final String studentId;

  const AttendanceHistoryPage({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Attendance History")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('schools')
            .doc(AppConfig.schoolId)
            .collection('attendance')
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const CircularProgressIndicator();
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No attendance data"));
          }

          return ListView(
            children: docs.map((doc) {
              final date = doc.id;

              return ListTile(
                title: Text("Date: $date"),
                subtitle: const Text("Check attendance record"),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}