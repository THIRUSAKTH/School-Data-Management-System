import 'package:firebase_auth/firebase_auth.dart';
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
    extends State<TeacherHomeworkSubmissionsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _students = [];
  List<String> _submittedStudentIds = [];
  Map<String, dynamic>? _homeworkData;
  List<Map<String, dynamic>> _submissionDetails = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load homework data
      final homeworkDoc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('homework')
          .doc(widget.homeworkId)
          .get();

      if (homeworkDoc.exists) {
        _homeworkData = homeworkDoc.data();
        _submittedStudentIds = List<String>.from(
          _homeworkData?['submittedBy'] ?? [],
        );

        // Load submission details if available
        if (_homeworkData?['submissionDetails'] != null) {
          _submissionDetails = List<Map<String, dynamic>>.from(
            _homeworkData!['submissionDetails'],
          );
        }
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
        final submissionDetail = _submissionDetails.firstWhere(
              (detail) => detail['studentId'] == doc.id,
          orElse: () => {},
        );

        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
          'rollNo': data['rollNo']?.toString() ?? '',
          'isSubmitted': _submittedStudentIds.contains(doc.id),
          'submittedAt': submissionDetail['submittedAt'],
          'remarks': submissionDetail['remarks'] ?? '',
          'grade': submissionDetail['grade'],
        };
      }).toList();

      // Sort: Pending first, then Submitted by date
      _students.sort((a, b) {
        if (a['isSubmitted'] == b['isSubmitted']) {
          if (a['isSubmitted']) {
            final aDate = a['submittedAt'] as Timestamp?;
            final bDate = b['submittedAt'] as Timestamp?;
            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return 1;
            if (bDate == null) return -1;
            return bDate.toDate().compareTo(aDate.toDate());
          }
          return 0;
        }
        return a['isSubmitted'] ? 1 : -1;
      });

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "All"),
            Tab(text: "Submitted"),
            Tab(text: "Pending"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: "Refresh",
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportReport,
            tooltip: "Export Report",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStudentList("All"),
                _buildStudentList("Submitted"),
                _buildStudentList("Pending"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final submittedCount = _students.where((s) => s['isSubmitted'] == true).length;
    final pendingCount = _students.length - submittedCount;
    final submissionRate = _students.isNotEmpty ? (submittedCount / _students.length) * 100 : 0;

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

  Widget _buildStudentList(String filterType) {
    var filteredStudents = _students;

    if (filterType == "Submitted") {
      filteredStudents = _students.where((s) => s['isSubmitted'] == true).toList();
    } else if (filterType == "Pending") {
      filteredStudents = _students.where((s) => s['isSubmitted'] == false).toList();
    }

    if (filteredStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              filterType == "Submitted"
                  ? Icons.assignment_turned_in
                  : Icons.pending_actions,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              filterType == "Submitted"
                  ? "No submissions yet"
                  : filterType == "Pending"
                  ? "All students have submitted"
                  : "No students found",
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            if (filterType == "Pending" && _students.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ElevatedButton.icon(
                  onPressed: _sendReminderNotifications,
                  icon: const Icon(Icons.notifications_active),
                  label: const Text("Send Reminders"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredStudents.length,
        itemBuilder: (context, index) {
          final student = filteredStudents[index];
          return _buildStudentCard(student);
        },
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final isSubmitted = student['isSubmitted'] as bool;
    final submittedAt = student['submittedAt'] as Timestamp?;
    final grade = student['grade'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isSubmitted ? Colors.green.shade100 : Colors.orange.shade100,
          child: Text(
            student['rollNo'] ?? '?',
            style: TextStyle(
              color: isSubmitted ? Colors.green : Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          student['name'],
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Roll No: ${student['rollNo'] ?? 'N/A'}",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (isSubmitted && submittedAt != null)
              Text(
                "Submitted: ${DateFormat('dd MMM yyyy, hh:mm a').format(submittedAt.toDate())}",
                style: const TextStyle(fontSize: 11, color: Colors.green),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            if (isSubmitted && grade != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Grade: $grade",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        children: [
          if (isSubmitted) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (student['remarks'] != null && student['remarks'].toString().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Student Remarks:",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            student['remarks'].toString(),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  // Responsive buttons - wrap on small screens
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 400) {
                        return Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _viewSubmission(student['id'], student['name']),
                                icon: const Icon(Icons.visibility),
                                label: const Text("View Details"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _gradeHomework(student['id'], student['name']),
                                icon: const Icon(Icons.grade),
                                label: Text(grade != null ? "Update Grade" : "Add Grade"),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _viewSubmission(student['id'], student['name']),
                              icon: const Icon(Icons.visibility),
                              label: const Text("View Details"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _gradeHomework(student['id'], student['name']),
                              icon: const Icon(Icons.grade),
                              label: Text(grade != null ? "Update Grade" : "Add Grade"),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _sendReminderToStudent(student['id'], student['name']),
                  icon: const Icon(Icons.notifications_active),
                  label: const Text("Send Reminder"),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange),
                    foregroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _viewSubmission(String studentId, String studentName) async {
    // Find the student's submission details
    final submission = _submissionDetails.firstWhere(
          (detail) => detail['studentId'] == studentId,
      orElse: () => {},
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Submission - $studentName"),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.assignment_turned_in, size: 48, color: Colors.green),
              const SizedBox(height: 16),
              if (submission['submittedAt'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    "Submitted: ${DateFormat('dd MMM yyyy, hh:mm a').format((submission['submittedAt'] as Timestamp).toDate())}",
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              if (submission['grade'] != null && submission['grade'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    "Grade: ${submission['grade']}",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              if (submission['teacherRemarks'] != null && submission['teacherRemarks'].toString().isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Teacher Remarks:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(submission['teacherRemarks'].toString()),
                    ],
                  ),
                ),
              if (submission['remarks'] != null && submission['remarks'].toString().isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Student Remarks:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(submission['remarks'].toString()),
                    ],
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
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _gradeHomework(studentId, studentName);
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
    );
  }

  Future<void> _gradeHomework(String studentId, String studentName) async {
    final gradeController = TextEditingController();
    final remarksController = TextEditingController();

    // Find existing grade
    final existingSubmission = _submissionDetails.firstWhere(
          (detail) => detail['studentId'] == studentId,
      orElse: () => {},
    );

    if (existingSubmission.isNotEmpty) {
      gradeController.text = existingSubmission['grade']?.toString() ?? '';
      remarksController.text = existingSubmission['teacherRemarks']?.toString() ?? '';
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Grade Homework - $studentName"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: gradeController,
              decoration: const InputDecoration(
                labelText: "Grade",
                hintText: "e.g., A+, 85%, Excellent",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.grade),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: remarksController,
              decoration: const InputDecoration(
                labelText: "Teacher Remarks (Optional)",
                hintText: "Add feedback for the student",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.comment),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text("Save Grade"),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() => _isLoading = true);

      try {
        final homeworkRef = FirebaseFirestore.instance
            .collection('schools')
            .doc(AppConfig.schoolId)
            .collection('homework')
            .doc(widget.homeworkId);

        // Update submission details
        final updatedDetails = List<Map<String, dynamic>>.from(_submissionDetails);
        final existingIndex = updatedDetails.indexWhere(
              (detail) => detail['studentId'] == studentId,
        );

        final submissionDetail = {
          'studentId': studentId,
          'studentName': studentName,
          'grade': gradeController.text.trim(),
          'teacherRemarks': remarksController.text.trim(),
          'gradedAt': FieldValue.serverTimestamp(),
          'gradedBy': FirebaseAuth.instance.currentUser?.uid,
        };

        if (existingIndex != -1) {
          updatedDetails[existingIndex] = submissionDetail;
        } else {
          updatedDetails.add(submissionDetail);
        }

        await homeworkRef.update({'submissionDetails': updatedDetails});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Grade saved successfully!"),
              backgroundColor: Colors.green,
            ),
          );
          await _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _sendReminderNotifications() async {
    final pendingStudents = _students.where((s) => s['isSubmitted'] == false).toList();

    if (pendingStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No pending submissions to remind"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Send Reminders"),
        content: Text(
          "Send reminder notifications to ${pendingStudents.length} student(s) who haven't submitted yet?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text("Send"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Here you would implement actual notification sending
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Reminders sent successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _sendReminderToStudent(String studentId, String studentName) async {
    // Here you would implement individual reminder logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Reminder sent to $studentName"),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _exportReport() async {
    // Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Report export will be available soon"),
        backgroundColor: Colors.orange,
      ),
    );
  }
}