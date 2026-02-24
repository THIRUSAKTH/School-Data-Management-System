import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClassManagementPage extends StatefulWidget {
  final String schoolId;

  const ClassManagementPage({super.key, required this.schoolId});

  @override
  State<ClassManagementPage> createState() => _ClassManagementPageState();
}

class _ClassManagementPageState extends State<ClassManagementPage> {
  String searchText = "";

  Future<String> getTeacherName(String id) async {
    final doc = await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('teachers')
        .doc(id)
        .get();
    return doc.exists ? doc['name'] : "Unknown";
  }

  void openEditDialog(DocumentSnapshot classDoc) {
    String? selectedClassTeacher = classDoc['classTeacherId'];
    Map<String, dynamic> subjectTeachers =
    Map<String, dynamic>.from(classDoc['subjectTeachers'] ?? {});

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Edit Class"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                /// Class Teacher Dropdown
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('schools')
                      .doc(widget.schoolId)
                      .collection('teachers')
                      .snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) return const CircularProgressIndicator();

                    return DropdownButtonFormField<String>(
                      value: selectedClassTeacher,
                      decoration:
                      const InputDecoration(labelText: "Class Teacher"),
                      items: snap.data!.docs.map((t) {
                        return DropdownMenuItem(
                          value: t.id,
                          child: Text(t['name']),
                        );
                      }).toList(),
                      onChanged: (v) => selectedClassTeacher = v,
                    );
                  },
                ),

                const SizedBox(height: 10),

                /// Add subject teacher
                ElevatedButton(
                  onPressed: () async {
                    final teachersSnap = await FirebaseFirestore.instance
                        .collection('schools')
                        .doc(widget.schoolId)
                        .collection('teachers')
                        .get();

                    showModalBottomSheet(
                      context: context,
                      builder: (_) {
                        return ListView(
                          children: teachersSnap.docs.map((t) {
                            return ListTile(
                              title: Text(t['name']),
                              onTap: () async {
                                final subjectController =
                                TextEditingController();

                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title:
                                    const Text("Enter Subject Name"),
                                    content: TextField(
                                        controller: subjectController),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          subjectTeachers[
                                          subjectController.text] =
                                              t.id;
                                          Navigator.pop(context);
                                          Navigator.pop(context);
                                        },
                                        child: const Text("Assign"),
                                      )
                                    ],
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        );
                      },
                    );
                  },
                  child: const Text("Add Subject Teacher"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('schools')
                    .doc(widget.schoolId)
                    .collection('classes')
                    .doc(classDoc.id)
                    .update({
                  "classTeacherId": selectedClassTeacher,
                  "subjectTeachers": subjectTeachers,
                });
                Navigator.pop(context);
              },
              child: const Text("Save"),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Classes")),
      body: Column(
        children: [
          /// 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search class (eg: 10 A)",
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => searchText = v.toLowerCase()),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('schools')
                  .doc(widget.schoolId)
                  .collection('classes')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final name =
                  "${doc['class']} ${doc['section']}".toLowerCase();
                  return name.contains(searchText);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text("No classes found"));
                }

                return ListView(
                  children: docs.map((doc) {
                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title:
                        Text("Class ${doc['class']} - ${doc['section']}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => openEditDialog(doc),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (doc['classTeacherId'] != null)
                              FutureBuilder(
                                future:
                                getTeacherName(doc['classTeacherId']),
                                builder: (c, s) => Text(
                                    "Class Teacher: ${s.data ?? ""}"),
                              ),
                            if ((doc['subjectTeachers'] ?? {}).isNotEmpty)
                              const Text("Subject Teachers:",
                                  style:
                                  TextStyle(fontWeight: FontWeight.bold)),
                            ...Map<String, dynamic>.from(
                                doc['subjectTeachers'] ?? {})
                                .entries
                                .map(
                                  (e) => FutureBuilder(
                                future: getTeacherName(e.value),
                                builder: (c, s) =>
                                    Text("${e.key} - ${s.data ?? ""}"),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}