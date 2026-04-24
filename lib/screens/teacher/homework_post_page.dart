import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:schoolprojectjan/app_config.dart';

class HomeworkPostPage extends StatefulWidget {
  const HomeworkPostPage({super.key});

  @override
  State<HomeworkPostPage> createState() => _HomeworkPostPageState();
}

class _HomeworkPostPageState extends State<HomeworkPostPage> {
  final TextEditingController _homeworkController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  String selectedClass = "All Classes";
  String selectedSection = "All Sections";
  String selectedSubject = "Mathematics";
  DateTime? dueDate;
  TimeOfDay? dueTime;
  bool isUrgent = false;
  List<String> attachments = [];

  bool isLoading = false;
  bool isEditing = false;
  String? editingHomeworkId;

  // Data lists
  List<String> classes = [];
  List<String> sections = [];
  List<String> subjects = [];

  @override
  void initState() {
    super.initState();
    _loadClasses();
    _loadSubjects();
  }

  @override
  void dispose() {
    _homeworkController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    try {
      final classesSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('classes')
          .get();

      setState(() {
        classes = ['All Classes', ...classesSnapshot.docs.map((doc) => doc['className'] as String).toList()];
      });
    } catch (e) {
      debugPrint('Error loading classes: $e');
    }
  }

  Future<void> _loadSubjects() async {
    try {
      final subjectsSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('subjects')
          .get();

      if (subjectsSnapshot.docs.isNotEmpty) {
        setState(() {
          subjects = subjectsSnapshot.docs.map((doc) => doc['name'] as String).toList();
        });
      } else {
        // Default subjects
        subjects = ['Mathematics', 'Physics', 'Chemistry', 'Biology', 'English', 'History', 'Geography'];
      }
    } catch (e) {
      debugPrint('Error loading subjects: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(isEditing ? "Edit Homework" : "Post Homework"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteHomework,
              tooltip: "Delete",
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleField(),
            const SizedBox(height: 20),
            _buildHomeworkField(),
            const SizedBox(height: 20),
            _buildClassSelector(),
            const SizedBox(height: 20),
            _buildSubjectSelector(),
            const SizedBox(height: 20),
            _buildDueDatePicker(),
            const SizedBox(height: 16),
            _buildUrgentToggle(),
            const SizedBox(height: 30),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Homework Title *",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: "e.g., Algebra Worksheet",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.title),
          ),
        ),
      ],
    );
  }

  Widget _buildHomeworkField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Homework Details *",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _homeworkController,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: "Enter homework description...\n- Complete exercise 5.1\n- Read chapter 3\n- Prepare for quiz",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClassSelector() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Class *",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: selectedClass,
                items: classes.map((className) {
                  return DropdownMenuItem(
                    value: className,
                    child: Text(className),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedClass = value!;
                    if (selectedClass != "All Classes") {
                      _loadSections(selectedClass);
                    } else {
                      sections = [];
                      selectedSection = "All Sections";
                    }
                  });
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        if (selectedClass != "All Classes" && sections.isNotEmpty)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Section",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedSection,
                  items: [
                    const DropdownMenuItem(value: "All Sections", child: Text("All Sections")),
                    ...sections.map((section) {
                      return DropdownMenuItem(
                        value: section,
                        child: Text(section),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedSection = value!;
                    });
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _loadSections(String className) async {
    try {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('students')
          .where('class', isEqualTo: className)
          .get();

      final sectionsSet = <String>{};
      for (var doc in studentsSnapshot.docs) {
        final section = doc['section'] as String?;
        if (section != null && section.isNotEmpty) {
          sectionsSet.add(section);
        }
      }

      setState(() {
        sections = sectionsSet.toList()..sort();
        if (sections.isNotEmpty) {
          selectedSection = sections.first;
        }
      });
    } catch (e) {
      debugPrint('Error loading sections: $e');
    }
  }

  Widget _buildSubjectSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Subject *",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: selectedSubject,
          items: subjects.map((subject) {
            return DropdownMenuItem(
              value: subject,
              child: Text(subject),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedSubject = value!;
            });
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.book),
          ),
        ),
      ],
    );
  }

  Widget _buildDueDatePicker() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Due Date *",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18, color: Colors.deepPurple),
                      const SizedBox(width: 12),
                      Text(
                        dueDate == null
                            ? "Select due date"
                            : DateFormat("dd MMM yyyy").format(dueDate!),
                        style: TextStyle(
                          color: dueDate == null ? Colors.grey : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Due Time (Optional)",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 18, color: Colors.deepPurple),
                      const SizedBox(width: 12),
                      Text(
                        dueTime == null
                            ? "Select time"
                            : dueTime!.format(context),
                        style: TextStyle(
                          color: dueTime == null ? Colors.grey : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUrgentToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.priority_high, color: Colors.orange),
          const SizedBox(width: 12),
          const Text(
            "Mark as Urgent",
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Switch(
            value: isUrgent,
            onChanged: (value) {
              setState(() {
                isUrgent = value;
              });
            },
            activeThumbColor: Colors.red,
            activeTrackColor: Colors.red.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : _publishHomework,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : Text(isEditing ? "Update Homework" : "Publish Homework"),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => dueDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: dueTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() => dueTime = picked);
    }
  }

  Future<void> _publishHomework() async {
    if (_titleController.text.trim().isEmpty ||
        _homeworkController.text.trim().isEmpty ||
        dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all required fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final teacherUid = FirebaseAuth.instance.currentUser!.uid;

      // Get teacher name
      final teacherDoc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('teachers')
          .where('uid', isEqualTo: teacherUid)
          .limit(1)
          .get();

      String teacherName = "Teacher";
      if (teacherDoc.docs.isNotEmpty) {
        teacherName = teacherDoc.docs.first['name'] ?? "Teacher";
      }

      // Prepare due date timestamp
      DateTime dueDateTime = dueDate!;
      if (dueTime != null) {
        dueDateTime = DateTime(
          dueDate!.year,
          dueDate!.month,
          dueDate!.day,
          dueTime!.hour,
          dueTime!.minute,
        );
      }

      final homeworkData = {
        "title": _titleController.text.trim(),
        "description": _homeworkController.text.trim(),
        "class": selectedClass,
        "section": selectedSection,
        "subject": selectedSubject,
        "dueDate": DateFormat("yyyy-MM-dd").format(dueDate!),
        "dueTime": dueTime != null ? "${dueTime!.hour.toString().padLeft(2, '0')}:${dueTime!.minute.toString().padLeft(2, '0')}" : null,
        "dueDateTime": Timestamp.fromDate(dueDateTime),
        "isUrgent": isUrgent,
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
        "teacherId": teacherUid,
        "teacherName": teacherName,
        "schoolId": AppConfig.schoolId,
      };

      if (isEditing && editingHomeworkId != null) {
        // Update existing homework
        await FirebaseFirestore.instance
            .collection('schools')
            .doc(AppConfig.schoolId)
            .collection('homework')
            .doc(editingHomeworkId)
            .update(homeworkData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Homework updated successfully"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Create new homework
        await FirebaseFirestore.instance
            .collection('schools')
            .doc(AppConfig.schoolId)
            .collection('homework')
            .add(homeworkData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Homework published successfully"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      _clearForm();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Error publishing homework: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _deleteHomework() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Homework"),
        content: const Text("Are you sure you want to delete this homework?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true && editingHomeworkId != null) {
      setState(() => isLoading = true);

      try {
        await FirebaseFirestore.instance
            .collection('schools')
            .doc(AppConfig.schoolId)
            .collection('homework')
            .doc(editingHomeworkId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Homework deleted successfully"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error deleting homework: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    }
  }

  void _clearForm() {
    _titleController.clear();
    _homeworkController.clear();
    setState(() {
      dueDate = null;
      dueTime = null;
      isUrgent = false;
      isEditing = false;
      editingHomeworkId = null;
      selectedClass = "All Classes";
      selectedSection = "All Sections";
      selectedSubject = "Mathematics";
    });
  }
}