import 'package:flutter/material.dart';

class TeacherAttendancePage extends StatelessWidget {
  const TeacherAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mark Attendance")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 25,
        itemBuilder: (_, i) {
          return Card(
            child: CheckboxListTile(
              title: Text("Student ${i + 1}"),
              value: true,
              onChanged: (_) {},
            ),
          );
        },
      ),
    );
  }
}