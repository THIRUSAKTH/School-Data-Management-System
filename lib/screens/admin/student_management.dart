import 'package:flutter/material.dart';

class StudentManagementPage extends StatelessWidget {
  const StudentManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Students")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 20,
        itemBuilder: (_, i) {
          return Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text("Student ${i + 1}"),
              subtitle: const Text("Class 8 - A"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            ),
          );
        },
      ),
    );
  }
}