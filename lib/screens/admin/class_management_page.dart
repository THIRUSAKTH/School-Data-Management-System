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
  bool _isLoading = false;

  // Cache for teacher names to avoid repeated Firestore calls
  final Map<String, String> _teacherNameCache = {};

  Future<String> getTeacherName(String id) async {
    if (_teacherNameCache.containsKey(id)) {
      return _teacherNameCache[id]!;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('teachers')
          .doc(id)
          .get();

      final name = doc.exists ? (doc['name'] ?? "Unknown") : "Unknown";
      _teacherNameCache[id] = name;
      return name;
    } catch (e) {
      return "Unknown";
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    _teacherNameCache.clear();
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoading = false);
  }

  void _showEditDialog(DocumentSnapshot classDoc) {
    String? selectedClassTeacher = classDoc['classTeacherId'];
    Map<String, dynamic> subjectTeachers =
    Map<String, dynamic>.from(classDoc['subjectTeachers'] ?? {});

    final TextEditingController _newSubjectController = TextEditingController();
    String? _selectedTeacherForSubject;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.edit, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text("Edit ${classDoc['class']} - ${classDoc['section']}"),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Class Teacher Section
                      const Text(
                        "Class Teacher",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('schools')
                            .doc(widget.schoolId)
                            .collection('teachers')
                            .snapshots(),
                        builder: (context, snap) {
                          if (!snap.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final teachers = snap.data!.docs;
                          if (teachers.isEmpty) {
                            return const Text(
                              "No teachers available",
                              style: TextStyle(color: Colors.grey),
                            );
                          }

                          return DropdownButtonFormField<String>(
                            value: selectedClassTeacher,
                            decoration: const InputDecoration(
                              labelText: "Select Class Teacher",
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text("None"),
                              ),
                              ...teachers.map((t) {
                                return DropdownMenuItem(
                                  value: t.id,
                                  child: Text(t['name'] ?? 'Unknown'),
                                );
                              }).toList(),
                            ],
                            onChanged: (v) => selectedClassTeacher = v,
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // Subject Teachers Section
                      const Text(
                        "Subject Teachers",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Existing Subject Teachers List
                      if (subjectTeachers.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: subjectTeachers.length,
                            separatorBuilder: (_, __) => const Divider(height: 0),
                            itemBuilder: (context, index) {
                              final entry = subjectTeachers.entries.elementAt(index);
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.book, size: 18),
                                title: Text(
                                  entry.key,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                subtitle: FutureBuilder(
                                  future: getTeacherName(entry.value),
                                  builder: (context, snapshot) {
                                    return Text(
                                      "Teacher: ${snapshot.data ?? 'Loading...'}",
                                      style: const TextStyle(fontSize: 12),
                                    );
                                  },
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                  onPressed: () {
                                    setDialogState(() {
                                      subjectTeachers.remove(entry.key);
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        ),

                      // Add New Subject Teacher
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Add Subject Teacher",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _newSubjectController,
                              decoration: const InputDecoration(
                                labelText: "Subject Name",
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('schools')
                                  .doc(widget.schoolId)
                                  .collection('teachers')
                                  .snapshots(),
                              builder: (context, snap) {
                                if (!snap.hasData) {
                                  return const Center(child: CircularProgressIndicator());
                                }

                                final teachers = snap.data!.docs;
                                return DropdownButtonFormField<String>(
                                  value: _selectedTeacherForSubject,
                                  hint: const Text("Select Teacher"),
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  items: teachers.map((t) {
                                    return DropdownMenuItem(
                                      value: t.id,
                                      child: Text(t['name'] ?? 'Unknown'),
                                    );
                                  }).toList(),
                                  onChanged: (v) => _selectedTeacherForSubject = v,
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  final subject = _newSubjectController.text.trim();
                                  if (subject.isNotEmpty && _selectedTeacherForSubject != null) {
                                    setDialogState(() {
                                      subjectTeachers[subject] = _selectedTeacherForSubject;
                                      _newSubjectController.clear();
                                      _selectedTeacherForSubject = null;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text("Add"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('schools')
                        .doc(widget.schoolId)
                        .collection('classes')
                        .doc(classDoc.id)
                        .update({
                      "classTeacherId": selectedClassTeacher,
                      "subjectTeachers": subjectTeachers,
                      "updatedAt": FieldValue.serverTimestamp(),
                    });

                    _teacherNameCache.clear();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Class updated successfully"),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Save Changes"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          "Class Management",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: "Refresh",
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),

          // Class List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildClassList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search by class name...",
          prefixIcon: const Icon(Icons.search, color: Colors.blue),
          suffixIcon: searchText.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                searchText = "";
              });
            },
          )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 1),
          ),
        ),
        onChanged: (value) => setState(() => searchText = value.toLowerCase()),
      ),
    );
  }

  Widget _buildClassList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('classes')
          .orderBy('class')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.class_, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  "No Classes Found",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  "Create a class first",
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs.where((doc) {
          final name = "${doc['class']} ${doc['section']}".toLowerCase();
          return name.contains(searchText);
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  "No matching classes",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  "Try a different search term",
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final className = doc['class'] ?? 'Unknown';
            final section = doc['section'] ?? '';
            final classTeacherId = doc['classTeacherId'];
            final subjectTeachers = Map<String, dynamic>.from(doc['subjectTeachers'] ?? {});

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ExpansionTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.class_,
                    color: Colors.blue.shade700,
                    size: 28,
                  ),
                ),
                title: Text(
                  "$className - ${section.isEmpty ? 'A' : section}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showEditDialog(doc),
                      tooltip: "Edit Class",
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Class Teacher
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person, color: Colors.blue),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Class Teacher",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    FutureBuilder(
                                      future: classTeacherId != null ? getTeacherName(classTeacherId) : Future.value("Not Assigned"),
                                      builder: (context, snapshot) {
                                        return Text(
                                          snapshot.data ?? "Loading...",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Subject Teachers
                        if (subjectTeachers.isNotEmpty) ...[
                          const Text(
                            "Subject Teachers",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...subjectTeachers.entries.map((entry) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.book, size: 18, color: Colors.grey),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.key,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        FutureBuilder(
                                          future: getTeacherName(entry.value),
                                          builder: (context, snapshot) {
                                            return Text(
                                              snapshot.data ?? "Loading...",
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],

                        if (subjectTeachers.isEmpty && classTeacherId == null)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                "No teachers assigned yet.\nTap Edit to assign teachers.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}