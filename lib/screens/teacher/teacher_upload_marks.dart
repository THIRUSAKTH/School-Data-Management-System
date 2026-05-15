import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:schoolprojectjan/services/notification_service.dart';
import '../../app_config.dart';

class TeacherUploadMarksPage extends StatefulWidget {
  final String? selectedClass;
  final String? selectedSection;
  final String? examId;
  final String? subject;

  const TeacherUploadMarksPage({
    super.key,
    this.selectedClass,
    this.selectedSection,
    this.examId,
    this.subject,
  });

  @override
  State<TeacherUploadMarksPage> createState() => _TeacherUploadMarksPageState();
}

class _TeacherUploadMarksPageState extends State<TeacherUploadMarksPage> {
  String? _selectedClass;
  String? _selectedSection;
  String? _selectedExam;
  String? _selectedSubject;
  List<String> _availableClasses = [];
  List<String> _availableSections = [];
  List<Map<String, dynamic>> _exams = [];
  List<Map<String, dynamic>> _students = [];
  Map<String, TextEditingController> _marksControllers = {};
  Map<String, TextEditingController> _remarksControllers = {};
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isLoadingExams = false;
  bool _isLoadingStudents = false;
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  @override
  void dispose() {
    for (var controller in _marksControllers.values) {
      controller.dispose();
    }
    for (var controller in _remarksControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadTeacherData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final teacherUid = FirebaseAuth.instance.currentUser!.uid;
      final teacherDoc =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('teachers')
              .where('uid', isEqualTo: teacherUid)
              .limit(1)
              .get();

      if (teacherDoc.docs.isNotEmpty) {
        final teacherData = teacherDoc.docs.first.data();

        List assignedClasses =
            teacherData['assignedClasses'] ??
            teacherData['classes'] ??
            teacherData['classAssignments'] ??
            [];

        _availableClasses.clear();

        for (var classInfo in assignedClasses) {
          if (classInfo is String) {
            _availableClasses.add(classInfo);
          } else if (classInfo is Map && classInfo.containsKey('className')) {
            _availableClasses.add(classInfo['className']);
          } else if (classInfo is Map && classInfo.containsKey('class')) {
            _availableClasses.add(classInfo['class']);
          }
        }

        _availableClasses = _availableClasses.toSet().toList();
        _availableClasses.sort();
      }

      if (widget.selectedClass != null &&
          _availableClasses.contains(widget.selectedClass)) {
        _selectedClass = widget.selectedClass;
        await _loadExams();

        if (widget.selectedSection != null) {
          _selectedSection = widget.selectedSection;
          await _loadSections();

          if (widget.examId != null) {
            _selectedExam = widget.examId;

            if (widget.subject != null) {
              _selectedSubject = widget.subject;
              await _loadStudents();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading teacher data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadExams() async {
    if (_selectedClass == null) return;

    setState(() => _isLoadingExams = true);

    try {
      final examsSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('exams')
              .where('className', isEqualTo: _selectedClass)
              .get();

      _exams =
          examsSnapshot.docs.map((doc) {
            final data = doc.data();
            final subjectsRaw = data['subjects'] ?? [];
            final maxMarksRaw = data['maxMarks'] ?? [];

            return {
              'id': doc.id,
              'name': data['examName'] ?? data['name'] ?? 'Unknown Exam',
              'type': data['examType'] ?? 'Regular',
              'subjects': List<String>.from(subjectsRaw),
              'maxMarks':
                  maxMarksRaw.map<int>((e) => (e as num).toInt()).toList(),
              'startDate': data['startDate'],
              'endDate': data['endDate'],
            };
          }).toList();

      _exams.sort((a, b) {
        final aDate = a['startDate'] as Timestamp?;
        final bDate = b['startDate'] as Timestamp?;
        if (aDate != null && bDate != null) {
          return bDate.toDate().compareTo(aDate.toDate());
        }
        return 0;
      });
    } catch (e) {
      debugPrint('Error loading exams: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading exams: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoadingExams = false);
    }
  }

  Future<void> _loadSections() async {
    if (_selectedClass == null) return;

    try {
      final studentsSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('students')
              .where('class', isEqualTo: _selectedClass)
              .get();

      final sectionsSet = <String>{};
      for (var doc in studentsSnapshot.docs) {
        final section = doc['section'] as String?;
        if (section != null && section.isNotEmpty) {
          sectionsSet.add(section);
        }
      }
      _availableSections = sectionsSet.toList()..sort();
    } catch (e) {
      debugPrint('Error loading sections: $e');
    }
  }

  Future<void> _loadStudents() async {
    if (_selectedClass == null ||
        _selectedSection == null ||
        _selectedExam == null ||
        _selectedSubject == null) {
      return;
    }

    if (!mounted) return;
    setState(() => _isLoadingStudents = true);

    for (var controller in _marksControllers.values) {
      controller.dispose();
    }
    for (var controller in _remarksControllers.values) {
      controller.dispose();
    }
    _marksControllers.clear();
    _remarksControllers.clear();

    try {
      final studentsSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('students')
              .where('class', isEqualTo: _selectedClass)
              .where('section', isEqualTo: _selectedSection)
              .get();

      final marksSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('exam_results')
              .where('examId', isEqualTo: _selectedExam)
              .where('subject', isEqualTo: _selectedSubject)
              .get();

      final Map<String, Map<String, dynamic>> existingMarksMap = {};
      for (var doc in marksSnapshot.docs) {
        final data = doc.data();
        final studentId = data['studentId'];
        if (studentId != null) {
          existingMarksMap[studentId] = data;
        }
      }

      _students =
          studentsSnapshot.docs.map((doc) {
            final data = doc.data();
            final studentId = doc.id;
            final existingMark = existingMarksMap[studentId];

            _marksControllers[studentId] = TextEditingController(
              text:
                  existingMark != null
                      ? existingMark['marksObtained']?.toString() ?? ''
                      : '',
            );
            _remarksControllers[studentId] = TextEditingController(
              text: existingMark != null ? existingMark['remarks'] ?? '' : '',
            );

            return {
              'id': studentId,
              'name': data['name'] ?? 'Unknown',
              'rollNo': data['rollNo']?.toString() ?? 'N/A',
            };
          }).toList();

      _students.sort((a, b) {
        final rollA = int.tryParse(a['rollNo'].toString()) ?? 0;
        final rollB = int.tryParse(b['rollNo'].toString()) ?? 0;
        return rollA.compareTo(rollB);
      });
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

    if (mounted) {
      setState(() => _isLoadingStudents = false);
    }
  }

  // Check if all subjects are completed
  Future<bool> _areAllSubjectsCompleted() async {
    if (_selectedExam == null) return false;

    final examDoc =
        await FirebaseFirestore.instance
            .collection('schools')
            .doc(AppConfig.schoolId)
            .collection('exams')
            .doc(_selectedExam)
            .get();

    if (!examDoc.exists) return false;

    final examData = examDoc.data()!;
    final totalSubjects = (examData['subjects'] as List).length;
    final completedSubjects =
        (examData['completedSubjects'] as List?)?.length ?? 0;

    return completedSubjects >= totalSubjects;
  }

  // Publish final results after all subjects are entered
  Future<void> _publishFinalResults() async {
    setState(() => _isPublishing = true);

    try {
      final examDoc =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('exams')
              .doc(_selectedExam)
              .get();

      final examData = examDoc.data()!;
      final subjects = List<String>.from(examData['subjects'] ?? []);
      final examName = examData['examName'] ?? 'Exam';

      // Get all students in the class
      final studentsSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('students')
              .where('class', isEqualTo: _selectedClass)
              .where('section', isEqualTo: _selectedSection)
              .get();

      // Collect all marks for all students
      final Map<String, Map<String, dynamic>> allMarks = {};

      for (var subject in subjects) {
        final marksSnapshot =
            await FirebaseFirestore.instance
                .collection('schools')
                .doc(AppConfig.schoolId)
                .collection('exam_results')
                .where('examId', isEqualTo: _selectedExam)
                .where('subject', isEqualTo: subject)
                .get();

        for (var doc in marksSnapshot.docs) {
          final data = doc.data();
          final studentId = data['studentId'];
          if (!allMarks.containsKey(studentId)) {
            allMarks[studentId] = {};
          }
          allMarks[studentId]![subject] = data;
        }
      }

      // Send final result notifications
      await _sendFinalResultNotifications(allMarks, examName: examName);

      // Update exam status to published
      await examDoc.reference.update({
        'status': 'published',
        'publishedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✅ Results published successfully! Parents notified.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error publishing results: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isPublishing = false);
    }
  }

  // Send final result notifications to parents
  Future<void> _sendFinalResultNotifications(
    Map<String, Map<String, dynamic>> allMarks, {
    required String examName,
  }) async {
    int notificationCount = 0;

    for (var entry in allMarks.entries) {
      final studentId = entry.key;
      final subjectMarks = entry.value;

      final studentDoc =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('students')
              .doc(studentId)
              .get();

      final parentUid =
          studentDoc.data()?['parentUID']; // Capital UID to match Firestore
      final studentName = studentDoc.data()?['name'] ?? 'Student';
      final rollNo = studentDoc.data()?['rollNo']?.toString() ?? 'N/A';

      if (parentUid == null || parentUid.isEmpty) {
        print('❌ No parent UID for student: $studentName');
        continue;
      }

      // Calculate total marks
      int totalObtained = 0;
      int totalMax = 0;

      for (var mark in subjectMarks.values) {
        totalObtained += (mark['marksObtained'] as int?) ?? 0;
        totalMax += (mark['maxMarks'] as int?) ?? 0;
      }

      final percentage = totalMax > 0 ? (totalObtained / totalMax) * 100.0 : 0;
      final grade = _calculateGrade(percentage);
      final percentageFormatted = percentage.toStringAsFixed(1);
      final gradeEmoji = _getGradeEmoji(grade);

      final notificationTitle = "📊 Final Exam Results Published";
      final notificationBody =
          "$studentName (Roll No: $rollNo) - $examName\n"
          "Total: $totalObtained/$totalMax ($percentageFormatted%) $gradeEmoji ($grade)";

      // Send push notification
      await NotificationService.sendToUser(
        userId: parentUid,
        title: notificationTitle,
        body: notificationBody,
        type: 'result',
        data: {
          'examId': _selectedExam,
          'examName': examName,
          'studentId': studentId,
          'studentName': studentName,
          'totalObtained': totalObtained,
          'totalMax': totalMax,
          'percentage': percentage,
          'grade': grade,
        },
      );

      // Create in-app notification
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('notifications')
          .add({
            'studentId': studentId,
            'title': notificationTitle,
            'message':
                "Your child $studentName scored $totalObtained/$totalMax ($percentageFormatted%) in $examName. Grade: $grade",
            'type': 'result',
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
            'deletedFor': [],
            'additionalData': {
              'examId': _selectedExam,
              'examName': examName,
              'totalObtained': totalObtained,
              'totalMax': totalMax,
              'percentage': percentage,
              'grade': grade,
            },
          });

      notificationCount++;
      print('✅ Final result notification sent to parent of $studentName');
    }

    print('✅ Sent $notificationCount final result notifications');
  }

  Future<void> _saveMarks() async {
    if (_selectedExam == null || _selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select exam and subject first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final batch = FirebaseFirestore.instance.batch();

      final examDoc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('exams')
          .doc(_selectedExam)
          .get();

      if (!examDoc.exists) {
        throw Exception('Exam not found');
      }

      final examData = examDoc.data()!;
      final subjects = List<String>.from(examData['subjects'] ?? []);
      final maxMarksRaw = examData['maxMarks'] ?? [];
      final List<int> maxMarks = maxMarksRaw.map<int>((e) => (e as num).toInt()).toList();
      final subjectIndex = subjects.indexOf(_selectedSubject!);
      final maxMark = subjectIndex >= 0 && subjectIndex < maxMarks.length
          ? maxMarks[subjectIndex]
          : 100;

      String examName = '';
      for (var exam in _exams) {
        if (exam['id'] == _selectedExam) {
          examName = exam['name'];
          break;
        }
      }

      final existingResultsSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('exam_results')
          .where('examId', isEqualTo: _selectedExam)
          .where('subject', isEqualTo: _selectedSubject)
          .get();

      final Map<String, QueryDocumentSnapshot> existingResultsMap = {};
      for (var doc in existingResultsSnapshot.docs) {
        final data = doc.data();
        if (data['studentId'] != null) {
          existingResultsMap[data['studentId']] = doc;
        }
      }

      int savedCount = 0;

      for (var student in _students) {
        final studentId = student['id'];
        final marksText = _marksControllers[studentId]?.text.trim() ?? '';

        if (marksText.isEmpty) continue;

        final marksObtained = int.tryParse(marksText);
        if (marksObtained == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Invalid marks for ${student['name']}'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          continue;
        }

        if (marksObtained < 0 || marksObtained > maxMark) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Marks must be between 0 and $maxMark for ${student['name']}'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          continue;
        }

        final remarks = _remarksControllers[studentId]?.text.trim() ?? '';

        // =============================================
        // FIXED LINE 456 - Convert to double explicitly
        // =============================================
        final percentage = (marksObtained / maxMark) * 100.0;
        final grade = _calculateGrade(percentage);

        final resultData = {
          'examId': _selectedExam,
          'examName': examName,
          'studentId': studentId,
          'studentName': student['name'],
          'rollNo': student['rollNo'],
          'className': _selectedClass,
          'section': _selectedSection,
          'subject': _selectedSubject,
          'marksObtained': marksObtained,
          'maxMarks': maxMark,
          'percentage': percentage,
          'grade': grade,
          'remarks': remarks,
          'uploadedBy': FirebaseAuth.instance.currentUser!.uid,
          'uploadedByRole': 'teacher',
          'uploadedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (existingResultsMap.containsKey(studentId)) {
          batch.update(existingResultsMap[studentId]!.reference, resultData);
        } else {
          final resultRef = FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('exam_results')
              .doc();
          batch.set(resultRef, resultData);
        }
        savedCount++;
      }

      await batch.commit();

      final examRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('exams')
          .doc(_selectedExam);

      final examSnapshot = await examRef.get();
      List<String> completedSubjects = List.from(examSnapshot.data()?['completedSubjects'] ?? []);

      if (!completedSubjects.contains(_selectedSubject)) {
        completedSubjects.add(_selectedSubject!);
        await examRef.update({
          'completedSubjects': completedSubjects,
          'marksEntered': completedSubjects.length,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $savedCount marks saved!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadStudents();
      }
    } catch (e) {
      debugPrint('Error saving marks: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
  String _getGradeEmoji(String grade) {
    switch (grade) {
      case 'A+':
        return 'Outstanding';
      case 'A':
        return 'Excellent';
      case 'B':
        return 'Very Good';
      case 'C':
        return 'Good';
      case 'D':
        return 'Average';
      default:
        return 'Keep Trying';
    }
  }

  String _calculateGrade(num percentage) {
    if (percentage >= 90.0) return 'A+';
    if (percentage >= 80.0) return 'A';
    if (percentage >= 70.0) return 'B';
    if (percentage >= 60.0) return 'C';
    if (percentage >= 50.0) return 'D';
    return 'F';
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Upload Exam Marks'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_selectedSubject != null && _selectedExam != null) {
                _loadStudents();
              } else if (_selectedClass != null) {
                _loadExams();
              }
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildClassSelector(),
                    const SizedBox(height: 16),
                    if (_selectedClass != null) _buildSectionSelector(),
                    const SizedBox(height: 16),
                    if (_selectedSection != null) _buildExamSelector(),
                    const SizedBox(height: 16),
                    if (_selectedExam != null) _buildSubjectSelector(),
                    const SizedBox(height: 24),
                    if (_selectedSubject != null &&
                        _students.isNotEmpty &&
                        !_isLoadingStudents)
                      _buildMarksTable(),
                    if (_isLoadingStudents)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    const SizedBox(height: 24),
                    if (_selectedSubject != null &&
                        _students.isNotEmpty &&
                        !_isLoadingStudents)
                      _buildSaveButton(),
                    // Publish Final Results Button (appears when all subjects completed)
                    if (_selectedExam != null && !_isLoadingStudents)
                      FutureBuilder<bool>(
                        future: _areAllSubjectsCompleted(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox();
                          }
                          final allCompleted = snapshot.data == true;
                          if (allCompleted) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _isPublishing
                                          ? null
                                          : _publishFinalResults,
                                  icon:
                                      _isPublishing
                                          ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                          : const Icon(Icons.send),
                                  label: Text(
                                    _isPublishing
                                        ? "Publishing..."
                                        : "📢 Publish Final Results",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    if (_selectedSubject != null &&
                        _students.isEmpty &&
                        !_isLoading &&
                        !_isLoadingStudents)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: _cardDecoration(),
                        child: const Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 12),
                              Text('No students found in this class/section'),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
    );
  }

  // Rest of the UI methods (_buildClassSelector, _buildSectionSelector, etc.)
  // ... (keep all your existing UI methods)

  Widget _buildClassSelector() {
    if (_availableClasses.isEmpty && !_isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: const Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.orange),
            SizedBox(height: 12),
            Text('No classes assigned to you'),
            SizedBox(height: 8),
            Text(
              'Please contact the admin to assign classes',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Class',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedClass,
            hint: const Text('Choose Class'),
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items:
                _availableClasses.map<DropdownMenuItem<String>>((className) {
                  return DropdownMenuItem<String>(
                    value: className,
                    child: Text(className),
                  );
                }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedClass = value;
                _selectedSection = null;
                _selectedExam = null;
                _selectedSubject = null;
                _students.clear();
                _marksControllers.clear();
                _remarksControllers.clear();
                _exams.clear();
                _availableSections.clear();
              });
              if (value != null) {
                _loadExams();
                _loadSections();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionSelector() {
    return FutureBuilder<QuerySnapshot>(
      future:
          FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('students')
              .where('class', isEqualTo: _selectedClass)
              .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final sections =
            snapshot.data!.docs
                .map((doc) => doc['section'] as String)
                .where((section) => section != null && section.isNotEmpty)
                .toSet()
                .toList()
              ..sort();

        if (sections.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: const Center(
              child: Text('No sections found for this class'),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Section',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedSection,
                hint: const Text('Choose Section'),
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items:
                    sections.map<DropdownMenuItem<String>>((section) {
                      return DropdownMenuItem<String>(
                        value: section,
                        child: Text('Section $section'),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSection = value;
                    _selectedExam = null;
                    _selectedSubject = null;
                    _students.clear();
                    _marksControllers.clear();
                    _remarksControllers.clear();
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExamSelector() {
    if (_isLoadingExams) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_exams.isEmpty && !_isLoadingExams) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: const Center(child: Text('No exams available for this class')),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Exam',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedExam,
            hint: const Text('Choose Exam'),
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items:
                _exams.map<DropdownMenuItem<String>>((exam) {
                  return DropdownMenuItem<String>(
                    value: exam['id'] as String,
                    child: Text('${exam['name']} (${exam['type']})'),
                  );
                }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedExam = value;
                _selectedSubject = null;
                _students.clear();
                _marksControllers.clear();
                _remarksControllers.clear();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectSelector() {
    Map<String, dynamic>? exam;
    for (var e in _exams) {
      if (e['id'] == _selectedExam) {
        exam = e;
        break;
      }
    }

    if (exam == null) return const SizedBox.shrink();

    final subjects = exam['subjects'] as List<String>? ?? [];

    if (subjects.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: const Center(child: Text('No subjects found for this exam')),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Subject',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedSubject,
            hint: const Text('Choose Subject'),
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items:
                subjects.map<DropdownMenuItem<String>>((subject) {
                  return DropdownMenuItem<String>(
                    value: subject,
                    child: Text(subject),
                  );
                }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedSubject = value;
              });
              _loadStudents();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMarksTable() {
    int maxMark = 100;
    for (var exam in _exams) {
      if (exam['id'] == _selectedExam) {
        final subjects = exam['subjects'] as List<String>? ?? [];
        final maxMarks = exam['maxMarks'] as List<int>? ?? [];
        final subjectIndex = subjects.indexOf(_selectedSubject!);
        if (subjectIndex >= 0 && subjectIndex < maxMarks.length) {
          maxMark = maxMarks[subjectIndex];
        }
        break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Enter Marks',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Max Marks: $maxMark',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Total: ${_students.length}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    'Roll No',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Student Name',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    'Marks',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Remarks',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _students.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final student = _students[index];
              final studentId = student['id'];
              final marksController = _marksControllers[studentId];
              final remarksController = _remarksControllers[studentId];

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(
                        student['rollNo'].toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        student['name'],
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: marksController,
                        decoration: InputDecoration(
                          hintText: '0-$maxMark',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: remarksController,
                        decoration: const InputDecoration(
                          hintText: 'Optional',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Enter marks for each student. Grades (A+, A, B, C, D, F) will be calculated automatically based on percentage.',
                    style: TextStyle(fontSize: 11, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveMarks,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
                : const Text(
                  'Save Marks',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
