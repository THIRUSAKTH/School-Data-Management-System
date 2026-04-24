import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../app_config.dart';

class TeacherExamSchedulePage extends StatefulWidget {
  const TeacherExamSchedulePage({super.key});

  @override
  State<TeacherExamSchedulePage> createState() => _TeacherExamSchedulePageState();
}

class _TeacherExamSchedulePageState extends State<TeacherExamSchedulePage> {
  List<String> _assignedClasses = [];
  bool _isLoading = true;
  String? _selectedClass;

  @override
  void initState() {
    super.initState();
    _loadTeacherClasses();
  }

  Future<void> _loadTeacherClasses() async {
    setState(() => _isLoading = true);

    try {
      final teacherUid = FirebaseAuth.instance.currentUser!.uid;
      final teacherDoc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('teachers')
          .where('uid', isEqualTo: teacherUid)
          .limit(1)
          .get();

      if (teacherDoc.docs.isNotEmpty) {
        final assignedClasses = teacherDoc.docs.first['assignedClasses'] as List? ?? [];
        for (var classInfo in assignedClasses) {
          _assignedClasses.add(classInfo['className']);
        }
        _assignedClasses = _assignedClasses.toSet().toList();
        if (_assignedClasses.isNotEmpty) {
          _selectedClass = _assignedClasses.first;
        }
      }
    } catch (e) {
      debugPrint('Error loading teacher classes: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text("Exam Schedule"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assignedClasses.isEmpty
          ? _buildEmptyState()
          : Column(
        children: [
          _buildClassSelector(),
          Expanded(child: _buildExamSchedule()),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            "No Classes Assigned",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "You haven't been assigned any classes yet",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildClassSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
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
      child: Row(
        children: [
          const Icon(Icons.class_, color: Colors.blue),
          const SizedBox(width: 12),
          const Text("Select Class:"),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedClass,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _assignedClasses.map<DropdownMenuItem<String>>((className) {
                return DropdownMenuItem<String>(
                  value: className,
                  child: Text(className),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedClass = value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamSchedule() {
    if (_selectedClass == null) {
      return const Center(child: Text("Select a class to view exams"));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('exams')
          .where('className', isEqualTo: _selectedClass)
          .orderBy('startDate', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.quiz_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text(
                  "No exams scheduled",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }

        final exams = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: exams.length,
          itemBuilder: (context, index) {
            final exam = exams[index];
            final data = exam.data() as Map<String, dynamic>;
            return _buildExamScheduleCard(data);
          },
        );
      },
    );
  }

  Widget _buildExamScheduleCard(Map<String, dynamic> exam) {
    final startDate = (exam['startDate'] as Timestamp).toDate();
    final endDate = (exam['endDate'] as Timestamp).toDate();
    final subjects = List<String>.from(exam['subjects']);
    final maxMarks = List<int>.from(exam['maxMarks']);
    final isUpcoming = startDate.isAfter(DateTime.now());
    final isOngoing = startDate.isBefore(DateTime.now()) && endDate.isAfter(DateTime.now());

    Color statusColor;
    String statusText;
    if (isOngoing) {
      statusColor = Colors.green;
      statusText = "ONGOING";
    } else if (isUpcoming) {
      statusColor = Colors.orange;
      statusText = "UPCOMING";
    } else {
      statusColor = Colors.grey;
      statusText = "COMPLETED";
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isOngoing ? BorderSide(color: Colors.green.shade300, width: 1) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam['examName'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        exam['examType'],
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  "${DateFormat('dd MMM yyyy').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              "Subjects",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...List.generate(subjects.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.book, size: 14, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(child: Text(subjects[index])),
                    Text("Max Marks: ${maxMarks[index]}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}