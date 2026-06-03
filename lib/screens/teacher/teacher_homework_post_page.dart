import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:schoolprojectjan/app_config.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:schoolprojectjan/services/notification_service.dart';

class TeacherHomeworkPostPage extends StatefulWidget {
  final String? editHomeworkId;
  final Map<String, dynamic>? editData;

  const TeacherHomeworkPostPage({
    super.key,
    this.editHomeworkId,
    this.editData,
  });

  @override
  State<TeacherHomeworkPostPage> createState() =>
      _TeacherHomeworkPostPageState();
}

class _TeacherHomeworkPostPageState extends State<TeacherHomeworkPostPage> {
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
  List<PlatformFile> _selectedFiles = [];
  List<XFile> _selectedImages = [];
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
        if (mounted) {
          setState(() {
            _customSubjects = List<String>.from(doc.data()!['customSubjects']);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading custom subjects: $e');
    }
  }

  Future<void> _loadClasses() async {
    try {
      final studentsSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('students')
              .get();

      final classesSet = <String>{};
      for (var doc in studentsSnapshot.docs) {
        final className = doc['class'] as String?;
        if (className != null && className.isNotEmpty) {
          classesSet.add(className);
        }
      }

      if (mounted) {
        setState(() {
          classes = classesSet.toList()..sort();
        });
      }

      if (classes.isEmpty && mounted) {
        setState(() {
          classes = [
            'LKG',
            'UKG',
            '1',
            '2',
            '3',
            '4',
            '5',
            '6',
            '7',
            '8',
            '9',
            '10',
            '11',
            '12',
          ];
        });
      }
    } catch (e) {
      debugPrint('Error loading classes: $e');
      if (mounted) {
        setState(() {
          classes = [
            'LKG',
            'UKG',
            '1',
            '2',
            '3',
            '4',
            '5',
            '6',
            '7',
            '8',
            '9',
            '10',
            '11',
            '12',
          ];
        });
      }
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

      if (subjectsSnapshot.docs.isNotEmpty && mounted) {
        setState(() {
          subjects =
              subjectsSnapshot.docs
                  .map((doc) => doc['name'] as String)
                  .toList();
        });
      } else if (mounted) {
        setState(() {
          subjects = [
            'Mathematics',
            'Physics',
            'Chemistry',
            'Biology',
            'English',
            'Tamil',
            'Social Science',
            'Computer Science',
            'Physical Education',
            'Art',
            'Music',
            'Hindi',
          ];
        });
      }
    } catch (e) {
      debugPrint('Error loading subjects: $e');
      if (mounted) {
        setState(() {
          subjects = [
            'Mathematics',
            'Physics',
            'Chemistry',
            'Biology',
            'English',
            'Tamil',
            'Social Science',
            'Computer Science',
            'Physical Education',
            'Art',
            'Music',
            'Hindi',
          ];
        });
      }
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

      if (mounted) {
        setState(() {
          sections = sectionsSet.toList()..sort();
        });
      }
    } catch (e) {
      debugPrint('Error loading sections: $e');
    }
  }

  // ============= FILE PICKING METHODS =============
  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null && result.files.isNotEmpty && mounted) {
      setState(() {
        _selectedFiles.addAll(result.files);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${result.files.length} file(s) selected"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _pickImages() async {
    final images = await ImagePicker().pickMultiImage();
    if (images.isNotEmpty && mounted) {
      setState(() {
        _selectedImages.addAll(images);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${images.length} image(s) selected"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _removeSelectedFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  void _removeSelectedImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _removeUploadedFile(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  // ============= FILE UPLOAD METHOD =============
  Future<void> _uploadFiles() async {
    if (_selectedFiles.isEmpty && _selectedImages.isEmpty) return;

    setState(() => _isUploading = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  "Uploading ${_selectedFiles.length + _selectedImages.length} files...",
                ),
              ],
            ),
          ),
    );

    try {
      List<Map<String, dynamic>> uploadedFiles = [];

      // Upload FilePicker files
      for (var file in _selectedFiles) {
        try {
          final fileName =
              '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
          final storageRef = FirebaseStorage.instance.ref().child(
            'homework/$fileName',
          );

          UploadTask uploadTask;
          if (kIsWeb && file.bytes != null) {
            uploadTask = storageRef.putData(file.bytes!);
          } else if (file.path != null) {
            uploadTask = storageRef.putFile(File(file.path!));
          } else {
            continue;
          }

          final snapshot = await uploadTask;
          final downloadUrl = await snapshot.ref.getDownloadURL();

          uploadedFiles.add({
            'name': fileName,
            'originalName': file.name,
            'url': downloadUrl,
            'type': _getFileType(file.name),
            'size': file.size,
          });
        } catch (e) {
          debugPrint('Error uploading file: $e');
        }
      }

      // Upload ImagePicker images
      for (var image in _selectedImages) {
        try {
          final fileName =
              '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
          final storageRef = FirebaseStorage.instance.ref().child(
            'homework/$fileName',
          );

          UploadTask uploadTask;
          if (kIsWeb) {
            final bytes = await image.readAsBytes();
            uploadTask = storageRef.putData(bytes);
          } else {
            uploadTask = storageRef.putFile(File(image.path));
          }

          final snapshot = await uploadTask;
          final downloadUrl = await snapshot.ref.getDownloadURL();

          uploadedFiles.add({
            'name': fileName,
            'originalName': image.name,
            'url': downloadUrl,
            'type': 'image',
            'size': await image.length(),
          });
        } catch (e) {
          debugPrint('Error uploading image: $e');
        }
      }

      Navigator.pop(context);

      if (mounted && uploadedFiles.isNotEmpty) {
        setState(() {
          _attachments.addAll(uploadedFiles);
          _selectedFiles.clear();
          _selectedImages.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${uploadedFiles.length} file(s) uploaded successfully",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error uploading files: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  String _getFileType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    const images = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'];
    const pdfs = ['pdf'];
    const docs = ['doc', 'docx', 'txt', 'xls', 'xlsx', 'ppt', 'pptx'];

    if (images.contains(extension)) return 'image';
    if (pdfs.contains(extension)) return 'pdf';
    if (docs.contains(extension)) return 'document';
    return 'other';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
          isEditing ? "Edit Homework" : "Post New Homework",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
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
            _buildHeaderCard(),
            const SizedBox(height: 16),
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

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.deepPurple, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.assignment, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Create Homework",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Assign homework to your students",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Homework Title",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
                borderSide: BorderSide(color: Colors.deepPurple, width: 2),
              ),
              prefixIcon: const Icon(Icons.title, color: Colors.deepPurple),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeworkField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Homework Details",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
                borderSide: BorderSide(color: Colors.deepPurple, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Attachments",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
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

          if (_selectedImages.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              "Selected Images:",
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
            const SizedBox(height: 8),
            ..._selectedImages.asMap().entries.map((entry) {
              final index = entry.key;
              final image = entry.value;
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
                    const Icon(Icons.image, size: 20, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        image.name,
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
                      onPressed: () => _removeSelectedImage(index),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],

          if (_selectedFiles.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              "Selected Files:",
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
            const SizedBox(height: 8),
            ..._selectedFiles.asMap().entries.map((entry) {
              final index = entry.key;
              final file = entry.value;
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
                    const Icon(
                      Icons.insert_drive_file,
                      size: 20,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _formatFileSize(file.size),
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
                        Icons.close,
                        size: 16,
                        color: Colors.red,
                      ),
                      onPressed: () => _removeSelectedFile(index),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],

          if (_selectedImages.isNotEmpty || _selectedFiles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
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
                          : Text(
                            "Upload ${_selectedImages.length + _selectedFiles.length} File(s)",
                          ),
                ),
              ),
            ),

          if (_attachments.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              "Uploaded Attachments:",
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
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
                  color: isImage ? Colors.green.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isImage ? Icons.image : Icons.insert_drive_file,
                      size: 20,
                      color: isImage ? Colors.green : Colors.blue,
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
                          if (attachment['size'] != null)
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

          if (_selectedImages.isEmpty &&
              _selectedFiles.isEmpty &&
              _attachments.isEmpty)
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

  Widget _buildClassSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Class & Section",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedClass.isEmpty ? null : selectedClass,
                  hint: const Text("Select Class"),
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text("Select Class"),
                    ),
                    ...classes.map(
                      (className) => DropdownMenuItem(
                        value: className,
                        child: Text(className),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedClass = value;
                        selectedSection = "";
                        _loadSections(selectedClass);
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedSection.isEmpty ? null : selectedSection,
                  hint: const Text("Select Section"),
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text("Select Section"),
                    ),
                    ...sections.map(
                      (section) => DropdownMenuItem(
                        value: section,
                        child: Text("Section $section"),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => selectedSection = value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Subject",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedSubject,
            isExpanded: true,
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              prefixIcon: const Icon(Icons.book, color: Colors.deepPurple),
            ),
            items:
                allSubjects
                    .map(
                      (subject) => DropdownMenuItem(
                        value: subject,
                        child: Text(subject),
                      ),
                    )
                    .toList(),
            onChanged: (value) => setState(() => selectedSubject = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildDueDatePicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Due Date & Time",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
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
                          size: 18,
                          color: Colors.deepPurple,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dueDate == null
                              ? "Select date"
                              : DateFormat("dd MMM yyyy").format(dueDate!),
                          style: TextStyle(
                            fontSize: 13,
                            color: dueDate == null ? Colors.grey : Colors.black,
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
                      horizontal: 12,
                      vertical: 12,
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
                          size: 18,
                          color: Colors.deepPurple,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dueTime == null
                              ? "Select time"
                              : dueTime!.format(context),
                          style: TextStyle(
                            fontSize: 13,
                            color: dueTime == null ? Colors.grey : Colors.black,
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
      ),
    );
  }

  Widget _buildUrgentToggle() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isUrgent ? Colors.red.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.priority_high,
              color: isUrgent ? Colors.red : Colors.grey,
              size: 20,
            ),
          ),
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
    if (picked != null && mounted) setState(() => dueDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: dueTime ?? const TimeOfDay(hour: 16, minute: 0),
    );
    if (picked != null && mounted) setState(() => dueTime = picked);
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

      String homeworkId;

      if (isEditing && editingHomeworkId != null) {
        await FirebaseFirestore.instance
            .collection('schools')
            .doc(AppConfig.schoolId)
            .collection('homework')
            .doc(editingHomeworkId)
            .update(homeworkData);
        homeworkId = editingHomeworkId!;
        _showSuccess("Homework updated successfully");
      } else {
        final docRef = await FirebaseFirestore.instance
            .collection('schools')
            .doc(AppConfig.schoolId)
            .collection('homework')
            .add(homeworkData);
        homeworkId = docRef.id;
        _showSuccess("Homework published successfully");
      }

      // Send notifications
      await _sendHomeworkNotifications(
        homeworkId: homeworkId,
        title: _titleController.text.trim(),
        description: _homeworkController.text.trim(),
        className: selectedClass,
        section: selectedSection,
        subject: selectedSubject,
        dueDate: dueDateTime,
        isUrgent: isUrgent,
      );

      _clearForm();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showError("Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _sendHomeworkNotifications({
    required String homeworkId,
    required String title,
    required String description,
    required String className,
    required String section,
    required String subject,
    required DateTime dueDate,
    required bool isUrgent,
  }) async {
    try {
      final studentsSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('students')
              .where('class', isEqualTo: className)
              .where('section', isEqualTo: section)
              .get();

      if (studentsSnapshot.docs.isEmpty) {
        print('No students found in class $className-$section');
        return;
      }

      final formattedDueDate = DateFormat('dd MMM yyyy').format(dueDate);
      final urgencyPrefix = isUrgent ? '🔴 URGENT: ' : '📚 ';
      final notificationTitle = "$urgencyPrefix$title";

      String notificationBody =
          description.length > 100
              ? '${description.substring(0, 100)}...'
              : description;
      notificationBody =
          "$subject - $notificationBody (Due: $formattedDueDate)";

      int notificationCount = 0;

      for (var studentDoc in studentsSnapshot.docs) {
        final studentData = studentDoc.data();
        final studentId = studentDoc.id;
        final parentUid = studentData['parentUID'] ?? studentData['parentUid'];
        final studentName = studentData['name'] ?? 'Student';

        if (parentUid != null && parentUid.isNotEmpty) {
          await NotificationService.sendToUser(
            userId: parentUid,
            title: notificationTitle,
            body: notificationBody,
            type: 'homework',
            data: {
              'homeworkId': homeworkId,
              'title': title,
              'subject': subject,
              'dueDate': dueDate.toIso8601String(),
              'className': className,
              'section': section,
              'studentId': studentId,
              'studentName': studentName,
              'isUrgent': isUrgent,
            },
          );

          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('notifications')
              .add({
                'studentId': studentId,
                'title': notificationTitle,
                'message': notificationBody,
                'type': 'homework',
                'isRead': false,
                'createdAt': FieldValue.serverTimestamp(),
                'deletedFor': [],
                'additionalData': {
                  'homeworkId': homeworkId,
                  'subject': subject,
                  'dueDate': dueDate.toIso8601String(),
                  'isUrgent': isUrgent,
                },
              });

          notificationCount++;
        }
      }

      print('✅ Homework notifications sent to $notificationCount parents');
    } catch (e) {
      print('Error sending homework notifications: $e');
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
      _selectedFiles.clear();
      _selectedImages.clear();
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

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
