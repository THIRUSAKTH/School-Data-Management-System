import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:schoolprojectjan/screens/admin/students_profile_page.dart';
import 'admin-add-student-page.dart';

class StudentManagementPage extends StatefulWidget {
  final String schoolId;

  const StudentManagementPage({
    super.key,
    required this.schoolId,
  });

  @override
  State<StudentManagementPage> createState() =>
      _StudentManagementPageState();
}

class _StudentManagementPageState
    extends State<StudentManagementPage> {

  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      appBar: AppBar(
        title: const Text(
          "Student Management",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.cyan,
        foregroundColor: Colors.white,
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.cyan,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text("Add Student",
            style: TextStyle(color: Colors.white)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AdminAddStudentPage(schoolId: widget.schoolId),
            ),
          );
        },
      ),

      body: Column(
        children: [

          /// 🔍 SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search student...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (val) {
                setState(() => searchQuery = val.toLowerCase());
              },
            ),
          ),

          /// 📋 STUDENT LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('schools')
                  .doc(widget.schoolId)
                  .collection('students')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),

              builder: (context, snapshot) {

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return _emptyState();
                }

                final students = snapshot.data!.docs;

                /// 🔍 FILTER
                final filtered = students.where((s) {
                  final name =
                  (s['name'] ?? "").toString().toLowerCase();
                  return name.contains(searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text("No matching students"),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.builder(
                    padding:
                    const EdgeInsets.only(bottom: 90),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {

                      final s = filtered[index];
                      final studentId = s.id;

                      final name = s['name'] ?? "No Name";
                      final className = s['class'] ?? "-";
                      final section = s['section'] ?? "-";
                      final roll = s['rollNo'] ?? "-";

                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          contentPadding:
                          const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10),

                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor:
                            Colors.deepPurple.withValues(alpha: 0.15),
                            child: const Icon(Icons.person,
                                color: Colors.deepPurple),
                          ),

                          title: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),

                          subtitle: Padding(
                            padding:
                            const EdgeInsets.only(top: 4),
                            child: Text(
                              "Class $className - $section | Roll $roll",
                              style: const TextStyle(
                                  fontSize: 13),
                            ),
                          ),

                          trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16),

                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    StudentProfilePage(
                                      schoolId:
                                      widget.schoolId,
                                      studentId:
                                      studentId,
                                    ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 📭 EMPTY STATE
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.groups,
              size: 80, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            "No students added yet",
            style: TextStyle(
                fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}