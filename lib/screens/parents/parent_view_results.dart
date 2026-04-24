import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app_config.dart';

class ParentViewResultsPage extends StatefulWidget {
  final String? studentId;
  final String? studentName;

  const ParentViewResultsPage({
    super.key,
    this.studentId,
    this.studentName,
  });

  @override
  State<ParentViewResultsPage> createState() => _ParentViewResultsPageState();
}

class _ParentViewResultsPageState extends State<ParentViewResultsPage> {
  String? _selectedStudentId;
  String? _selectedStudentName;
  String? _selectedExamId;
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _exams = [];
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = true;
  bool _isExporting = false;

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
          'name': data['name'] ?? 'Unknown',
          'class': data['class'] ?? '',
          'section': data['section'] ?? '',
          'rollNo': data['rollNo'] ?? '',
          'admissionNo': data['admissionNo'] ?? '',
        };
      }).toList();

      // Use provided studentId or first child
      if (_students.isNotEmpty) {
        if (widget.studentId != null) {
          final foundStudent = _students.firstWhere(
                (s) => s['id'] == widget.studentId,
            orElse: () => _students.first,
          );
          _selectedStudentId = foundStudent['id'];
          _selectedStudentName = foundStudent['name'];
        } else {
          _selectedStudentId = _students.first['id'];
          _selectedStudentName = _students.first['name'];
        }
        await _loadExams();
      }
    } catch (e) {
      debugPrint('Error loading students: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading students: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadExams() async {
    if (_selectedStudentId == null) return;

    // Find selected student
    Map<String, dynamic>? selectedStudent;
    for (var student in _students) {
      if (student['id'] == _selectedStudentId) {
        selectedStudent = student;
        break;
      }
    }

    if (selectedStudent == null) return;

    final className = selectedStudent['class'];
    if (className == null || className.isEmpty) return;

    try {
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
          'name': data['examName'] ?? data['name'] ?? 'Unknown Exam',
          'type': data['examType'] ?? 'Regular',
          'date': data['startDate'] ?? data['examDate'] ?? 'N/A',
        };
      }).toList();

      if (_exams.isNotEmpty) {
        _selectedExamId = _exams.first['id'];
        await _loadResults();
      }
    } catch (e) {
      debugPrint('Error loading exams: $e');
    }
  }

  Future<void> _loadResults() async {
    if (_selectedStudentId == null || _selectedExamId == null) return;

    setState(() => _isLoading = true);

    try {
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
          'subject': data['subject'] ?? 'Unknown',
          'marksObtained': data['marksObtained'] ?? 0,
          'maxMarks': data['maxMarks'] ?? 100,
          'percentage': data['percentage'] ?? 0.0,
          'grade': data['grade'] ?? 'N/A',
          'remarks': data['remarks'] ?? '',
        };
      }).toList();

      // Sort results alphabetically by subject
      _results.sort((a, b) => a['subject'].compareTo(b['subject']));
    } catch (e) {
      debugPrint('Error loading results: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading results: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
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
    if (avg >= 75) return 'B+';
    if (avg >= 70) return 'B';
    if (avg >= 60) return 'C';
    if (avg >= 50) return 'D';
    return 'F';
  }

  String get _performanceMessage {
    final avg = _totalPercentage;
    if (avg >= 90) return 'Excellent performance! Keep up the great work! 🎉';
    if (avg >= 75) return 'Good job! You\'re doing well. 👍';
    if (avg >= 60) return 'Satisfactory. Keep improving! 📚';
    if (avg >= 50) return 'Need more effort. You can do better! 💪';
    return 'Needs significant improvement. Please focus more. ⚠️';
  }

  Future<void> _exportResults() async {
    setState(() => _isExporting = true);

    // Simulate export delay
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF Export will be available soon'),
          backgroundColor: Colors.orange,
        ),
      );
    }

    setState(() => _isExporting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Exam Results',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_selectedStudentName != null)
              Text(
                _selectedStudentName!,
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_results.isNotEmpty)
            IconButton(
              icon: _isExporting
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(Icons.picture_as_pdf),
              onPressed: _isExporting ? null : _exportResults,
              tooltip: 'Export as PDF',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadResults();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
          ? _buildEmptyState('No Children Linked', 'Please contact the school admin to link your children.')
          : _exams.isEmpty
          ? _buildEmptyState('No Exams Found', 'No exam results have been published yet.')
          : Column(
        children: [
          if (_students.length > 1) _buildStudentSelector(),
          _buildExamSelector(),
          const SizedBox(height: 8),
          Expanded(child: _buildResultsView()),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assessment, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentSelector() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const Icon(Icons.switch_account, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Child:',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedStudentId,
                hint: const Text('Select Child'),
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.orange),
                items: _students.map<DropdownMenuItem<String>>((student) {
                  return DropdownMenuItem<String>(
                    value: student['id'] as String,
                    child: Text(
                      '${student['name']} (${student['class']}-${student['section']})',
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: (value) async {
                  setState(() {
                    _selectedStudentId = value;
                    _selectedExamId = null;
                    _results = [];
                  });

                  // Update selected student name
                  for (var student in _students) {
                    if (student['id'] == value) {
                      setState(() {
                        _selectedStudentName = student['name'];
                      });
                      break;
                    }
                  }

                  await _loadExams();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamSelector() {
    if (_exams.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: const Center(
          child: Text('No exams available for this student'),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const Icon(Icons.quiz, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Exam:',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedExamId,
                hint: const Text('Select Exam'),
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.orange),
                items: _exams.map<DropdownMenuItem<String>>((exam) {
                  return DropdownMenuItem<String>(
                    value: exam['id'] as String,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          exam['name'],
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        if (exam['date'] != 'N/A')
                          Text(
                            exam['date'],
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                      ],
                    ),
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
            ),
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
            const Text(
              'No results found for this exam',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Results will appear here once published',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadResults,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 16),
            _buildPerformanceMessage(),
            const SizedBox(height: 16),
            const Text(
              'Subject-wise Marks',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._results.map((result) => _buildResultCard(result)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.orange, Colors.deepOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Overall Performance',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '${_totalPercentage.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Grade: $_overallGrade',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_results.length} Subjects',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMessage() {
    Color getMessageColor() {
      final avg = _totalPercentage;
      if (avg >= 75) return Colors.green;
      if (avg >= 60) return Colors.orange;
      return Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: getMessageColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: getMessageColor().withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _totalPercentage >= 75 ? Icons.emoji_events : Icons.rocket_launch,
            color: getMessageColor(),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _performanceMessage,
              style: TextStyle(
                fontSize: 12,
                color: getMessageColor(),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result) {
    final percentage = result['percentage'] as double;
    Color gradeColor = percentage >= 80
        ? Colors.green
        : (percentage >= 60 ? Colors.orange : Colors.red);

    IconData getIcon() {
      if (percentage >= 80) return Icons.emoji_events;
      if (percentage >= 60) return Icons.thumb_up;
      if (percentage >= 50) return Icons.trending_up;
      return Icons.trending_down;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () => _showResultDetail(result),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: gradeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(getIcon(), color: gradeColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result['subject'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${result['marksObtained']}/${result['maxMarks']} marks',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: gradeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: gradeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Grade: ${result['grade']}',
                          style: TextStyle(
                            color: gradeColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (result['remarks'] != null && result['remarks'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.comment, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            result['remarks'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResultDetail(Map<String, dynamic> result) {
    final percentage = result['percentage'] as double;
    final marksObtained = result['marksObtained'];
    final maxMarks = result['maxMarks'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.assignment_turned_in,
                    color: Colors.orange.shade700,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result['subject'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Exam Result Details',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            _detailRow('Marks Obtained', '$marksObtained / $maxMarks'),
            _detailRow('Percentage', '${percentage.toStringAsFixed(2)}%'),
            _detailRow('Grade', result['grade']),
            if (result['remarks'] != null && result['remarks'].toString().isNotEmpty)
              _detailRow('Remarks', result['remarks']),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Close"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}