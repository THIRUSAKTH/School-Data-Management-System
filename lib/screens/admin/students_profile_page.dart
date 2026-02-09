import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentProfilePage extends StatelessWidget {
  final String schoolId;
  final String studentId;

  const StudentProfilePage({
    super.key,
    required this.schoolId,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Profile"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolId)
            .collection('students')
            .doc(studentId)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Student not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final parentId = data['parentId'];
          final parentEmail = data['parentEmail'];

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _info("Name", data['name']),
                _info("Class", data['class']),
                _info("Section", data['section']),
                _info("Roll No", data['rollNo']),
                _info(
                  "Parent Email",
                  parentEmail ?? "Not linked",
                ),
                _info(
                  "Parent ID",
                  parentId ?? "Not linked",
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                    ),
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text(
                      "Edit Student",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      // edit screen later
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _info(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Student"),
        content: const Text("Are you sure you want to delete this student?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('schools')
                  .doc(schoolId)
                  .collection('students')
                  .doc(studentId)
                  .delete();

              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
