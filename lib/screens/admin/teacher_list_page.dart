import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'assign_class_to_teacher_page.dart';

class TeacherListPage extends StatefulWidget {
  final String schoolId;
  final bool isAssignMode;
  final bool isSubjectAssignMode;

  const TeacherListPage({
    super.key,
    required this.schoolId,
    this.isAssignMode = false,
    this.isSubjectAssignMode = false,
  });

  @override
  State<TeacherListPage> createState() => _TeacherListPageState();
}

class _TeacherListPageState extends State<TeacherListPage> {
  String _searchQuery = "";
  String? _selectedDepartmentFilter;
  List<String> _availableDepartments = [];

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    try {
      final teachersSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('teachers')
          .get();

      final Set<String> departments = {};
      for (var doc in teachersSnapshot.docs) {
        final data = doc.data();
        final dept = data['department'] as String?;
        if (dept != null && dept.isNotEmpty) {
          departments.add(dept);
        }
      }

      setState(() {
        _availableDepartments = departments.toList()..sort();
      });
    } catch (e) {
      debugPrint('Error loading departments: $e');
    }
  }

  String _getPageTitle() {
    if (widget.isSubjectAssignMode) {
      return "Assign Subjects";
    } else if (widget.isAssignMode) {
      return "Select Teacher";
    }
    return "Teachers";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text(
          _getPageTitle(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: "Refresh",
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_availableDepartments.isNotEmpty) _buildDepartmentFilter(),
          _buildTeacherCount(),
          Expanded(
            child: _buildTeacherList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(12),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search by name, email, or phone...",
          prefixIcon: const Icon(Icons.search, color: Colors.blue),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() => _searchQuery = "");
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
        onChanged: (value) {
          setState(() => _searchQuery = value.toLowerCase());
        },
      ),
    );
  }

  Widget _buildDepartmentFilter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _availableDepartments.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: const Text("All"),
                selected: _selectedDepartmentFilter == null,
                onSelected: (_) {
                  setState(() {
                    _selectedDepartmentFilter = null;
                  });
                },
                backgroundColor: Colors.grey.shade100,
                selectedColor: Colors.blue.shade100,
                checkmarkColor: Colors.blue,
              ),
            );
          }

          final department = _availableDepartments[index - 1];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(department),
              selected: _selectedDepartmentFilter == department,
              onSelected: (selected) {
                setState(() {
                  _selectedDepartmentFilter = selected ? department : null;
                });
              },
              backgroundColor: Colors.grey.shade100,
              selectedColor: Colors.blue.shade100,
              checkmarkColor: Colors.blue,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTeacherCount() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('teachers')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        int count = snapshot.data!.docs.length;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.school, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                "$count Teacher${count != 1 ? 's' : ''}",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTeacherList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('teachers')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _emptyState();
        }

        var teachers = snapshot.data!.docs;

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          teachers = teachers.where((teacher) {
            final data = teacher.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '').toString().toLowerCase();
            final email = (data['email'] ?? '').toString().toLowerCase();
            final phone = (data['phone'] ?? '').toString().toLowerCase();
            return name.contains(_searchQuery) ||
                email.contains(_searchQuery) ||
                phone.contains(_searchQuery);
          }).toList();
        }

        // Apply department filter
        if (_selectedDepartmentFilter != null) {
          teachers = teachers.where((teacher) {
            final data = teacher.data() as Map<String, dynamic>;
            final dept = (data['department'] ?? '').toString();
            return dept == _selectedDepartmentFilter;
          }).toList();
        }

        if (teachers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  "No teachers found",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
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
          onRefresh: () async {
            setState(() {});
            await _loadDepartments();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: teachers.length,
            itemBuilder: (context, index) {
              final doc = teachers[index];
              final data = doc.data() as Map<String, dynamic>;

              final name = (data['name'] ?? data['teacherName'] ?? "Teacher").toString();
              final email = (data['email'] ?? "").toString();
              final phone = (data['phone'] ?? "").toString();
              final subjects = data['subjects'] as List? ?? [];
              final department = (data['department'] ?? "").toString();
              final assignedClasses = data['assignedClasses'] as List? ?? [];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: widget.isAssignMode || widget.isSubjectAssignMode
                      ? () {
                    if (widget.isSubjectAssignMode) {
                      _showSubjectAssignmentDialog(doc.id, name, subjects);
                    } else if (widget.isAssignMode) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AssignClassToTeacherPage(
                            schoolId: widget.schoolId,
                            teacherId: doc.id,
                            teacherName: name,
                          ),
                        ),
                      );
                    }
                  }
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : "T",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Teacher Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),

                              if (email.isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(Icons.email, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        email,
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),

                              if (phone.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.phone, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        phone,
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),

                              if (subjects.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: subjects.take(2).map((subject) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          subject.toString(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),

                              if (department.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    "Dept: $department",
                                    style: const TextStyle(fontSize: 11, color: Colors.purple),
                                  ),
                                ),

                              if (assignedClasses.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    "${assignedClasses.length} Class${assignedClasses.length != 1 ? 'es' : ''} Assigned",
                                    style: const TextStyle(fontSize: 11, color: Colors.orange),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Action Button
                        if (widget.isSubjectAssignMode)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "Subjects",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          )
                        else if (widget.isAssignMode)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "Assign",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AssignClassToTeacherPage(
                                    schoolId: widget.schoolId,
                                    teacherId: doc.id,
                                    teacherName: name,
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showSubjectAssignmentDialog(String teacherId, String teacherName, List<dynamic> currentSubjects) {
    List<String> availableSubjects = [
      "Tamil", "English", "Mathematics", "Physics", "Chemistry",
      "Biology", "History", "Geography", "Computer Science",
      "Accountancy", "Commerce", "Economics", "Physical Education",
      "Art", "Music",
    ];

    List<String> selectedSubjects = List<String>.from(currentSubjects.map((s) => s.toString()));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text("Assign Subjects to $teacherName"),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: Column(
                children: [
                  const Text(
                    "Select subjects taught by this teacher",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: availableSubjects.length,
                      itemBuilder: (context, index) {
                        final subject = availableSubjects[index];
                        final isSelected = selectedSubjects.contains(subject);
                        return CheckboxListTile(
                          title: Text(subject),
                          value: isSelected,
                          onChanged: (selected) {
                            setStateDialog(() {
                              if (selected == true) {
                                selectedSubjects.add(subject);
                              } else {
                                selectedSubjects.remove(subject);
                              }
                            });
                          },
                          activeColor: Colors.purple,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _updateTeacherSubjects(teacherId, selectedSubjects);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Subjects updated successfully"),
                        backgroundColor: Colors.green,
                      ),
                    );
                    setState(() {});
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _updateTeacherSubjects(String teacherId, List<String> subjects) async {
    await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('teachers')
        .doc(teacherId)
        .update({
      'subjects': subjects,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No teachers added yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Add teachers to get started",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}