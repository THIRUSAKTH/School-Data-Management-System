import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:schoolprojectjan/app_config.dart';
import 'package:schoolprojectjan/services/file_picker_service.dart';

class HomeworkPostPage extends StatefulWidget {
  final String? editHomeworkId;
  final Map<String, dynamic>? editData;

  const HomeworkPostPage({super.key, this.editHomeworkId, this.editData});

  @override
  State<HomeworkPostPage> createState() => _HomeworkPostPageState();
}

class _HomeworkPostPageState extends State<HomeworkPostPage> {
  final TextEditingController _homeworkController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  String selectedClass = "";
  String selectedSection = "";
  String selectedSubject = "Mathematics";
  DateTime? dueDate;
  TimeOfDay? dueTime;
  bool isUrgent = false;

  // File attachments
  List<Map<String, dynamic>> _attachments = [];
  List<File> _localFiles = [];
  bool _isUploading = false;

  bool isLoading = false;
  bool isEditing = false;
  String? editingHomeworkId;

  // Data lists
  List<String> classes = [];
  List<String> sections = [];
  List<String> subjects = [];
  List<String> _customSubjects = [];

  List<String> get allSubjects => [...subjects, ..._customSubjects];

  @override
  void initState() {
    super.initState();
    _loadClasses();
    _loadSubjects();
    _loadCustomSubjects();

    if (widget.editHomeworkId != null && widget.editData != null) {
      isEditing = true;
      editingHomeworkId = widget.editHomeworkId;
      _loadHomeworkData(widget.editData!);
    }
  }

  void _loadHomeworkData(Map<String, dynamic> data) {
    _titleController.text = data['title'] ?? '';
    _homeworkController.text = data['description'] ?? '';
    selectedClass = data['className'] ?? '';
    selectedSection = data['section'] ?? '';
    selectedSubject = data['subject'] ?? 'Mathematics';
    isUrgent = data['isUrgent'] ?? false;

    // Load existing attachments
    if (data['attachments'] != null) {
      _attachments = List<Map<String, dynamic>>.from(data['attachments']);
    }

    if (data['dueDate'] != null) {
      if (data['dueDate'] is Timestamp) {
        dueDate = (data['dueDate'] as Timestamp).toDate();
      } else if (data['dueDate'] is DateTime) {
        dueDate = data['dueDate'];
      }
    }

    if (data['dueTime'] != null && data['dueTime'] is String) {
      final timeParts = data['dueTime'].split(':');
      if (timeParts.length == 2) {
        dueTime = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
      }
    }

    if (selectedClass.isNotEmpty) {
      _loadSections(selectedClass);
    }
  }

  Future<void> _loadCustomSubjects() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('settings')
              .doc('subjects')
              .get();

      if (doc.exists && doc.data()?['customSubjects'] != null) {
        setState(() {
          _customSubjects = List<String>.from(doc.data()!['customSubjects']);
        });
      }
    } catch (e) {
      debugPrint('Error loading custom subjects: $e');
    }
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
        classes =
            classesSnapshot.docs
                .map(
                  (doc) =>
                      doc['className'] as String? ??
                      doc['class'] as String? ??
                      '',
                )
                .where((name) => name.isNotEmpty)
                .toList();
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
      });
    } catch (e) {
      debugPrint('Error loading sections: $e');
    }
  }

  // File attachment methods
  Future<void> _pickFiles() async {
    final files = await FilePickerService.pickFiles(allowMultiple: true);
    if (files.isNotEmpty) {
      setState(() {
        _localFiles.addAll(files);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${files.length} file(s) selected"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _pickImages() async {
    final images = await FilePickerService.pickImages(allowMultiple: true);
    if (images.isNotEmpty) {
      setState(() {
        _localFiles.addAll(images);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${images.length} image(s) selected"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _removeLocalFile(int index) {
    setState(() {
      _localFiles.removeAt(index);
    });
  }

  void _removeUploadedFile(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Future<void> _uploadFiles() async {
    if (_localFiles.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      final uploadedFiles = await FilePickerService.uploadMultipleFiles(
        files: _localFiles,
        folder: 'homework',
      );

      setState(() {
        _attachments.addAll(uploadedFiles);
        _localFiles.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${uploadedFiles.length} file(s) uploaded successfully",
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error uploading files: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _homeworkController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
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
            _buildAttachmentsCard(),
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

  Widget _buildAttachmentsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Attachments",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Upload buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUploading ? null : _pickImages,
                  icon: const Icon(Icons.image),
                  label: const Text("Add Images"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUploading ? null : _pickFiles,
                  icon: const Icon(Icons.attach_file),
                  label: const Text("Add Files"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Local files (not yet uploaded)
          if (_localFiles.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              "Pending Upload:",
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ..._localFiles.asMap().entries.map((entry) {
              final index = entry.key;
              final file = entry.value;
              final fileName = file.path.split('/').last;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.insert_drive_file, size: 20, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.red,
                      ),
                      onPressed: () => _removeLocalFile(index),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadFiles,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isUploading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Text("Upload ${_localFiles.length} File(s)"),
              ),
            ),
          ],

          // Uploaded files
          if (_attachments.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              "Uploaded Attachments:",
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ..._attachments.asMap().entries.map((entry) {
              final index = entry.key;
              final attachment = entry.value;
              final isImage = attachment['type'] == 'image';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isImage ? Icons.image : Icons.insert_drive_file,
                      size: 20,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            attachment['originalName'] ?? attachment['name'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _formatFileSize(attachment['size']),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Colors.red,
                      ),
                      onPressed: () => _removeUploadedFile(index),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],

          if (_localFiles.isEmpty && _attachments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  "No attachments added",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
          value: selectedClass.isEmpty ? null : selectedClass,
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
              classes
                  .map(
                    (className) => DropdownMenuItem(
                      value: className,
                      child: Text(className),
                    ),
                  )
                  .toList(),
          onChanged: (value) {
            setState(() {
              selectedClass = value!;
              selectedSection = "";
              _loadSections(selectedClass);
            });
          },
        ),
        if (selectedClass.isNotEmpty && sections.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Section *",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedSection.isEmpty ? null : selectedSection,
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
                  items:
                      sections
                          .map(
                            (section) => DropdownMenuItem(
                              value: section,
                              child: Text("Section $section"),
                            ),
                          )
                          .toList(),
                  onChanged:
                      (value) => setState(() => selectedSection = value!),
                ),
              ],
            ),
          ),
        if (selectedClass.isNotEmpty && sections.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              "No sections found for this class",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
      ],
    );
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
              allSubjects
                  .map(
                    (subject) =>
                        DropdownMenuItem(value: subject, child: Text(subject)),
                  )
                  .toList(),
          onChanged: (value) => setState(() => selectedSubject = value!),
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
            onChanged: (value) => setState(() => isUrgent = value),
            activeColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isValid =
        _titleController.text.trim().isNotEmpty &&
        _homeworkController.text.trim().isNotEmpty &&
        selectedClass.isNotEmpty &&
        selectedSection.isNotEmpty &&
        dueDate != null;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading || !isValid ? null : _publishHomework,
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
    if (selectedClass.isEmpty) {
      _showError("Please select a class");
      return;
    }
    if (selectedSection.isEmpty) {
      _showError("Please select a section");
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
              .where('uid', isEqualTo: teacherUid)
              .get();

      String teacherName = "Teacher";
      if (teacherDoc.docs.isNotEmpty) {
        teacherName = teacherDoc.docs.first.data()['name'] ?? "Teacher";
      }

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
        "attachments": _attachments,
        "schoolId": AppConfig.schoolId,
        "isActive": true,
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
      if (mounted) Navigator.pop(context, true);
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
              "Are you sure you want to delete this homework? This cannot be undone.",
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
        if (mounted) Navigator.pop(context, true);
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
      selectedClass = "";
      selectedSection = "";
      selectedSubject = "Mathematics";
      _attachments.clear();
      _localFiles.clear();
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
