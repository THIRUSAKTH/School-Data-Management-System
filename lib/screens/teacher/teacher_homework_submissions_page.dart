import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:schoolprojectjan/app_config.dart';

class TeacherHomeworkSubmissionsPage extends StatefulWidget {
  final String homeworkId;
  final String homeworkTitle;
  final String className;
  final String section;

  const TeacherHomeworkSubmissionsPage({
    super.key,
    required this.homeworkId,
    required this.homeworkTitle,
    required this.className,
    required this.section,
  });

  @override
  State<TeacherHomeworkSubmissionsPage> createState() =>
      _TeacherHomeworkSubmissionsPageState();
}

class _TeacherHomeworkSubmissionsPageState
    extends State<TeacherHomeworkSubmissionsPage> {
  String _selectedTab = "All";
  bool _isLoading = true;
  List<Map<String, dynamic>> _students = [];
  List<String> _submittedStudentIds = [];
  Map<String, dynamic>? _homeworkData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Load homework data
    final homeworkDoc = await FirebaseFirestore.instance
        .collection('schools')
        .doc(AppConfig.schoolId)
        .collection('homework')
        .doc(widget.homeworkId)
        .get();

    if (homeworkDoc.exists) {
      _homeworkData = homeworkDoc.data();
      _submittedStudentIds =
      List<String>.from(_homeworkData?['submittedBy'] ?? []);
    }

    // Load students in the class
    final studentsSnapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(AppConfig.schoolId)
        .collection('students')
        .where('class', isEqualTo: widget.className)
        .where('section', isEqualTo: widget.section)
        .get();

    _students = studentsSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? 'Unknown',
        'rollNo': data['rollNo'] ?? '',
        'isSubmitted': _submittedStudentIds.contains(doc.id),
      };
    }).toList();

    // Sort: Pending first, then Submitted
    _students.sort((a, b) {
      if (a['isSubmitted'] == b['isSubmitted']) return 0;
      return a['isSubmitted'] ? 1 : -1;
    });

    setState(() => _isLoading = false);
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
              "Homework Submissions",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              "${widget.homeworkTitle} - ${widget.className} ${widget.section}",
              style: const TextStyle(fontSize: 12),
            ),
          ],
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
          _buildSummaryCards(),
          _buildTabBar(),
          Expanded(child: _buildStudentList()),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final submittedCount = _students.where((s) => s['isSubmitted'] == true).length;
    final pendingCount = _students.length - submittedCount;
    final submissionRate = _students.isNotEmpty
        ? (submittedCount / _students.length) * 100
        : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _summaryCard(
              "Submitted",
              submittedCount.toString(),
              Colors.green,
              Icons.check_circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _summaryCard(
              "Pending",
              pendingCount.toString(),
              Colors.orange,
              Icons.pending,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _summaryCard(
              "Rate",
              "${submissionRate.toStringAsFixed(1)}%",
              Colors.deepPurple,
              Icons.trending_up,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
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
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final submittedCount = _students.where((s) => s['isSubmitted'] == true).length;
    final pendingCount = _students.length - submittedCount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _tabButton("All", _students.length, _selectedTab == "All"),
          _tabButton("Submitted", submittedCount, _selectedTab == "Submitted"),
          _tabButton("Pending", pendingCount, _selectedTab == "Pending"),
        ],
      ),
    );
  }

  Widget _tabButton(String title, int count, bool isSelected) {
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.deepPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.deepPurple,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? Colors.white70 : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentList() {
    var filteredStudents = _students;
    if (_selectedTab == "Submitted") {
      filteredStudents = _students.where((s) => s['isSubmitted'] == true).toList();
    } else if (_selectedTab == "Pending") {
      filteredStudents = _students.where((s) => s['isSubmitted'] == false).toList();
    }

    if (filteredStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedTab == "Submitted"
                  ? Icons.assignment_turned_in
                  : Icons.pending_actions,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedTab == "Submitted"
                  ? "No submissions yet"
                  : "All students have submitted",
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredStudents.length,
      itemBuilder: (context, index) {
        final student = filteredStudents[index];
        return _buildStudentCard(student);
      },
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final isSubmitted = student['isSubmitted'] as bool;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isSubmitted ? Colors.green.shade100 : Colors.orange.shade100,
              child: Text(
                student['rollNo'] ?? '?',
                style: TextStyle(
                  color: isSubmitted ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student['name'],
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    "Roll No: ${student['rollNo'] ?? 'N/A'}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSubmitted ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSubmitted ? Icons.check_circle : Icons.pending,
                    size: 14,
                    color: isSubmitted ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isSubmitted ? "Submitted" : "Pending",
                    style: TextStyle(
                      fontSize: 11,
                      color: isSubmitted ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (isSubmitted)
              IconButton(
                icon: const Icon(Icons.visibility, color: Colors.blue),
                onPressed: () => _viewSubmission(student['id']),
                tooltip: "View Submission",
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _viewSubmission(String studentId) async {
    // Show submission details dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Submission Details"),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.assignment_turned_in, size: 48, color: Colors.green),
              const SizedBox(height: 16),
              const Text(
                "Student has submitted the homework",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to grade homework page
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.grade),
                label: const Text("Grade Homework"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}