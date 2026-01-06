import 'package:flutter/material.dart';

class TeacherManagementPage extends StatelessWidget {
  const TeacherManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Teachers")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 10,
        itemBuilder: (_, i) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.school),
              title: Text("Teacher ${i + 1}"),
              subtitle: const Text("Subject: Maths"),
            ),
          );
        },
      ),
    );
  }
}