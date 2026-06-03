import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClassManagementPage extends StatefulWidget {
  final String schoolId;

  const ClassManagementPage({super.key, required this.schoolId});

  @override
  State<ClassManagementPage> createState() => _ClassManagementPageState();
}

class _ClassManagementPageState extends State<ClassManagementPage> {
  String _searchText = "";
  bool _isLoading = false;
  bool _isRefreshing = false;

  // Cache for teacher names
  final Map<String, String> _teacherNameCache = {};

  Future<String> getTeacherName(String id) async {
    if (id.isEmpty) return "Not Assigned";

    if (_teacherNameCache.containsKey(id)) {
      return _teacherNameCache[id]!;
    }

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('teachers')
              .doc(id)
              .get();

      final name = doc.exists ? (doc.data()?['name'] ?? "Unknown") : "Unknown";
      _teacherNameCache[id] = name;
      return name;
    } catch (e) {
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

  // Simple Edit Dialog - No complex animations
  Future<void> _showEditDialog(DocumentSnapshot classDoc) async {
    final data = classDoc.data() as Map<String, dynamic>;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => EditClassDialog(
            schoolId: widget.schoolId,
            className: data['class'] ?? 'Unknown',
            section: data['section'] ?? '',
            initialClassTeacher: data['classTeacherId'] as String?,
            initialSubjectTeachers:
                data['subjectTeachers'] != null
                    ? Map<String, dynamic>.from(data['subjectTeachers'])
                    : {},
          ),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Updating class..."),
          duration: Duration(seconds: 1),
        ),
      );

      try {
        await FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolId)
            .collection('classes')
            .doc(classDoc.id)
            .update({
              "classTeacherId": result['classTeacherId'],
              "subjectTeachers": result['subjectTeachers'],
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
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
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
            icon:
                _isRefreshing
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
            child:
                _isLoading
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
          suffixIcon:
              _searchText.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _searchText = ""),
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        onChanged: (value) => setState(() => _searchText = value.toLowerCase()),
      ),
    );
  }

  Widget _buildClassList() {
    return StreamBuilder<QuerySnapshot>(
      key: ValueKey('class_list_${widget.schoolId}'),
      stream:
          FirebaseFirestore.instance
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
                const Text("Error loading classes"),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshData,
                  child: const Text("Retry"),
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
                const Text("No Classes Found"),
                const SizedBox(height: 8),
                Text(
                  "Create a class first",
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        final docs =
            snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = "${data['class']} ${data['section']}".toLowerCase();
              return name.contains(_searchText);
            }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text("No matching classes"),
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
              final subjectTeachers = Map<String, dynamic>.from(
                data['subjectTeachers'] ?? {},
              );

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
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showEditDialog(doc),
                    tooltip: "Edit Class",
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        future:
                                            classTeacherId != null
                                                ? getTeacherName(classTeacherId)
                                                : Future.value("Not Assigned"),
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
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.book,
                                      size: 18,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                            future: getTeacherName(
                                              entry.value.toString(),
                                            ),
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

// ==================== SEPARATE DIALOG WIDGET ====================
class EditClassDialog extends StatefulWidget {
  final String schoolId;
  final String className;
  final String section;
  final String? initialClassTeacher;
  final Map<String, dynamic> initialSubjectTeachers;

  const EditClassDialog({
    super.key,
    required this.schoolId,
    required this.className,
    required this.section,
    this.initialClassTeacher,
    required this.initialSubjectTeachers,
  });

  @override
  State<EditClassDialog> createState() => _EditClassDialogState();
}

class _EditClassDialogState extends State<EditClassDialog> {
  String? _selectedClassTeacher;
  Map<String, dynamic> _subjectTeachers = {};
  final TextEditingController _newSubjectController = TextEditingController();
  String? _selectedTeacherForSubject;

  @override
  void initState() {
    super.initState();
    _selectedClassTeacher = widget.initialClassTeacher;
    _subjectTeachers = Map<String, dynamic>.from(widget.initialSubjectTeachers);
  }

  @override
  void dispose() {
    // Dispose controller only once
    _newSubjectController.dispose();
    super.dispose();
  }

  void _addSubjectTeacher() {
    final subject = _newSubjectController.text.trim();
    if (subject.isEmpty) {
      _showSnackBar("Please enter subject name", Colors.orange);
      return;
    }
    if (_selectedTeacherForSubject == null) {
      _showSnackBar("Please select a teacher", Colors.orange);
      return;
    }
    if (_subjectTeachers.containsKey(subject)) {
      _showSnackBar(
        "This subject already has a teacher assigned",
        Colors.orange,
      );
      return;
    }

    setState(() {
      _subjectTeachers[subject] = _selectedTeacherForSubject;
      _newSubjectController.clear();
      _selectedTeacherForSubject = null;
    });
  }

  void _removeSubjectTeacher(String subject) {
    setState(() {
      _subjectTeachers.remove(subject);
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.edit, color: Colors.blue),
          const SizedBox(width: 8),
          Text("Edit ${widget.className} - ${widget.section}"),
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
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('schools')
                          .doc(widget.schoolId)
                          .collection('teachers')
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text(
                        "No teachers available",
                        style: TextStyle(color: Colors.grey),
                      );
                    }

                    final teachers = snapshot.data!.docs;
                    return DropdownButtonFormField<String>(
                      value: _selectedClassTeacher,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text("None"),
                        ),
                        ...teachers.map((t) {
                          final data = t.data() as Map<String, dynamic>;
                          return DropdownMenuItem(
                            value: t.id,
                            child: Text(data['name'] ?? 'Unknown'),
                          );
                        }),
                      ],
                      onChanged:
                          (value) =>
                              setState(() => _selectedClassTeacher = value),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Subject Teachers Section
              const Text(
                "Subject Teachers",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),

              // Existing Subject Teachers
              if (_subjectTeachers.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _subjectTeachers.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (context, index) {
                      final entry = _subjectTeachers.entries.elementAt(index);
                      return ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.book,
                          size: 18,
                          color: Colors.blue,
                        ),
                        title: Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: FutureBuilder(
                          future: _getTeacherName(entry.value.toString()),
                          builder: (context, snapshot) {
                            return Text(
                              "Teacher: ${snapshot.data ?? 'Loading...'}",
                              style: const TextStyle(fontSize: 11),
                            );
                          },
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.red,
                          ),
                          onPressed: () => _removeSubjectTeacher(entry.key),
                        ),
                      );
                    },
                  ),
                ),

              // Add New Subject Teacher
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
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
                        hintText: "e.g., Mathematics, Physics",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('schools')
                              .doc(widget.schoolId)
                              .collection('teachers')
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Text(
                            "No teachers available",
                            style: TextStyle(color: Colors.grey),
                          );
                        }

                        final teachers = snapshot.data!.docs;
                        return DropdownButtonFormField<String>(
                          value: _selectedTeacherForSubject,
                          hint: const Text("Select Teacher"),
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items:
                              teachers.map((t) {
                                final data = t.data() as Map<String, dynamic>;
                                return DropdownMenuItem(
                                  value: t.id,
                                  child: Text(data['name'] ?? 'Unknown'),
                                );
                              }).toList(),
                          onChanged:
                              (value) => setState(
                                () => _selectedTeacherForSubject = value,
                              ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addSubjectTeacher,
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
          onPressed: () {
            Navigator.pop(context, {
              'classTeacherId': _selectedClassTeacher,
              'subjectTeachers': _subjectTeachers,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text("Save Changes"),
        ),
      ],
    );
  }

  Future<String> _getTeacherName(String id) async {
    if (id.isEmpty) return "Not Assigned";
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('teachers')
              .doc(id)
              .get();
      return doc.exists ? (doc.data()?['name'] ?? "Unknown") : "Unknown";
    } catch (e) {
      return "Unknown";
    }
  }
}
