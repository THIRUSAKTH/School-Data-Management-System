import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminAddStudentPage extends StatefulWidget {
  final String schoolId;

  const AdminAddStudentPage({
    super.key,
    required this.schoolId,
  });

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
              _field(classController, "Class"),
              _field(sectionController, "Section"),
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

      final parentEmail = parentEmailController.text
          .trim()
          .toLowerCase();

      String parentUid;

      // 🔍 Check parent Firestore
      final parentQuery = await schoolRef
          .collection('parents')
          .where('email', isEqualTo: parentEmail)
          .limit(1)
          .get();

      if (parentQuery.docs.isEmpty) {

        // ⚠️ SAVE ADMIN SESSION
        final adminUser = FirebaseAuth.instance.currentUser;

        // 👨‍👩‍👧 CREATE AUTH ACCOUNT FOR PARENT
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: parentEmail,
          password: "parent@123",
        );

        parentUid = credential.user!.uid;

        // 📄 CREATE PARENT PROFILE
        await schoolRef.collection('parents').doc(parentUid).set({
          'email': parentEmail,
          'firstLogin': true,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 🔐 LOGIN BACK AS ADMIN
        if (adminUser != null) {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: adminUser.email!,
            password: "YOUR_ADMIN_PASSWORD",
          );
        }

      } else {
        parentUid = parentQuery.docs.first.id;
      }

      // 🎓 CREATE STUDENT (PERFECTLY LINKED)
      await schoolRef.collection('students').add({
        'name': nameController.text.trim(),
        'class': classController.text.trim(),
        'section': sectionController.text.trim(),
        'rollNo': rollController.text.trim(),
        'parentUid': parentUid,
        'parentEmail': parentEmail,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Student linked with parent successfully")),
      );

      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => loading = false);
  }
}
