import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateClassPage extends StatefulWidget {
  final String schoolId;

  const CreateClassPage({super.key, required this.schoolId});

  @override
  State<CreateClassPage> createState() => _CreateClassPageState();
}

class _CreateClassPageState extends State<CreateClassPage> {
  final classController = TextEditingController();
  final sectionController = TextEditingController();

  String? selectedClassTeacher;
  bool loading = false;

  Future<void> createClass() async {
    final className = classController.text.trim();
    final section = sectionController.text.trim().toUpperCase();

    if (className.isEmpty || section.isEmpty) return;

    final classId = "${className}_$section";

    setState(() => loading = true);

    await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('classes')
        .doc(classId)
        .set({
      "class": className,
      "section": section,
      "classTeacherId": selectedClassTeacher,
      "subjectTeachers": {},
      "createdAt": FieldValue.serverTimestamp(),
    });

    /// Update teacher assigned classes (important for permissions)
    if (selectedClassTeacher != null) {
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('teachers')
          .doc(selectedClassTeacher)
          .update({
        "assignedClasses": FieldValue.arrayUnion([classId])
      });
    }

    setState(() => loading = false);

    classController.clear();
    sectionController.clear();
    selectedClassTeacher = null;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Class created successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Class")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// Class
            TextField(
              controller: classController,
              decoration: const InputDecoration(
                labelText: "Class (eg: 10)",
              ),
            ),

            const SizedBox(height: 12),

            /// Section
            TextField(
              controller: sectionController,
              decoration: const InputDecoration(
                labelText: "Section (eg: A)",
              ),
            ),

            const SizedBox(height: 12),

            /// Class Teacher Dropdown
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('schools')
                  .doc(widget.schoolId)
                  .collection('teachers')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final teachers = snapshot.data!.docs;

                if (teachers.isEmpty) {
                  return const Text("No teachers added yet");
                }

                return DropdownButtonFormField<String>(
                  value: selectedClassTeacher,
                  decoration: const InputDecoration(
                    labelText: "Select Class Teacher",
                  ),
                  items: teachers.map((doc) {
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(doc['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedClassTeacher = value;
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 20),

            /// Create Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : createClass,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Create Class"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}