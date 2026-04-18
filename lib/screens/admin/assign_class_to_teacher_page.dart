import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app_config.dart';

class AssignClassToTeacherPage extends StatefulWidget {
  final String schoolId;
  final String teacherId;
  final String teacherName;

  const AssignClassToTeacherPage({
    super.key,
    required this.schoolId,
    required this.teacherId,
    this.teacherName = '',
  });

  @override
  State<AssignClassToTeacherPage> createState() =>
      _AssignClassToTeacherPageState();
}

class _AssignClassToTeacherPageState extends State<AssignClassToTeacherPage> {
  final classController = TextEditingController();
  final sectionController = TextEditingController();
  final subjectController = TextEditingController();

  List<Map<String, dynamic>> assigned = [];
  List<String> _availableClasses = [];
  List<String> _availableSections = ['A', 'B', 'C', 'D'];
  List<String> _availableSubjects = [];

  bool _isLoading = true;
  bool _isSaving = false;
  String? _selectedClass;
  String? _selectedSection;
  String? _selectedSubject;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    classController.dispose();
    sectionController.dispose();
    subjectController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load available classes
      final classesSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('classes')
          .get();

      _availableClasses = classesSnapshot.docs
          .map((doc) => doc['className'] as String)
          .toList();

      // Load available subjects
      final subjectsSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('subjects')
          .get();

      if (subjectsSnapshot.docs.isNotEmpty) {
        _availableSubjects = subjectsSnapshot.docs
            .map((doc) => doc['name'] as String)
            .toList();
      } else {
        // Default subjects
        _availableSubjects = [
          'Mathematics', 'Physics', 'Chemistry', 'Biology',
          'English', 'History', 'Geography', 'Computer Science'
        ];
      }

      // Load teacher's existing assignments
      final teacherDoc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('teachers')
          .doc(widget.teacherId)
          .get();

      if (teacherDoc.exists) {
        final data = teacherDoc.data();
        final existingAssignments = data?['assignedClasses'] as List<dynamic>? ?? [];

        setState(() {
          assigned = existingAssignments.map((item) {
            return {
              'class': item['className'] ?? item['class'] ?? '',
              'section': item['section'] ?? '',
              'subject': item['subject'] ?? '',
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text(
          widget.teacherName.isNotEmpty
              ? 'Assign Classes - ${widget.teacherName}'
              : 'Assign Classes to Teacher',
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Teacher Info Card
          _buildTeacherInfoCard(),

          // Assignment Form
          _buildAssignmentForm(),

          const SizedBox(height: 16),

          // Assigned Classes List
          Expanded(
            child: _buildAssignedList(),
          ),

          // Save Button
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildTeacherInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
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
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 35, color: Colors.deepPurple),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Teacher',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  widget.teacherName.isNotEmpty ? widget.teacherName : 'Teacher',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${assigned.length} Classes Assigned',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentForm() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            'Add New Assignment',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Class Dropdown
          _buildClassDropdown(),
          const SizedBox(height: 12),

          // Section Dropdown
          _buildSectionDropdown(),
          const SizedBox(height: 12),

          // Subject Dropdown
          _buildSubjectDropdown(),
          const SizedBox(height: 16),

          // Add Button
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton.icon(
              onPressed: _addAssignment,
              icon: const Icon(Icons.add),
              label: const Text('Add Class'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassDropdown() {
    if (_availableClasses.isEmpty) {
      return TextFormField(
        controller: classController,
        decoration: const InputDecoration(
          labelText: 'Class (e.g., Grade 10)',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.class_),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedClass,
      hint: const Text('Select Class'),
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.class_),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Select Class')),
        ..._availableClasses.map((className) {
          return DropdownMenuItem(
            value: className,
            child: Text(className),
          );
        }).toList(),
      ],
      onChanged: (value) {
        setState(() {
          _selectedClass = value;
          classController.text = value ?? '';
        });
      },
    );
  }

  Widget _buildSectionDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSection,
      hint: const Text('Select Section'),
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.group),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Select Section')),
        ..._availableSections.map((section) {
          return DropdownMenuItem(
            value: section,
            child: Text(section),
          );
        }).toList(),
      ],
      onChanged: (value) {
        setState(() {
          _selectedSection = value;
          sectionController.text = value ?? '';
        });
      },
    );
  }

  Widget _buildSubjectDropdown() {
    if (_availableSubjects.isEmpty) {
      return TextFormField(
        controller: subjectController,
        decoration: const InputDecoration(
          labelText: 'Subject',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.book),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedSubject,
      hint: const Text('Select Subject'),
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.book),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Select Subject')),
        ..._availableSubjects.map((subject) {
          return DropdownMenuItem(
            value: subject,
            child: Text(subject),
          );
        }).toList(),
      ],
      onChanged: (value) {
        setState(() {
          _selectedSubject = value;
          subjectController.text = value ?? '';
        });
      },
    );
  }

  Widget _buildAssignedList() {
    if (assigned.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.class_, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No classes assigned yet',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Use the form above to add classes',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: assigned.length,
      itemBuilder: (context, index) {
        final item = assigned[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple.shade100,
              child: Text(
                '${index + 1}',
                style: TextStyle(color: Colors.deepPurple.shade700),
              ),
            ),
            title: Text(
              '${item['class']} - ${item['section']}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(item['subject'] ?? 'No subject'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                _showDeleteConfirmation(index);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveAssignments,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
              : const Text(
            'Save Assignments',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  void _addAssignment() {
    final className = classController.text.trim();
    final section = sectionController.text.trim();
    final subject = subjectController.text.trim();

    if (className.isEmpty || section.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter class and section'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check for duplicate
    final isDuplicate = assigned.any((item) =>
    item['class'] == className && item['section'] == section);

    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This class-section is already assigned'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      assigned.add({
        'class': className,
        'section': section,
        'subject': subject.isEmpty ? 'General' : subject,
      });
    });

    // Clear form
    classController.clear();
    sectionController.clear();
    subjectController.clear();
    setState(() {
      _selectedClass = null;
      _selectedSection = null;
      _selectedSubject = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Class added to list'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showDeleteConfirmation(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Assignment'),
        content: Text(
          'Remove ${assigned[index]['class']} - ${assigned[index]['section']} from this teacher?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                assigned.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Class removed'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAssignments() async {
    if (assigned.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one class assignment'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Format assignments for Firestore
      final formattedAssignments = assigned.map((item) {
        return {
          'className': item['class'],
          'section': item['section'],
          'subject': item['subject'],
          'assignedAt': FieldValue.serverTimestamp(),
        };
      }).toList();

      // Update teacher document
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('teachers')
          .doc(widget.teacherId)
          .update({
        'assignedClasses': formattedAssignments,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Also update a separate assignments collection for easier querying
      final batch = FirebaseFirestore.instance.batch();

      // Delete existing assignment entries
      final existingAssignments = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('teacher_assignments')
          .where('teacherId', isEqualTo: widget.teacherId)
          .get();

      for (var doc in existingAssignments.docs) {
        batch.delete(doc.reference);
      }

      // Add new assignments
      for (var item in assigned) {
        final assignmentRef = FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolId)
            .collection('teacher_assignments')
            .doc();

        batch.set(assignmentRef, {
          'teacherId': widget.teacherId,
          'teacherName': widget.teacherName,
          'className': item['class'],
          'section': item['section'],
          'subject': item['subject'],
          'assignedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Classes assigned successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving assignments: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}