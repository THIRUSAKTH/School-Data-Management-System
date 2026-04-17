import 'package:flutter/material.dart';

class StudentDetailsPage extends StatelessWidget {
  final Map<String, dynamic> student;

  const StudentDetailsPage({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Details")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              student['name'] ?? "",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Text("Class: ${student['class']}"),
            Text("Section: ${student['section']}"),
            Text("Roll No: ${student['rollNo']}"),

            const SizedBox(height: 20),

            const Text("Attendance: 85%"),
            const Text("Fees Pending: ₹2000"),
          ],
        ),
      ),
    );
  }
}