import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app_config.dart';

class ParentViewResultsPage extends StatefulWidget {
  const ParentViewResultsPage({super.key});

  @override
  State<ParentViewResultsPage> createState() => _ParentViewResultsPageState();
}

class _ParentViewResultsPageState extends State<ParentViewResultsPage> {
  String? _selectedStudentId;
  String? _selectedExamId;
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _exams = [];
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);

    try {
      final parentUid = FirebaseAuth.instance.currentUser!.uid;
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('students')
          .where('parentUid', isEqualTo: parentUid)
          .get();

      _students = studentsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'],
          'class': data['class'],
          'section': data['section'],
          'rollNo': data['rollNo'],
        };
      }).toList();

      if (_students.isNotEmpty) {
        _selectedStudentId = _students.first['id'];
        await _loadExams();
      }
    } catch (e) {
      debugPrint('Error loading students: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadExams() async {
    if (_selectedStudentId == null) return;

    // FIXED: Safe find with manual loop
    Map<String, dynamic>? selectedStudent;
    for (var student in _students) {
      if (student['id'] == _selectedStudentId) {
        selectedStudent = student;
        break;
      }
    }

    if (selectedStudent == null) return;

    final className = selectedStudent['class'];

    final examsSnapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(AppConfig.schoolId)
        .collection('exams')
        .where('className', isEqualTo: className)
        .orderBy('createdAt', descending: true)
        .get();

    _exams = examsSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['examName'],
        'type': data['examType'],
        'date': data['startDate'],
      };
    }).toList();

    if (_exams.isNotEmpty) {
      _selectedExamId = _exams.first['id'];
      await _loadResults();
    }
  }

  Future<void> _loadResults() async {
    if (_selectedStudentId == null || _selectedExamId == null) return;

    final resultsSnapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(AppConfig.schoolId)
        .collection('exam_results')
        .where('studentId', isEqualTo: _selectedStudentId)
        .where('examId', isEqualTo: _selectedExamId)
        .get();

    _results = resultsSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'subject': data['subject'],
        'marksObtained': data['marksObtained'],
        'maxMarks': data['maxMarks'],
        'percentage': data['percentage'],
        'grade': data['grade'],
        'remarks': data['remarks'] ?? '',
      };
    }).toList();

    setState(() {});
  }

  double get _totalPercentage {
    if (_results.isEmpty) return 0;
    double totalPercentage = 0;
    for (var result in _results) {
      totalPercentage += result['percentage'] as double;
    }
    return totalPercentage / _results.length;
  }

  String get _overallGrade {
    final avg = _totalPercentage;
    if (avg >= 90) return 'A+';
    if (avg >= 80) return 'A';
    if (avg >= 70) return 'B';
    if (avg >= 60) return 'C';
    if (avg >= 50) return 'D';
    return 'F';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Exam Results'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
          ? _buildEmptyState()
          : Column(
        children: [
          _buildStudentSelector(),
          if (_exams.isNotEmpty) _buildExamSelector(),
          const SizedBox(height: 16),
          Expanded(child: _buildResultsView()),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assessment, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('No Results Available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Results will appear here once published'),
        ],
      ),
    );
  }

  Widget _buildStudentSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Child', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedStudentId,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: _students.map<DropdownMenuItem<String>>((student) {
              return DropdownMenuItem<String>(
                value: student['id'] as String,
                child: Text('${student['name']} (${student['class']} - ${student['section']})'),
              );
            }).toList(),
            onChanged: (value) async {
              setState(() {
                _selectedStudentId = value;
                _selectedExamId = null;
                _results = [];
              });
              await _loadExams();
              await _loadResults();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExamSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Exam', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedExamId,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: _exams.map<DropdownMenuItem<String>>((exam) {
              return DropdownMenuItem<String>(
                value: exam['id'] as String,
                child: Text('${exam['name']} (${exam['type']})'),
              );
            }).toList(),
            onChanged: (value) async {
              setState(() {
                _selectedExamId = value;
                _results = [];
              });
              await _loadResults();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_late, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('No results found for this exam'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 16),
          const Text('Subject-wise Marks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._results.map((result) => _buildResultCard(result)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text('Overall Performance', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text('${_totalPercentage.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Grade: $_overallGrade', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result) {
    final percentage = result['percentage'] as double;
    Color gradeColor = percentage >= 80 ? Colors.green : (percentage >= 60 ? Colors.orange : Colors.red);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(result['subject'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('${result['marksObtained']}/${result['maxMarks']}', style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: gradeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text('${percentage.toStringAsFixed(1)}%', style: TextStyle(color: gradeColor, fontWeight: FontWeight.bold)),
                      Text('Grade: ${result['grade']}', style: TextStyle(color: gradeColor, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            if (result['remarks'] != null && result['remarks'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.comment, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(child: Text(result['remarks'], style: TextStyle(fontSize: 12, color: Colors.grey.shade700))),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
      ],
    );
  }
}