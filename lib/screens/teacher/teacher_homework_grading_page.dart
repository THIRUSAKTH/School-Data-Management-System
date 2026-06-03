import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:schoolprojectjan/app_config.dart';

class TeacherHomeworkGradingPage extends StatefulWidget {
  final String homeworkId;
  final String studentId;
  final String studentName;

  const TeacherHomeworkGradingPage({
    super.key,
    required this.homeworkId,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<TeacherHomeworkGradingPage> createState() =>
      _TeacherHomeworkGradingPageState();
}

class _TeacherHomeworkGradingPageState extends State<TeacherHomeworkGradingPage> {
  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();
  int _selectedGrade = 0;
  bool _isSaving = false;
  Map<String, dynamic>? _submissionData;

  @override
  void initState() {
    super.initState();
    _loadSubmission();
  }

  Future<void> _loadSubmission() async {
    final submissionDoc = await FirebaseFirestore.instance
        .collection('schools')
        .doc(AppConfig.schoolId)
        .collection('homework_submissions')
        .doc("${widget.homeworkId}_${widget.studentId}")
        .get();

    if (submissionDoc.exists) {
      setState(() {
        _submissionData = submissionDoc.data();
        _selectedGrade = _submissionData?['grade'] ?? 0;
        _feedbackController.text = _submissionData?['feedback'] ?? '';
      });
    }
  }

  Future<void> _saveGrade() async {
    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('homework_submissions')
          .doc("${widget.homeworkId}_${widget.studentId}")
          .set({
        'homeworkId': widget.homeworkId,
        'studentId': widget.studentId,
        'studentName': widget.studentName,
        'grade': _selectedGrade,
        'feedback': _feedbackController.text,
        'gradedAt': FieldValue.serverTimestamp(),
        'gradedBy': FirebaseAuth.instance.currentUser?.uid,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Grade saved successfully"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSaving = false);
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGradeSelector(),
            const SizedBox(height: 20),
            _buildFeedbackField(),
            const SizedBox(height: 30),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select Grade",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(10, (index) {
              final grade = index * 10;
              final isSelected = _selectedGrade == grade;
              return GestureDetector(
                onTap: () => setState(() => _selectedGrade = grade),
                child: Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.deepPurple : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.deepPurple : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "$grade%",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                      if (grade == 100)
                        Text(
                          "A+",
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? Colors.white70 : Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Feedback",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _feedbackController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Write feedback for the student...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
        onPressed: _isSaving ? null : _saveGrade,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isSaving
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : const Text("Save Grade", style: TextStyle(fontSize: 16)),
      ),
    );
  }
}