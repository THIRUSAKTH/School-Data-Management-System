import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'assign_class_to_teacher_page.dart';

class TeacherListPage extends StatefulWidget {
  final String schoolId;
  final bool isAssignMode;

  const TeacherListPage({
    super.key,
    required this.schoolId,
    this.isAssignMode = false,
  });

  @override
  State<TeacherListPage> createState() => _TeacherListPageState();
}

class _TeacherListPageState extends State<TeacherListPage> {
  String searchQuery = "";
  String? selectedDepartmentFilter;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text(
          widget.isAssignMode ? "Select Teacher" : "Teachers",
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
          if (_availableDepartments.isNotEmpty)
            _buildDepartmentFilter(),
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
          hintText: "Search by name or email...",
          prefixIcon: const Icon(Icons.search, color: Colors.blue),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() => searchQuery = "");
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
          setState(() => searchQuery = value.toLowerCase());
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
                selected: selectedDepartmentFilter == null,
                onSelected: (_) {
                  setState(() {
                    selectedDepartmentFilter = null;
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
              selected: selectedDepartmentFilter == department,
              onSelected: (selected) {
                setState(() {
                  selectedDepartmentFilter = selected ? department : null;
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
        if (searchQuery.isNotEmpty) {
          teachers = teachers.where((teacher) {
            final data = teacher.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '').toString().toLowerCase();
            final email = (data['email'] ?? '').toString().toLowerCase();
            return name.contains(searchQuery) || email.contains(searchQuery);
          }).toList();
        }

        // Apply department filter
        if (selectedDepartmentFilter != null) {
          teachers = teachers.where((teacher) {
            final data = teacher.data() as Map<String, dynamic>;
            final dept = (data['department'] ?? '').toString();
            return dept == selectedDepartmentFilter;
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
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: teachers.length,
            itemBuilder: (context, index) {
              final doc = teachers[index];
              final data = doc.data() as Map<String, dynamic>;

              // Safe access using toString() and fallbacks
              final name = (data['name'] ?? data['teacherName'] ?? "Teacher").toString();
              final email = (data['email'] ?? "").toString();
              final phone = (data['phone'] ?? "").toString();
              final subject = (data['subject'] ?? "").toString();
              final department = (data['department'] ?? "").toString();
              final assignedClasses = data['assignedClasses'] as List? ?? [];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: widget.isAssignMode
                      ? () {
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
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 18,
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
                              if (subject.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      subject,
                                      style: TextStyle(fontSize: 10, color: Colors.green.shade700),
                                    ),
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
                        if (widget.isAssignMode)
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

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No teachers added yet",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
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