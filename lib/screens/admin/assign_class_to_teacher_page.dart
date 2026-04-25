import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _sectionController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();

  List<Map<String, dynamic>> _assigned = [];
  List<String> _availableClasses = [];
  List<String> _availableSections = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
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
    _classController.dispose();
    _sectionController.dispose();
    _subjectController.dispose();
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
          .map((doc) {
        final data = doc.data();
        return (data['class'] as String?) ?? (data['className'] as String?) ?? '';
      })
          .where((name) => name.isNotEmpty)
          .toList();

      // Load available subjects
      final subjectsSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('subjects')
          .get();

      if (subjectsSnapshot.docs.isNotEmpty) {
        _availableSubjects = subjectsSnapshot.docs
            .map((doc) {
          final data = doc.data();
          return data['name'] as String? ?? '';
        })
            .where((name) => name.isNotEmpty)
            .toList();
      } else {
        // Default subjects
        _availableSubjects = [
          'Mathematics', 'Physics', 'Chemistry', 'Biology',
          'English', 'History', 'Geography', 'Computer Science',
          'Tamil', 'Hindi', 'Physical Education', 'Art',
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
          _assigned = existingAssignments.map((item) {
            final itemMap = item as Map<String, dynamic>;
            return {
              'class': itemMap['className'] ?? itemMap['class'] ?? '',
              'section': itemMap['section'] ?? '',
              'subject': itemMap['subject'] ?? '',
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
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
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: "Refresh",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildTeacherInfoCard(),
          _buildAssignmentForm(),
          const SizedBox(height: 16),
          Expanded(
            child: _buildAssignedList(),
          ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
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
                  '${_assigned.length} Class${_assigned.length != 1 ? 'es' : ''} Assigned',
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
          _buildClassDropdown(),
          const SizedBox(height: 12),
          _buildSectionDropdown(),
          const SizedBox(height: 12),
          _buildSubjectDropdown(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton.icon(
              onPressed: _addAssignment,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Class', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
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
        controller: _classController,
        decoration: const InputDecoration(
          labelText: 'Class (e.g., Grade 10, Class 5)',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.class_),
          hintText: 'Enter class name',
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedClass,
      hint: const Text('Select Class'),
      isExpanded: true,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.class_),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('Select Class'),
        ),
        ..._availableClasses.map((className) {
          return DropdownMenuItem<String>(
            value: className,
            child: Text(className),
          );
        }).toList(),
      ],
      onChanged: (value) {
        setState(() {
          _selectedClass = value;
          _classController.text = value ?? '';
        });
      },
    );
  }

  Widget _buildSectionDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSection,
      hint: const Text('Select Section'),
      isExpanded: true,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.group),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('Select Section'),
        ),
        ..._availableSections.map((section) {
          return DropdownMenuItem<String>(
            value: section,
            child: Text(section),
          );
        }).toList(),
      ],
      onChanged: (value) {
        setState(() {
          _selectedSection = value;
          _sectionController.text = value ?? '';
        });
      },
    );
  }

  Widget _buildSubjectDropdown() {
    if (_availableSubjects.isEmpty) {
      return TextFormField(
        controller: _subjectController,
        decoration: const InputDecoration(
          labelText: 'Subject',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.book),
          hintText: 'Enter subject name',
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedSubject,
      hint: const Text('Select Subject'),
      isExpanded: true,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.book),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('Select Subject'),
        ),
        ..._availableSubjects.map((subject) {
          return DropdownMenuItem<String>(
            value: subject,
            child: Text(subject),
          );
        }).toList(),
      ],
      onChanged: (value) {
        setState(() {
          _selectedSubject = value;
          _subjectController.text = value ?? '';
        });
      },
    );
  }

  Widget _buildAssignedList() {
    if (_assigned.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.class_, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No classes assigned yet',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Use the form above to add classes',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _assigned.length,
      itemBuilder: (context, index) {
        final item = _assigned[index];
        return Dismissible(
          key: Key('${item['class']}_${item['section']}_$index'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await _showDeleteConfirmation(index);
          },
          child: Card(
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
                  style: TextStyle(
                    color: Colors.deepPurple.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                '${item['class']} - ${item['section']}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(item['subject'] ?? 'No subject'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () async {
                  final confirm = await _showDeleteConfirmation(index);
                  if (confirm == true) {
                    setState(() {
                      _assigned.removeAt(index);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Class removed'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
              ),
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
            elevation: 2,
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
    final className = _classController.text.trim();
    final section = _sectionController.text.trim();
    final subject = _subjectController.text.trim();

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
    final isDuplicate = _assigned.any(
          (item) => item['class'] == className && item['section'] == section,
    );

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
      _assigned.add({
        'class': className,
        'section': section,
        'subject': subject.isEmpty ? 'General' : subject,
      });
    });

    // Clear form
    _classController.clear();
    _sectionController.clear();
    _subjectController.clear();
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

  Future<bool?> _showDeleteConfirmation(int index) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Remove Assignment'),
        content: Text(
          'Remove ${_assigned[index]['class']} - ${_assigned[index]['section']} from this teacher?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAssignments() async {
    if (_assigned.isEmpty) {
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
      final formattedAssignments = _assigned.map((item) {
        return {
          'className': item['class'],
          'section': item['section'],
          'subject': item['subject'],
          'assignedAt': FieldValue.serverTimestamp(),
        };
      }).toList();

      await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('teachers')
          .doc(widget.teacherId)
          .update({
        'assignedClasses': formattedAssignments,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Classes assigned successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
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