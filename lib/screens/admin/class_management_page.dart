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
  bool _isRefreshing = false;

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

      final name = doc.exists ? (doc.data()?['name'] ?? "Unknown") : "Unknown";
      _teacherNameCache[id] = name;
      return name;
    } catch (e) {
      debugPrint('Error getting teacher name for $id: $e');
      return "Unknown";
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _isLoading = true;
    });

    _teacherNameCache.clear();
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  void _showEditDialog(DocumentSnapshot classDoc) {
    final data = classDoc.data() as Map<String, dynamic>;

    String? selectedClassTeacher = data['classTeacherId'] as String?;

    // Safe casting of subjectTeachers
    Map<String, dynamic> subjectTeachers = {};
    if (data['subjectTeachers'] != null) {
      subjectTeachers = Map<String, dynamic>.from(data['subjectTeachers']);
    }

    final TextEditingController newSubjectController = TextEditingController();
    String? selectedTeacherForSubject;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.edit, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text("Edit ${data['class']} - ${data['section']}"),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.6,
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
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (!snap.hasData || snap.data!.docs.isEmpty) {
                            return const Text(
                              "No teachers available",
                              style: TextStyle(color: Colors.grey),
                            );
                          }

                          final teachers = snap.data!.docs;

                          return DropdownButtonFormField<String>(
                            value: selectedClassTeacher,
                            decoration: const InputDecoration(
                              labelText: "Select Class Teacher",
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text("None"),
                              ),
                              ...teachers.map<DropdownMenuItem<String>>((t) {
                                final teacherData = t.data() as Map<String, dynamic>;
                                return DropdownMenuItem<String>(
                                  value: t.id,
                                  child: Text(teacherData['name'] ?? 'Unknown'),
                                );
                              }).toList(),
                            ],
                            onChanged: (value) {
                              selectedClassTeacher = value;
                              setDialogState(() {});
                            },
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
                                  future: getTeacherName(entry.value.toString()),
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
                              controller: newSubjectController,
                              decoration: const InputDecoration(
                                labelText: "Subject Name",
                                hintText: "e.g., Mathematics, Physics",
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
                                if (snap.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }

                                if (!snap.hasData || snap.data!.docs.isEmpty) {
                                  return const Text(
                                    "No teachers available",
                                    style: TextStyle(color: Colors.grey),
                                  );
                                }

                                final teachers = snap.data!.docs;
                                return DropdownButtonFormField<String>(
                                  value: selectedTeacherForSubject,
                                  hint: const Text("Select Teacher"),
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  items: teachers.map<DropdownMenuItem<String>>((t) {
                                    final teacherData = t.data() as Map<String, dynamic>;
                                    return DropdownMenuItem<String>(
                                      value: t.id,
                                      child: Text(teacherData['name'] ?? 'Unknown'),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    selectedTeacherForSubject = value;
                                    setDialogState(() {});
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  final subject = newSubjectController.text.trim();
                                  if (subject.isNotEmpty && selectedTeacherForSubject != null) {
                                    setDialogState(() {
                                      subjectTeachers[subject] = selectedTeacherForSubject;
                                      newSubjectController.clear();
                                      selectedTeacherForSubject = null;
                                    });
                                  } else if (subject.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Please enter subject name")),
                                    );
                                  } else if (selectedTeacherForSubject == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Please select a teacher")),
                                    );
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
                    // Show loading indicator
                    setDialogState(() {});

                    try {
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
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Error updating class: $e"),
                          backgroundColor: Colors.red,
                        ),
                      );
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
            icon: _isRefreshing
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshData,
            tooltip: "Refresh",
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
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

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                const Text(
                  "Error loading classes",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
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
                  "Create a class first using 'Create Class' option",
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = "${data['class']} ${data['section']}".toLowerCase();
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

        return RefreshIndicator(
          onRefresh: _refreshData,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final className = data['class'] ?? 'Unknown';
              final section = data['section'] ?? '';
              final classTeacherId = data['classTeacherId'] as String?;
              final subjectTeachers = Map<String, dynamic>.from(data['subjectTeachers'] ?? {});

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
                                            future: getTeacherName(entry.value.toString()),
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
          ),
        );
      },
    );
  }
}