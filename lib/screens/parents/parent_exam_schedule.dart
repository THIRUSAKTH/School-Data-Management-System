import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../app_config.dart';

class ParentExamSchedulePage extends StatefulWidget {
  final String? className;
  final String? section;

  const ParentExamSchedulePage({
    super.key,
    this.className,
    this.section,
  });

  @override
  State<ParentExamSchedulePage> createState() => _ParentExamSchedulePageState();
}

class _ParentExamSchedulePageState extends State<ParentExamSchedulePage> {
  String? _selectedStudentId;
  String? _selectedStudentName;
  String? _selectedClass;
  String? _selectedSection;
  List<Map<String, dynamic>> _students = [];
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
          'name': data['name'] ?? 'Student',
          'class': data['class'] ?? '',
          'section': data['section'] ?? '',
          'rollNo': data['rollNo'] ?? '',
        };
      }).toList();

      if (_students.isNotEmpty) {
        if (widget.className != null && widget.section != null) {
          // Find student matching the provided class/section
          final matchingStudent = _students.firstWhere(
                (s) => s['class'] == widget.className && s['section'] == widget.section,
            orElse: () => _students.first,
          );
          _selectedStudentId = matchingStudent['id'];
          _selectedStudentName = matchingStudent['name'];
          _selectedClass = matchingStudent['class'];
          _selectedSection = matchingStudent['section'];
        } else {
          _selectedStudentId = _students.first['id'];
          _selectedStudentName = _students.first['name'];
          _selectedClass = _students.first['class'];
          _selectedSection = _students.first['section'];
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Exam Schedule",
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
              _loadStudents();
            },
            tooltip: "Refresh",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
          ? _buildEmptyState('No Children Linked', 'Please contact the school admin to link your children.')
          : _selectedClass == null || _selectedClass!.isEmpty
          ? _buildEmptyState('No Class Assigned', 'Your child has not been assigned to any class yet.')
          : Column(
        children: [
          if (_students.length > 1) _buildStudentSelector(),
          _buildClassInfoCard(),
          Expanded(child: _buildExamSchedule()),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 80, color: Colors.grey.shade400),
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
                  setState(() => _isLoading = true);

                  final selectedStudent = _students.firstWhere((s) => s['id'] == value);
                  setState(() {
                    _selectedStudentId = value;
                    _selectedStudentName = selectedStudent['name'];
                    _selectedClass = selectedStudent['class'];
                    _selectedSection = selectedStudent['section'];
                    _isLoading = false;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.class_, color: Colors.orange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Class $_selectedClass - $_selectedSection',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Exam schedule for your child\'s class',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _students.length > 1 ? 'Selected Child' : 'Your Child',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamSchedule() {
    if (_selectedClass == null || _selectedClass!.isEmpty) {
      return const Center(child: Text("No class assigned to this student"));
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
                Text(
                  "No exams scheduled for this class",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  "Check back later for updates",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        final exams = snapshot.data!.docs;

        // Separate exams by status
        final Map<String, List<QueryDocumentSnapshot>> groupedExams = {
          'Ongoing': [],
          'Upcoming': [],
          'Completed': [],
        };

        for (var exam in exams) {
          final data = exam.data() as Map<String, dynamic>;
          final startDate = (data['startDate'] as Timestamp).toDate();
          final endDate = (data['endDate'] as Timestamp).toDate();

          if (startDate.isBefore(DateTime.now()) && endDate.isAfter(DateTime.now())) {
            groupedExams['Ongoing']!.add(exam);
          } else if (startDate.isAfter(DateTime.now())) {
            groupedExams['Upcoming']!.add(exam);
          } else {
            groupedExams['Completed']!.add(exam);
          }
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: exams.length,
            itemBuilder: (context, index) {
              final exam = exams[index];
              final data = exam.data() as Map<String, dynamic>;
              return _buildExamCard(data);
            },
          ),
        );
      },
    );
  }

  Widget _buildExamCard(Map<String, dynamic> exam) {
    final startDate = (exam['startDate'] as Timestamp).toDate();
    final endDate = (exam['endDate'] as Timestamp).toDate();
    final subjects = List<String>.from(exam['subjects'] ?? []);
    final maxMarks = List<int>.from(exam['maxMarks'] ?? []);

    final isUpcoming = startDate.isAfter(DateTime.now());
    final isOngoing = startDate.isBefore(DateTime.now()) && endDate.isAfter(DateTime.now());
    final daysUntil = isUpcoming ? startDate.difference(DateTime.now()).inDays : 0;

    Color getStatusColor() {
      if (isOngoing) return Colors.green;
      if (isUpcoming) return Colors.orange;
      return Colors.grey;
    }

    String getStatusText() {
      if (isOngoing) return "ONGOING";
      if (isUpcoming) return "UPCOMING";
      return "COMPLETED";
    }

    IconData getStatusIcon() {
      if (isOngoing) return Icons.play_circle;
      if (isUpcoming) return Icons.schedule;
      return Icons.check_circle;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isOngoing
            ? BorderSide(color: Colors.green.shade300, width: 1.5)
            : BorderSide.none,
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: getStatusColor().withValues(alpha: 0.1),
          child: Icon(
            getStatusIcon(),
            color: getStatusColor(),
            size: 20,
          ),
        ),
        title: Text(
          exam['examName'] ?? 'Unknown Exam',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${DateFormat('dd MMM').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}",
              style: const TextStyle(fontSize: 12),
            ),
            if (isUpcoming && daysUntil > 0)
              Text(
                "$daysUntil days to go",
                style: TextStyle(fontSize: 10, color: Colors.orange.shade700),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: getStatusColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            getStatusText(),
            style: TextStyle(
              color: getStatusColor(),
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exam Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    exam['examType'] ?? 'Regular',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Subjects List
                const Text(
                  'Subjects',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: subjects.length,
                  separatorBuilder: (_, __) => const Divider(height: 8),
                  itemBuilder: (context, index) {
                    return Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            subjects[index],
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        if (maxMarks.isNotEmpty && index < maxMarks.length)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Max: ${maxMarks[index]}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Info Container
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (exam['examType'] == 'Final' ? Colors.red : Colors.blue).shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (exam['examType'] == 'Final' ? Colors.red : Colors.blue).shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        exam['examType'] == 'Final' ? Icons.warning : Icons.info_outline,
                        size: 16,
                        color: (exam['examType'] == 'Final' ? Colors.red : Colors.blue).shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          exam['examType'] == 'Final'
                              ? "Final exams are compulsory for all students. Please ensure proper preparation."
                              : "Please prepare well for the exam. Contact teachers for any clarification.",
                          style: TextStyle(
                            fontSize: 11,
                            color: (exam['examType'] == 'Final' ? Colors.red : Colors.blue).shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (isUpcoming && daysUntil <= 3 && daysUntil > 0)
                  const SizedBox(height: 8),
                if (isUpcoming && daysUntil <= 3 && daysUntil > 0)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.alarm, size: 14, color: Colors.orange),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            daysUntil == 0
                                ? "Exam starts tomorrow! Best of luck!"
                                : "Only $daysUntil days left for exam! Start preparing.",
                            style: const TextStyle(fontSize: 11, color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
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