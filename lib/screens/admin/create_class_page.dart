import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CreateClassPage extends StatefulWidget {
  final String schoolId;

  const CreateClassPage({super.key, required this.schoolId});

  @override
  State<CreateClassPage> createState() => _CreateClassPageState();
}

class _CreateClassPageState extends State<CreateClassPage> {
  final classController = TextEditingController();
  final sectionController = TextEditingController();
  final roomNoController = TextEditingController();

  String? selectedClassTeacher;
  bool loading = false;
  bool _isDuplicate = false;

  List<String> _existingClasses = [];

  @override
  void initState() {
    super.initState();
    _loadExistingClasses();
  }

  @override
  void dispose() {
    classController.dispose();
    sectionController.dispose();
    roomNoController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingClasses() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('classes')
          .get();

      _existingClasses = snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('Error loading existing classes: $e');
    }
  }

  void _checkDuplicate() {
    final className = classController.text.trim();
    final section = sectionController.text.trim().toUpperCase();

    if (className.isNotEmpty && section.isNotEmpty) {
      final classId = "${className}_$section";
      setState(() {
        _isDuplicate = _existingClasses.contains(classId);
      });
    } else {
      setState(() {
        _isDuplicate = false;
      });
    }
  }

  Future<void> createClass() async {
    final className = classController.text.trim();
    final section = sectionController.text.trim().toUpperCase();
    final roomNo = roomNoController.text.trim();

    // Validation
    if (className.isEmpty) {
      _showError("Please enter class name");
      return;
    }

    if (section.isEmpty) {
      _showError("Please enter section");
      return;
    }

    final classId = "${className}_$section";

    // Check for duplicate
    if (_existingClasses.contains(classId)) {
      _showError("Class $className - $section already exists!");
      return;
    }

    setState(() => loading = true);

    try {
      final schoolRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId);

      // Create class document
      await schoolRef
          .collection('classes')
          .doc(classId)
          .set({
        "class": className,
        "section": section,
        "roomNo": roomNo.isEmpty ? null : roomNo,
        "classTeacherId": selectedClassTeacher,
        "subjectTeachers": {},
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
        "isActive": true,
      });

      // Update teacher's assigned classes if a class teacher is selected
      if (selectedClassTeacher != null && selectedClassTeacher!.isNotEmpty) {
        final teacherRef = schoolRef
            .collection('teachers')
            .doc(selectedClassTeacher);

        final teacherDoc = await teacherRef.get();
        if (teacherDoc.exists) {
          List<dynamic> currentAssignments = teacherDoc['assignedClasses'] ?? [];

          // Check if already assigned
          if (!currentAssignments.contains(classId)) {
            await teacherRef.update({
              "assignedClasses": FieldValue.arrayUnion([classId]),
              "updatedAt": FieldValue.serverTimestamp(),
            });
          }
        }
      }

      // Clear form
      classController.clear();
      sectionController.clear();
      roomNoController.clear();
      setState(() {
        selectedClassTeacher = null;
        _isDuplicate = false;
      });

      // Refresh existing classes list
      await _loadExistingClasses();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Class created successfully"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError("Error creating class: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          "Create New Class",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            _buildHeaderCard(),
            const SizedBox(height: 20),

            // Form Card
            _buildFormCard(),
            const SizedBox(height: 20),

            // Info Card
            _buildInfoCard(),
            const SizedBox(height: 24),

            // Create Button
            _buildCreateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.deepPurple, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.add_comment,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Add New Class",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Create a new class with section and assign teacher",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
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

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Class Information",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Class Name Field
          TextField(
            controller: classController,
            onChanged: (_) => _checkDuplicate(),
            decoration: InputDecoration(
              labelText: "Class Name *",
              hintText: "e.g., 10, Grade 10, Class 10",
              prefixIcon: const Icon(Icons.class_, color: Colors.deepPurple),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              errorText: _isDuplicate ? "Class already exists" : null,
            ),
          ),
          const SizedBox(height: 16),

          // Section Field
          TextField(
            controller: sectionController,
            onChanged: (_) => _checkDuplicate(),
            decoration: InputDecoration(
              labelText: "Section *",
              hintText: "e.g., A, B, C",
              prefixIcon: const Icon(Icons.group, color: Colors.deepPurple),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Room Number Field
          TextField(
            controller: roomNoController,
            decoration: InputDecoration(
              labelText: "Room Number (Optional)",
              hintText: "e.g., 101, Ground Floor",
              prefixIcon: const Icon(Icons.meeting_room, color: Colors.deepPurple),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Class Teacher Dropdown
          const Text(
            "Assign Class Teacher",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _buildTeacherDropdown(),

          // Preview Section
          if (classController.text.isNotEmpty && sectionController.text.isNotEmpty && !_isDuplicate)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.preview, color: Colors.deepPurple),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Class ID Preview",
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        Text(
                          "${classController.text}_${sectionController.text.toUpperCase()}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTeacherDropdown() {
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
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "No teachers available. Please add teachers first.",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        }

        final teachers = snapshot.data!.docs;

        return DropdownButtonFormField<String>(
          value: selectedClassTeacher,
          hint: const Text("Select Class Teacher (Optional)"),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.person, color: Colors.deepPurple),
          ),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text("None"),
            ),
            ...teachers.map((doc) {
              final teacherData = doc.data() as Map<String, dynamic>;
              return DropdownMenuItem(
                value: doc.id,
                child: Text(teacherData['name'] ?? 'Unknown'),
              );
            }).toList(),
          ],
          onChanged: (value) {
            setState(() {
              selectedClassTeacher = value;
            });
          },
        );
      },
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Important Note",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "• Class ID will be generated automatically\n• Class Teacher can be assigned later\n• You can add subject teachers after creation",
                  style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    final isValid = classController.text.isNotEmpty &&
        sectionController.text.isNotEmpty &&
        !_isDuplicate;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading || !isValid ? null : createClass,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: loading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : const Text(
          "Create Class",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}