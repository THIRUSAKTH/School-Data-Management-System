import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAddStudentPage extends StatefulWidget {
  final String schoolId;

  const AdminAddStudentPage({super.key, required this.schoolId});

  @override
  State<AdminAddStudentPage> createState() => _AdminAddStudentPageState();
}

class _AdminAddStudentPageState extends State<AdminAddStudentPage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final classController = TextEditingController();
  final sectionController = TextEditingController();
  final rollController = TextEditingController();
  final parentEmailController = TextEditingController();

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Student")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _field(nameController, "Student Name"),
              _field(classController, "Class (eg: 8)"),
              _field(sectionController, "Section (eg: A)"),
              _field(rollController, "Roll Number"),
              _field(parentEmailController, "Parent Email"),

              const SizedBox(height: 20),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: loading ? null : _addStudent,
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Create Student"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        validator: (v) => v == null || v.isEmpty ? "Required" : null,
        decoration: InputDecoration(
          labelText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _addStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final schoolRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId);

      final parentEmail = parentEmailController.text.trim().toLowerCase();

      // 🔍 Check if parent exists
      final parentQuery = await schoolRef
          .collection('parents')
          .where('email', isEqualTo: parentEmail)
          .limit(1)
          .get();

      String parentId;

      // 👨‍👩‍👧 Auto-create parent if not exists
      if (parentQuery.docs.isEmpty) {
        final parentDoc = await schoolRef.collection('parents').add({
          'email': parentEmail,
          'firstLogin': true,
          'createdAt': FieldValue.serverTimestamp(),
        });

        parentId = parentDoc.id;
      } else {
        parentId = parentQuery.docs.first.id;
      }

      // 🎓 Create student
      // 🎓 Create student (linked properly)
      await schoolRef.collection('students').add({
        'name': nameController.text.trim(),
        'class': classController.text.trim(),
        'section': sectionController.text.trim(),
        'rollNo': rollController.text.trim(),

        'parentUid': parentId,        // ✅ fixed key
        'parentEmail': parentEmail,  // optional but useful

        'createdAt': FieldValue.serverTimestamp(),
      });


      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Student added successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => loading = false);
  }
}
