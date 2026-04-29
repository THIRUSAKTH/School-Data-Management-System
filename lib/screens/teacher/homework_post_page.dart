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
  List<Map<String, dynamic>> attachments = [];

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
      final classesSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('classes')
              .get();

      setState(() {
        classes = [
          'All Classes',
          ...classesSnapshot.docs
              .map((doc) => doc['className'] as String)
              .toList(),
        ];
      });
    } catch (e) {
      debugPrint('Error loading classes: $e');
    }
  }

  Future<void> _loadSubjects() async {
    try {
      final subjectsSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('subjects')
              .get();

      if (subjectsSnapshot.docs.isNotEmpty) {
        setState(() {
          subjects =
              subjectsSnapshot.docs
                  .map((doc) => doc['name'] as String)
                  .toList();
        });
      } else {
        subjects = [
          'Mathematics',
          'Physics',
          'Chemistry',
          'Biology',
          'English',
          'History',
          'Geography',
          'Computer Science',
          'Tamil',
          'Hindi',
          'Physical Education',
          'Art',
        ];
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
        title: Text(
          isEditing ? "Edit Homework" : "Post Homework",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: false,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
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
            const SizedBox(height: 16),
            _buildHomeworkField(),
            const SizedBox(height: 16),
            _buildClassSelector(),
            const SizedBox(height: 16),
            _buildSubjectSelector(),
            const SizedBox(height: 16),
            _buildDueDatePicker(),
            const SizedBox(height: 12),
            _buildUrgentToggle(),
            const SizedBox(height: 24),
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
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: "e.g., Algebra Worksheet, Chapter 5 Questions",
            hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
            ),
            prefixIcon: const Icon(Icons.title, color: Colors.deepPurple),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          style: const TextStyle(fontSize: 14),
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
        const SizedBox(height: 8),
        TextField(
          controller: _homeworkController,
          maxLines: 6,
          decoration: InputDecoration(
            hintText:
                "Enter detailed homework description...\n\nExample:\n• Complete exercise 5.2 from textbook\n• Write 10 sentences about your hobby\n• Practice multiplication tables 2-10",
            hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            alignLabelWithHint: true,
          ),
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildClassSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Class *",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedClass,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            prefixIcon: const Icon(Icons.class_, color: Colors.deepPurple),
          ),
          items:
              classes.map((className) {
                return DropdownMenuItem(
                  value: className,
                  child: Text(className, style: const TextStyle(fontSize: 14)),
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
        ),
        if (selectedClass != "All Classes" && sections.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Section",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedSection,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.deepPurple,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.group,
                      color: Colors.deepPurple,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: "All Sections",
                      child: Text("All Sections"),
                    ),
                    ...sections.map((section) {
                      return DropdownMenuItem(
                        value: section,
                        child: Text(
                          section,
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedSection = value!;
                    });
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _loadSections(String className) async {
    try {
      final studentsSnapshot =
          await FirebaseFirestore.instance
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
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedSubject,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            prefixIcon: const Icon(Icons.book, color: Colors.deepPurple),
          ),
          items:
              subjects.map((subject) {
                return DropdownMenuItem(
                  value: subject,
                  child: Text(subject, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
          onChanged: (value) {
            setState(() {
              selectedSubject = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDueDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Due Date & Time *",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          dueDate == null
                              ? "Select due date"
                              : DateFormat("dd MMM yyyy").format(dueDate!),
                          style: TextStyle(
                            fontSize: 14,
                            color: dueDate == null ? Colors.grey : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: _pickTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 20,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          dueTime == null
                              ? "Select time"
                              : dueTime!.format(context),
                          style: TextStyle(
                            fontSize: 14,
                            color: dueTime == null ? Colors.grey : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUrgentToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.priority_high, color: Colors.orange, size: 22),
          const SizedBox(width: 12),
          const Text(
            "Mark as Urgent",
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          const Spacer(),
          Switch(
            value: isUrgent,
            onChanged: (value) {
              setState(() {
                isUrgent = value;
              });
            },
            activeColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : _publishHomework,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child:
            isLoading
                ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : Text(
                  isEditing ? "Update Homework" : "Publish Homework",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dueDate ?? DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => dueDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: dueTime ?? const TimeOfDay(hour: 16, minute: 0),
    );
    if (picked != null) setState(() => dueTime = picked);
  }

  Future<void> _publishHomework() async {
    if (_titleController.text.trim().isEmpty) {
      _showError("Please enter homework title");
      return;
    }
    if (_homeworkController.text.trim().isEmpty) {
      _showError("Please enter homework description");
      return;
    }
    if (dueDate == null) {
      _showError("Please select due date");
      return;
    }

    setState(() => isLoading = true);

    try {
      final teacherUid = FirebaseAuth.instance.currentUser!.uid;

      final teacherDoc =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('teachers')
              .doc(teacherUid)
              .get();

      String teacherName =
          teacherDoc.exists ? (teacherDoc['name'] ?? "Teacher") : "Teacher";

      final dueDateTime = DateTime(
        dueDate!.year,
        dueDate!.month,
        dueDate!.day,
        dueTime?.hour ?? 23,
        dueTime?.minute ?? 59,
      );

      final homeworkData = {
        "title": _titleController.text.trim(),
        "description": _homeworkController.text.trim(),
        "className": selectedClass,
        "section": selectedSection,
        "subject": selectedSubject,
        "dueDate": Timestamp.fromDate(dueDateTime),
        "dueTime":
            dueTime != null
                ? "${dueTime!.hour.toString().padLeft(2, '0')}:${dueTime!.minute.toString().padLeft(2, '0')}"
                : null,
        "isUrgent": isUrgent,
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
        "teacherId": teacherUid,
        "teacherName": teacherName,
        "submittedBy": [],
        "attachments": attachments,
        "schoolId": AppConfig.schoolId,
      };

      if (isEditing && editingHomeworkId != null) {
        await FirebaseFirestore.instance
            .collection('schools')
            .doc(AppConfig.schoolId)
            .collection('homework')
            .doc(editingHomeworkId)
            .update(homeworkData);
        _showSuccess("Homework updated successfully");
      } else {
        await FirebaseFirestore.instance
            .collection('schools')
            .doc(AppConfig.schoolId)
            .collection('homework')
            .add(homeworkData);
        _showSuccess("Homework published successfully");
      }

      _clearForm();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError("Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _deleteHomework() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text("Delete Homework"),
            content: const Text(
              "Are you sure you want to delete this homework?",
            ),
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
        _showSuccess("Homework deleted successfully");
        if (mounted) Navigator.pop(context);
      } catch (e) {
        _showError("Error deleting homework: $e");
      } finally {
        if (mounted) setState(() => isLoading = false);
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }
}
