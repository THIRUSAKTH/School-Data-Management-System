import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:schoolprojectjan/screens/admin/students_profile_page.dart';
import 'admin-add-student-page.dart';

class StudentManagementPage extends StatelessWidget {
  final String schoolId;

  const StudentManagementPage({
    super.key,
    required this.schoolId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Management",style: TextStyle(fontWeight: FontWeight.bold,),),
        backgroundColor: Colors.cyan,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.cyan,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          "Add Student",
          style: TextStyle(color: Colors.white),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminAddStudentPage(schoolId: schoolId),
            ),
          );
        },
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolId)
            .collection('students')
            .orderBy('createdAt', descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _emptyState();
          }

          final students = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final s = students[index];
              final studentId = s.id; // ✅ ALWAYS use Firestore doc id

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

                  leading: CircleAvatar(
                    backgroundColor: Colors.deepPurple.withOpacity(0.15),
                    child:
                    const Icon(Icons.person, color: Colors.deepPurple),
                  ),

                  title: Text(
                    s['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "Class ${s['class']} - ${s['section']} | Roll ${s['rollNo']}",
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),

                  trailing:
                  const Icon(Icons.arrow_forward_ios, size: 16),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentProfilePage(
                          schoolId: schoolId,
                          studentId: studentId, // ✅ correct student
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

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.groups, size: 80, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            "No students added yet",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
