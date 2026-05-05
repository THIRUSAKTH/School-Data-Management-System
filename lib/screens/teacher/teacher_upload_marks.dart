import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

        // Try multiple field names for assigned classes
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

      // Set from widget params if provided
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

      // Sort exams by date (newest first or by creation)
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

    // Dispose old controllers
    for (var controller in _marksControllers.values) {
      controller.dispose();
    }
    for (var controller in _remarksControllers.values) {
      controller.dispose();
    }
    _marksControllers.clear();
    _remarksControllers.clear();

    try {
      // Load students
      final studentsSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('students')
              .where('class', isEqualTo: _selectedClass)
              .where('section', isEqualTo: _selectedSection)
              .get();

      // Load existing marks from exam_results collection
      final marksSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('exam_results')
              .where('examId', isEqualTo: _selectedExam)
              .where('subject', isEqualTo: _selectedSubject)
              .get();

      // Create a map of existing marks by studentId
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

      // Get exam details for max marks
      final examDoc =
          await FirebaseFirestore.instance
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
      final List<int> maxMarks =
          maxMarksRaw.map<int>((e) => (e as num).toInt()).toList();
      final subjectIndex = subjects.indexOf(_selectedSubject!);
      final maxMark =
          subjectIndex >= 0 && subjectIndex < maxMarks.length
              ? maxMarks[subjectIndex]
              : 100;

      // Get exam name
      String examName = '';
      for (var exam in _exams) {
        if (exam['id'] == _selectedExam) {
          examName = exam['name'];
          break;
        }
      }

      // Get existing results to check for updates vs inserts
      final existingResultsSnapshot =
          await FirebaseFirestore.instance
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

        // Validate marks range
        if (marksObtained < 0 || marksObtained > maxMark) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Marks must be between 0 and $maxMark for ${student['name']}',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
          continue;
        }

        final remarks = _remarksControllers[studentId]?.text.trim() ?? '';
        final percentage = (marksObtained / maxMark) * 100;
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
          final resultRef =
              FirebaseFirestore.instance
                  .collection('schools')
                  .doc(AppConfig.schoolId)
                  .collection('exam_results')
                  .doc();
          batch.set(resultRef, resultData);
        }
        savedCount++;
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $savedCount marks saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the data to show updated marks
        await _loadStudents();
      }
    } catch (e) {
      debugPrint('Error saving marks: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }

    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  String _calculateGrade(double percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B';
    if (percentage >= 60) return 'C';
    if (percentage >= 50) return 'D';
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
    // Get max marks for the selected subject
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

          // Table Header
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

          // Student List
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

          // Instructions
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
