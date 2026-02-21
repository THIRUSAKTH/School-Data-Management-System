import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssignClassToTeacherPage extends StatefulWidget {
  final String schoolId;
  final String teacherId;

  const AssignClassToTeacherPage({
    super.key,
    required this.schoolId,
    required this.teacherId,
  });

  @override
  State<AssignClassToTeacherPage> createState() =>
      _AssignClassToTeacherPageState();
}

class _AssignClassToTeacherPageState extends State<AssignClassToTeacherPage> {
  final classController = TextEditingController();
  final sectionController = TextEditingController();

  List<Map<String, String>> assigned = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Assign Classes")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _field(classController, "Class (eg: 10)"),
            const SizedBox(height: 12),
            _field(sectionController, "Section (eg: A)"),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: _addClass,
              child: const Text("Add Class"),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: assigned.length,
                itemBuilder: (context, i) {
                  final item = assigned[i];
                  return Card(
                    child: ListTile(
                      title: Text("Class ${item['class']} - ${item['section']}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() => assigned.removeAt(i));
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saveClasses,
                child: const Text("Save Assignments"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint) {
    return TextField(
      controller: c,
      decoration: InputDecoration(
        labelText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }

  void _addClass() {
    if (classController.text.isEmpty || sectionController.text.isEmpty) return;

    setState(() {
      assigned.add({
        "class": classController.text.trim(),
        "section": sectionController.text.trim(),
      });
    });

    classController.clear();
    sectionController.clear();
  }

  Future<void> _saveClasses() async {
    await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('teachers')
        .doc(widget.teacherId)
        .update({
      'assignedClasses': assigned,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Classes assigned successfully")),
    );

    Navigator.pop(context);
  }
}