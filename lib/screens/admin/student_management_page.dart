import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:schoolprojectjan/screens/admin/admin_add_student_page.dart';
import 'package:schoolprojectjan/screens/admin/students_profile_page.dart';
import 'student_edit_page.dart';

class StudentManagementPage extends StatefulWidget {
  final String schoolId;

  const StudentManagementPage({
    super.key,
    required this.schoolId,
  });

  @override
  State<StudentManagementPage> createState() => _StudentManagementPageState();
}

class _StudentManagementPageState extends State<StudentManagementPage> {
  String _searchQuery = "";
  String? _selectedClassFilter;
  String? _selectedSectionFilter;
  String _selectedSortBy = "Name";

  List<String> _availableClasses = [];
  List<String> _availableSections = [];
  bool _isLoadingFilters = true;

  final List<String> _sortOptions = ["Name", "Roll Number", "Class"];

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    setState(() => _isLoadingFilters = true);

    try {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('students')
          .get();

      final Set<String> classesSet = {};
      final Set<String> sectionsSet = {};

      for (var doc in studentsSnapshot.docs) {
        final data = doc.data();
        final className = data['class'] as String?;
        final section = data['section'] as String?;

        if (className != null && className.isNotEmpty) {
          classesSet.add(className);
        }
        if (section != null && section.isNotEmpty) {
          sectionsSet.add(section);
        }
      }

      setState(() {
        _availableClasses = classesSet.toList()..sort();
        _availableSections = sectionsSet.toList()..sort();
        _isLoadingFilters = false;
      });
    } catch (e) {
      debugPrint('Error loading filters: $e');
      setState(() => _isLoadingFilters = false);
    }
  }

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
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: "Filter",
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortDialog,
            tooltip: "Sort",
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: "Refresh",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.cyan,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text("Add Student"),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminAddStudentPage(schoolId: widget.schoolId),
            ),
          ).then((_) => setState(() {}));
        },
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_selectedClassFilter != null || _selectedSectionFilter != null)
            _buildActiveFilters(),
          _buildStudentCount(),
          Expanded(
            child: _buildStudentList(),
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
          hintText: "Search by student name or roll number...",
          prefixIcon: const Icon(Icons.search, color: Colors.cyan),
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
            borderSide: const BorderSide(color: Colors.cyan, width: 1),
          ),
        ),
        onChanged: (val) {
          setState(() => _searchQuery = val.toLowerCase());
        },
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.cyan.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          const Icon(Icons.filter_alt, size: 16, color: Colors.cyan),
          const Text("Active Filters:", style: TextStyle(fontSize: 12)),
          if (_selectedClassFilter != null)
            Chip(
              label: Text("Class: $_selectedClassFilter"),
              onDeleted: () => setState(() => _selectedClassFilter = null),
              deleteIcon: const Icon(Icons.close, size: 14),
              backgroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
            ),
          if (_selectedSectionFilter != null)
            Chip(
              label: Text("Section: $_selectedSectionFilter"),
              onDeleted: () => setState(() => _selectedSectionFilter = null),
              deleteIcon: const Icon(Icons.close, size: 14),
              backgroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _buildStudentCount() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('students')
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
              const Icon(Icons.people, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                "$count Student${count != 1 ? 's' : ''}",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStudentList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
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

        var students = snapshot.data!.docs;

        // Apply class filter
        if (_selectedClassFilter != null) {
          students = students.where((s) {
            final data = s.data() as Map<String, dynamic>;
            return data['class'] == _selectedClassFilter;
          }).toList();
        }

        // Apply section filter
        if (_selectedSectionFilter != null) {
          students = students.where((s) {
            final data = s.data() as Map<String, dynamic>;
            return data['section'] == _selectedSectionFilter;
          }).toList();
        }

        // Apply search
        if (_searchQuery.isNotEmpty) {
          students = students.where((s) {
            final data = s.data() as Map<String, dynamic>;
            final name = (data['name'] ?? "").toString().toLowerCase();
            final roll = (data['rollNo'] ?? "").toString().toLowerCase();
            return name.contains(_searchQuery) || roll.contains(_searchQuery);
          }).toList();
        }

        // Apply sorting
        students.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;

          switch (_selectedSortBy) {
            case "Name":
              return (aData['name'] ?? "").compareTo(bData['name'] ?? "");
            case "Roll Number":
              final rollA = int.tryParse(aData['rollNo']?.toString() ?? "0") ?? 0;
              final rollB = int.tryParse(bData['rollNo']?.toString() ?? "0") ?? 0;
              return rollA.compareTo(rollB);
            case "Class":
              final classA = "${aData['class']}${aData['section']}";
              final classB = "${bData['class']}${bData['section']}";
              return classA.compareTo(classB);
            default:
              return 0;
          }
        });

        if (students.isEmpty) {
          return const Center(
            child: Text("No matching students found"),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
            await _loadFilters();
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 90),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final s = students[index];
              final data = s.data() as Map<String, dynamic>;
              final studentId = s.id;

              final name = (data['name'] ?? "No Name").toString();
              final className = (data['class'] ?? "-").toString();
              final section = (data['section'] ?? "-").toString();
              final roll = (data['rollNo'] ?? "-").toString();
              final admissionNo = (data['admissionNo'] ?? "-").toString();

              // Get parent name from parentUid or direct field
              String parentName = "";
              if (data['parentName'] != null) {
                parentName = data['parentName'].toString();
              } else if (data['parent_name'] != null) {
                parentName = data['parent_name'].toString();
              }

              return Dismissible(
                key: Key(studentId),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text("Delete Student"),
                      content: Text("Are you sure you want to delete $name?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context, true);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text("Delete"),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) async {
                  try {
                    // Delete student document
                    await FirebaseFirestore.instance
                        .collection('schools')
                        .doc(widget.schoolId)
                        .collection('students')
                        .doc(studentId)
                        .delete();

                    // Also delete from class subcollection
                    if (className != "-") {
                      await FirebaseFirestore.instance
                          .collection('schools')
                          .doc(widget.schoolId)
                          .collection('classes')
                          .doc(className)
                          .collection('students')
                          .doc(studentId)
                          .delete();
                    }

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("$name deleted successfully"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Error deleting: $e"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    leading: CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.cyan.withValues(alpha: 0.1),
                      child: Text(
                        roll,
                        style: const TextStyle(
                          color: Colors.cyan,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Class $className - $section | Roll: $roll",
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (admissionNo != "-")
                            Text(
                              "Admission No: $admissionNo",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          if (parentName.isNotEmpty)
                            Text(
                              "Parent: $parentName",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20, color: Colors.cyan),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StudentEditPage(
                                  schoolId: widget.schoolId,
                                  studentId: studentId,
                                ),
                              ),
                            ).then((_) => setState(() {}));
                          },
                        ),
                        const Icon(Icons.arrow_forward_ios,
                            size: 16, color: Colors.grey),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudentProfilePage(
                            schoolId: widget.schoolId,
                            studentId: studentId,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text("Filter Students"),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String?>(
                  value: _selectedClassFilter,
                  hint: const Text("All Classes"),
                  decoration: const InputDecoration(
                    labelText: "Class",
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text("All Classes"),
                    ),
                    ..._availableClasses.map((className) {
                      return DropdownMenuItem(
                        value: className,
                        child: Text(className),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedClassFilter = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  value: _selectedSectionFilter,
                  hint: const Text("All Sections"),
                  decoration: const InputDecoration(
                    labelText: "Section",
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text("All Sections"),
                    ),
                    ..._availableSections.map((section) {
                      return DropdownMenuItem(
                        value: section,
                        child: Text(section),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedSectionFilter = value;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedClassFilter = null;
                _selectedSectionFilter = null;
              });
              Navigator.pop(context);
            },
            child: const Text("Clear All"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Apply"),
          ),
        ],
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text("Sort By"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _sortOptions.map((option) {
            return RadioListTile<String>(
              title: Text(option),
              value: option,
              groupValue: _selectedSortBy,
              activeColor: Colors.cyan,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedSortBy = value;
                  });
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No students added yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap the + button to add your first student",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}