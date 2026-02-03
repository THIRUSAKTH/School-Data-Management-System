import 'package:flutter/material.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();

  static Widget _infoTile(String title, String value) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(title: const Text("Student Profile")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// PROFILE HEADER
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: const [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.deepPurple,
                  child: Icon(Icons.person, color: Colors.white, size: 40),
                ),
                SizedBox(height: 12),
                Text(
                  "Student Name",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text("Class 10 - A | Roll No: 12"),
              ],
            ),
          ),

          const SizedBox(height: 20),

          StudentProfilePage._infoTile("Admission No", "ADM2023-012"),
          StudentProfilePage._infoTile("Academic Year", "2025 - 2026"),
          StudentProfilePage._infoTile("Blood Group", "O+"),
          StudentProfilePage._infoTile("Class Teacher", "Mrs. Lakshmi"),
        ],
      ),
    );
  }
}