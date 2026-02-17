import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'mark_attendance_page.dart';

class SelectClassAttendancePage extends StatelessWidget {
  final String schoolId;

  const SelectClassAttendancePage({
    super.key,
    required this.schoolId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Class"),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolId)
            .collection('students')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No classes found"));
          }

          // Get unique class-section combinations
          final classes = <String>{};

          for (var doc in snapshot.data!.docs) {
            final className = doc['class'];
            final section = doc['section'];
            classes.add("$className-$section");
          }

          final classList = classes.toList()..sort();

          return ListView.builder(
            itemCount: classList.length,
            itemBuilder: (context, index) {
              final item = classList[index];
              final parts = item.split('-');

              return Card(
                margin: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.class_),
                  title: Text("Class ${parts[0]}"),
                  subtitle: Text("Section ${parts[1]}"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MarkAttendancePage(
                          schoolId: schoolId,
                          className: parts[0],
                          section: parts[1],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
