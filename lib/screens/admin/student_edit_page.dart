import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentEditPage extends StatefulWidget {
  final String schoolId;
  final String studentId;

  const StudentEditPage({
    super.key,
    required this.schoolId,
    required this.studentId,
  });

  @override
  State<StudentEditPage> createState() => _StudentEditPageState();
}

class _StudentEditPageState extends State<StudentEditPage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final classController = TextEditingController();
  final sectionController = TextEditingController();
  final rollController = TextEditingController();

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadStudent();
  }

  Future<void> _loadStudent() async {
    final doc = await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('students')
        .doc(widget.studentId)
        .get();

    final data = doc.data()!;

    nameController.text = data['name'];
    classController.text = data['class'];
    sectionController.text = data['section'];
    rollController.text = data['rollNo'];

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Student",style: TextStyle(fontWeight: FontWeight.bold),),centerTitle: true,
        backgroundColor: Colors.cyan,
        foregroundColor: Colors.white,
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _field(nameController, "Student Name"),
              _field(classController, "Class"),
              _field(sectionController, "Section"),
              _field(rollController, "Roll Number"),

              const SizedBox(height: 24),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                  ),
                  onPressed: _updateStudent,
                  child: const Text(
                    "Update Student",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        validator: (v) => v == null || v.isEmpty ? "Required" : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _updateStudent() async {
    if (!_formKey.currentState!.validate()) return;

    await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('students')
        .doc(widget.studentId)
        .update({
      'name': nameController.text.trim(),
      'class': classController.text.trim(),
      'section': sectionController.text.trim(),
      'rollNo': rollController.text.trim(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Student updated successfully")),
    );
    Navigator.pop(context);
  }
}
