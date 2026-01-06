import 'package:flutter/material.dart';

class ClassSectionPage extends StatelessWidget {
  const ClassSectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final classes = ["6-A", "6-B", "7-A", "7-B", "8-A", "8-B"];

    return Scaffold(
      appBar: AppBar(title: const Text("Classes & Sections")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: classes
            .map(
              (cls) => Card(
            child: ListTile(
              title: Text("Class $cls"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            ),
          ),
        )
            .toList(),
      ),
    );
  }
}