import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:schoolprojectjan/screens/teacher/teacher_upload_marks.dart';
import '../../app_config.dart';

class TeacherExamSchedulePage extends StatefulWidget {
  const TeacherExamSchedulePage({super.key});

  @override
  State<TeacherExamSchedulePage> createState() =>
      _TeacherExamSchedulePageState();
}

class _TeacherExamSchedulePageState extends State<TeacherExamSchedulePage> {
  List<String> _assignedClasses = [];
  bool _isLoading = true;
  String? _selectedClass;
  String? _errorMessage;
  List<Map<String, dynamic>> _exams = [];
  bool _isLoadingExams = false;

  @override
  void initState() {
    super.initState();
    _loadTeacherClasses();
  }

  Future<void> _loadTeacherClasses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final teacherUid = FirebaseAuth.instance.currentUser!.uid;

      // Query from teachers collection
      final teacherQuery =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('teachers')
              .where('uid', isEqualTo: teacherUid)
              .limit(1)
              .get();

      if (teacherQuery.docs.isNotEmpty) {
        final teacherData = teacherQuery.docs.first.data();

        // Try multiple field names for assigned classes
        List assignedClasses =
            teacherData['assignedClasses'] ??
            teacherData['classes'] ??
            teacherData['classAssignments'] ??
            [];

        _assignedClasses.clear();

        for (var classInfo in assignedClasses) {
          if (classInfo is String) {
            _assignedClasses.add(classInfo);
          } else if (classInfo is Map && classInfo.containsKey('className')) {
            _assignedClasses.add(classInfo['className']);
          } else if (classInfo is Map && classInfo.containsKey('class')) {
            _assignedClasses.add(classInfo['class']);
          }
        }

        _assignedClasses = _assignedClasses.toSet().toList();
        _assignedClasses.sort();

        if (_assignedClasses.isNotEmpty) {
          _selectedClass = _assignedClasses.first;
          await _loadExams();
        } else {
          _errorMessage = "No classes assigned to you yet.";
        }
      } else {
        _errorMessage = "Teacher profile not found. Please contact admin.";
      }
    } catch (e) {
      debugPrint('Error loading teacher classes: $e');
      _errorMessage =
          "Error loading classes: ${e.toString().substring(0, 100)}";
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadExams() async {
    if (_selectedClass == null) return;

    setState(() => _isLoadingExams = true);

    try {
      // Method 1: Try with orderBy (requires index)
      final examsSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('exams')
              .where('className', isEqualTo: _selectedClass)
              .orderBy('startDate', descending: false)
              .get();

      _processExams(examsSnapshot);
    } catch (e) {
      debugPrint('Ordered query failed: $e');
      // Method 2: Fallback - query without orderBy
      await _loadExamsWithoutOrder();
    }

    setState(() => _isLoadingExams = false);
  }

  Future<void> _loadExamsWithoutOrder() async {
    try {
      final examsSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('exams')
              .where('className', isEqualTo: _selectedClass)
              .get();

      _processExams(examsSnapshot);
    } catch (e) {
      debugPrint('Fallback query failed: $e');
      setState(() {
        _exams = [];
        _errorMessage = "Error loading exams. Please create Firebase index.";
      });
    }
  }

  void _processExams(QuerySnapshot snapshot) {
    final examsList =
        snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'name': data['examName'] ?? data['name'] ?? 'Unknown Exam',
            'type': data['examType'] ?? 'Regular',
            'startDate': data['startDate'],
            'endDate': data['endDate'],
            'subjects': List<String>.from(data['subjects'] ?? []),
            'maxMarks':
                (data['maxMarks'] as List?)
                    ?.map((e) => (e as num).toInt())
                    .toList() ??
                [],
          };
        }).toList();

    // Sort locally if no index
    examsList.sort((a, b) {
      final aDate = a['startDate'] as Timestamp?;
      final bDate = b['startDate'] as Timestamp?;
      if (aDate != null && bDate != null) {
        return aDate.toDate().compareTo(bDate.toDate());
      }
      return 0;
    });

    setState(() {
      _exams = examsList;
      _errorMessage = null;
    });
  }

  Future<void> _refreshData() async {
    await _loadTeacherClasses();
    if (_selectedClass != null) {
      await _loadExams();
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: "Refresh",
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? _buildErrorWidget()
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

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            label: const Text("Retry"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
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
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            label: const Text("Refresh"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.class_, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            "Select Class:",
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedClass,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              items:
                  _assignedClasses.map<DropdownMenuItem<String>>((className) {
                    return DropdownMenuItem<String>(
                      value: className,
                      child: Text(className),
                    );
                  }).toList(),
              onChanged: (value) async {
                setState(() => _selectedClass = value);
                if (value != null) {
                  await _loadExams();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamSchedule() {
    if (_selectedClass == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.class_, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text("Select a class to view exams"),
          ],
        ),
      );
    }

    if (_isLoadingExams) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_exams.isEmpty) {
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
            const SizedBox(height: 8),
            Text(
              "No exams have been created for ${_selectedClass} yet",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _exams.length,
        itemBuilder: (context, index) {
          final exam = _exams[index];
          return _buildExamScheduleCard(exam);
        },
      ),
    );
  }

  Widget _buildExamScheduleCard(Map<String, dynamic> exam) {
    final startTimestamp = exam['startDate'] as Timestamp?;
    final endTimestamp = exam['endDate'] as Timestamp?;

    if (startTimestamp == null || endTimestamp == null) {
      return const SizedBox.shrink();
    }

    final startDate = startTimestamp.toDate();
    final endDate = endTimestamp.toDate();
    final subjects = List<String>.from(exam['subjects'] ?? []);
    final maxMarks = List<int>.from(exam['maxMarks'] ?? []);

    final now = DateTime.now();
    final isUpcoming = startDate.isAfter(now);
    final isOngoing = startDate.isBefore(now) && endDate.isAfter(now);
    final isCompleted = endDate.isBefore(now);
    final daysUntil = isUpcoming ? startDate.difference(now).inDays : 0;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isOngoing) {
      statusColor = Colors.green;
      statusText = "ONGOING";
      statusIcon = Icons.play_circle;
    } else if (isUpcoming) {
      statusColor = Colors.orange;
      statusText = "UPCOMING";
      statusIcon = Icons.schedule;
    } else {
      statusColor = Colors.grey;
      statusText = "COMPLETED";
      statusIcon = Icons.check_circle;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:
            isOngoing
                ? BorderSide(color: Colors.green.shade300, width: 1.5)
                : BorderSide.none,
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor, size: 22),
        ),
        title: Text(
          exam['name'],
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exam['type'],
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            if (isUpcoming && daysUntil > 0)
              Text(
                "$daysUntil day${daysUntil == 1 ? '' : 's'} to go",
                style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
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
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Range
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${DateFormat('dd MMM yyyy').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}",
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Subjects List
                const Text(
                  "Subjects",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: subjects.length,
                  separatorBuilder: (_, __) => const Divider(height: 12),
                  itemBuilder: (context, index) {
                    return Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            subjects[index],
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        if (maxMarks.isNotEmpty && index < maxMarks.length)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "Max: ${maxMarks[index]}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Marks Entry Button (if not completed)
                if (!isCompleted)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _navigateToMarksEntry(exam);
                      },
                      icon: const Icon(Icons.edit_note, size: 18),
                      label: const Text("Enter Marks"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToMarksEntry(Map<String, dynamic> exam) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TeacherUploadMarksPage(
              selectedClass: _selectedClass,
              examId: exam['id'],
              subject: null,
            ),
      ),
    );
  }
}
