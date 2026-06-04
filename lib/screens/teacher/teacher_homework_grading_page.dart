import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:schoolprojectjan/app_config.dart';

class TeacherHomeworkGradingPage extends StatefulWidget {
  final String homeworkId;
  final String studentId;
  final String studentName;
  final String className;
  final String section;

  const TeacherHomeworkGradingPage({
    super.key,
    required this.homeworkId,
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.section,
  });

  @override
  State<TeacherHomeworkGradingPage> createState() =>
      _TeacherHomeworkGradingPageState();
}

class _TeacherHomeworkGradingPageState
    extends State<TeacherHomeworkGradingPage> {
  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  bool _isSaving = false;
  Map<String, dynamic>? _submissionData;
  String _selectedGradeOption = '';
  bool _isCompleted = false;

  final List<String> _gradeOptions = [
    'A+ (90-100%)',
    'A (80-89%)',
    'B+ (75-79%)',
    'B (70-74%)',
    'C+ (65-69%)',
    'C (60-64%)',
    'D (50-59%)',
    'F (Below 50%)',
    'Pass',
    'Excellent',
    'Very Good',
    'Good',
    'Satisfactory',
    'Needs Improvement',
  ];

  @override
  void initState() {
    super.initState();
    _loadSubmission();
  }

  Future<void> _loadSubmission() async {
    try {
      final homeworkDoc =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('homework')
              .doc(widget.homeworkId)
              .get();

      if (homeworkDoc.exists) {
        final data = homeworkDoc.data() as Map<String, dynamic>;
        final submittedBy = List<String>.from(data['submittedBy'] ?? []);
        _isCompleted = submittedBy.contains(widget.studentId);

        final submissionDetails =
            data['submissionDetails'] as List<dynamic>? ?? [];
        final submission = submissionDetails.firstWhere(
          (detail) => detail['studentId'] == widget.studentId,
          orElse: () => {},
        );

        if (submission.isNotEmpty) {
          _selectedGradeOption = submission['grade'] ?? '';
          _feedbackController.text = submission['teacherRemarks'] ?? '';
          _remarksController.text = submission['remarks'] ?? '';
        }
      }

      setState(() {});
    } catch (e) {
      debugPrint('Error loading submission: $e');
    }
  }

  Future<void> _saveGrade() async {
    if (!_isCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Student hasn't submitted the homework yet!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedGradeOption.isEmpty && _gradeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a grade"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final homeworkRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('homework')
          .doc(widget.homeworkId);

      final homeworkDoc = await homeworkRef.get();
      final existingDetails = List<Map<String, dynamic>>.from(
        homeworkDoc.data()?['submissionDetails'] ?? [],
      );

      final gradeValue =
          _selectedGradeOption.isNotEmpty
              ? _selectedGradeOption
              : _gradeController.text.trim();

      final existingIndex = existingDetails.indexWhere(
        (detail) => detail['studentId'] == widget.studentId,
      );

      final submissionDetail = {
        'studentId': widget.studentId,
        'studentName': widget.studentName,
        'className': widget.className,
        'section': widget.section,
        'grade': gradeValue,
        'teacherRemarks': _feedbackController.text.trim(),
        'remarks': _remarksController.text.trim(),
        'gradedAt': FieldValue.serverTimestamp(),
        'gradedBy': FirebaseAuth.instance.currentUser?.uid,
        'gradedByName':
            FirebaseAuth.instance.currentUser?.displayName ?? 'Teacher',
      };

      if (existingIndex != -1) {
        existingDetails[existingIndex] = submissionDetail;
      } else {
        existingDetails.add(submissionDetail);
      }

      await homeworkRef.update({'submissionDetails': existingDetails});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Grade saved successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text("Grade - ${widget.studentName}"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isCompleted)
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.white),
              onPressed: null,
              tooltip: "Submitted",
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildGradeSelector(),
            const SizedBox(height: 16),
            _buildCustomGradeField(),
            const SizedBox(height: 16),
            _buildFeedbackField(),
            const SizedBox(height: 16),
            _buildStudentRemarksField(),
            const SizedBox(height: 30),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isCompleted ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isCompleted ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isCompleted ? Icons.check_circle : Icons.pending,
            color: _isCompleted ? Colors.green : Colors.orange,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isCompleted ? "Homework Submitted" : "Pending Submission",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color:
                        _isCompleted
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                  ),
                ),
                if (!_isCompleted)
                  Text(
                    "Student hasn't submitted yet. You can save grade for later.",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange.shade600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select Grade",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _gradeOptions.map((grade) {
                  final isSelected = _selectedGradeOption == grade;
                  return FilterChip(
                    label: Text(grade),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedGradeOption = grade;
                          _gradeController.clear();
                        } else if (_selectedGradeOption == grade) {
                          _selectedGradeOption = '';
                        }
                      });
                    },
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: Colors.deepPurple.shade100,
                    checkmarkColor: Colors.deepPurple,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.deepPurple : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomGradeField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Or Enter Custom Grade",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _gradeController,
            enabled: _selectedGradeOption.isEmpty,
            decoration: InputDecoration(
              hintText: "e.g., 85%, A, Excellent, Pass",
              prefixIcon: const Icon(Icons.grade, color: Colors.deepPurple),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
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
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                setState(() => _selectedGradeOption = '');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Teacher Feedback",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _feedbackController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
                  "Write constructive feedback for the student...\n\nExamples:\n• Great work! Keep it up!\n• Good effort, but please check the calculations.\n• Excellent presentation and clear explanations.",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentRemarksField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Student Remarks (if any)",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _remarksController,
            maxLines: 2,
            readOnly: true,
            decoration: InputDecoration(
              hintText: "Student's remarks will appear here",
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final hasGrade =
        _selectedGradeOption.isNotEmpty ||
        _gradeController.text.trim().isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveGrade,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child:
            _isSaving
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      hasGrade ? "Save Grade" : "Save as Draft",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
