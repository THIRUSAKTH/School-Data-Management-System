import 'package:flutter/material.dart';

class StudentMarksPage extends StatelessWidget {
  const StudentMarksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Marks")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(title: Text("Maths"), trailing: Text("85")),
          ListTile(title: Text("Science"), trailing: Text("88")),
          ListTile(title: Text("English"), trailing: Text("78")),
        ],
      ),
    );
  }
}