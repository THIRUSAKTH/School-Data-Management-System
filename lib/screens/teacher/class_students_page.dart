import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ClassStudentsPage extends StatefulWidget {
  const ClassStudentsPage({super.key});

  @override
  State<ClassStudentsPage> createState() => _ClassStudentsPageState();
}

class _ClassStudentsPageState extends State<ClassStudentsPage> {
  final String classId = "grade_10_A";
  final String teacherId = "teacher_001";

  final String today =
  DateFormat("yyyy-MM-dd").format(DateTime.now());

  final List<Map<String, dynamic>> students = List.generate(
    30,
        (i) => {
      "id": "student_${i + 1}",
      "name": "Student ${i + 1}",
      "roll": "10${i + 1}",
      "present": true,
    },
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mark Attendance"),
        actions: [
          TextButton(
            onPressed: _saveAttendance,
            child: const Text(
              "SAVE",
              style: TextStyle(color: Colors.black),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          _dateHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: students.length,
              itemBuilder: (_, index) {
                final student = students[index];
                return _studentTile(student);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// STUDENT TILE
  Widget _studentTile(Map<String, dynamic> student) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
          student["present"] ? Colors.green : Colors.red,
          child: const Icon(Icons.person, color: Colors.white),
        ),
        title: Text(student["name"]),
        subtitle: Text("Roll No: ${student["roll"]}"),
        trailing: Switch(
          value: student["present"],
          activeColor: Colors.green,
          inactiveThumbColor: Colors.red,
          onChanged: (value) {
            setState(() {
              student["present"] = value;
            });
          },
        ),
      ),
    );
  }

  /// DATE HEADER
  Widget _dateHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade200,
      child: Text(
        "Date: $today",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  /// SAVE ATTENDANCE
  void _saveAttendance() {
    final attendancePayload = {
      "classId": classId,
      "date": today,
      "teacherId": teacherId,
      "students": students.map((s) {
        return {
          "studentId": s["id"],
          "status": s["present"] ? "present" : "absent",
        };
      }).toList(),
      "timestamp": DateTime.now().toIso8601String(),
    };

    // 🔥 Firebase upload will go here
    debugPrint(attendancePayload.toString());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Attendance saved successfully")),
    );
  }
}