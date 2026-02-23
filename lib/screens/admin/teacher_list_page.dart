import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'assign_class_to_teacher_page.dart';

class TeacherListPage extends StatelessWidget {
  final String schoolId;
  final bool isAssignMode;

  const TeacherListPage({
    super.key,
    required this.schoolId,
    this.isAssignMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isAssignMode ? "Select Teacher" : "Teachers"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolId)
            .collection('teachers')
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No teachers found"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];

              final name = doc['name'] ?? "Teacher";
              final email = doc['email'] ?? "";

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),

                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(.15),
                    child: const Icon(Icons.school, color: Colors.blue),
                  ),

                  title: Text(
                    name,


                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  subtitle: Text(email),

                  trailing: isAssignMode
                      ? ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,foregroundColor: Colors.white,
                    ),
                    child: const Text("Assign",style: TextStyle(fontWeight: FontWeight.bold),),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AssignClassToTeacherPage(
                            schoolId: schoolId,
                            teacherId: doc.id,
                          ),
                        ),
                      );
                    },
                  )
                      : const Icon(Icons.arrow_forward_ios, size: 14),
                ),
              );
            },
          );
        },
      ),
    );
  }
}