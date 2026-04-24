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
          if (classInfo is Map && classInfo.containsKey('className')) {
            _availableClasses.add(classInfo['className']);
          }
        }
        _availableClasses = _availableClasses.toSet().toList();
      }

      // Set from widget params if provided
      if (widget.selectedClass != null) {
        setState(() {
          _selectedClass = widget.selectedClass;
        });
        await _loadExams();

        if (widget.selectedSection != null) {
          setState(() {
            _selectedSection = widget.selectedSection;
          });

          if (widget.examId != null) {
            setState(() {
              _selectedExam = widget.examId;
            });

            if (widget.subject != null) {
              setState(() {
                _selectedSubject = widget.subject;
              });
              await _loadStudents();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading teacher data: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadExams() async {
    if (_selectedClass == null) return;

    setState(() => _isLoading = true);

    try {
      final examsSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('exams')
          .where('className', isEqualTo: _selectedClass)
          .get();

      _exams = examsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['examName'] ?? data['name'] ?? 'Unknown Exam',
          'type': data['examType'] ?? 'Regular',
          'subjects': List<String>.from(data['subjects'] ?? []),
          'maxMarks': List<int>.from(data['maxMarks'] ?? []),
        };
      }).toList();
    } catch (e) {
      debugPrint('Error loading exams: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadSections() async {
    if (_selectedClass == null) return;

    try {
      final studentsSnapshot = await FirebaseFirestore.instance
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
    if (_selectedClass == null || _selectedSection == null || _selectedExam == null || _selectedSubject == null) {
      return;
    }

    setState(() => _isLoading = true);

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
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('students')
          .where('class', isEqualTo: _selectedClass)
          .where('section', isEqualTo: _selectedSection)
          .get();

      // Load existing marks
      final marksSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('exam_results')
          .where('examId', isEqualTo: _selectedExam)
          .where('subject', isEqualTo: _selectedSubject)
          .get();

      _students = studentsSnapshot.docs.map((doc) {
        final data = doc.data();
        final studentId = doc.id;

        // Find existing mark for this student
        Map<String, dynamic>? existingMark;
        for (var markDoc in marksSnapshot.docs) {
          if (markDoc['studentId'] == studentId) {
            existingMark = markDoc.data();
            break;
          }
        }

        _marksControllers[studentId] = TextEditingController(
          text: existingMark != null ? existingMark['marksObtained']?.toString() ?? '' : '',
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
        final rollA = int.tryParse(a['rollNo']) ?? 0;
        final rollB = int.tryParse(b['rollNo']) ?? 0;
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

    setState(() => _isLoading = false);
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
      final maxMarks = List<int>.from(examData['maxMarks'] ?? []);
      final subjectIndex = subjects.indexOf(_selectedSubject!);
      final maxMark = subjectIndex >= 0 && subjectIndex < maxMarks.length
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

      for (var student in _students) {
        final studentId = student['id'];
        final marksText = _marksControllers[studentId]?.text.trim() ?? '';

        if (marksText.isEmpty) continue;

        final marksObtained = int.tryParse(marksText);
        if (marksObtained == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid marks for ${student['name']}'),
              backgroundColor: Colors.orange,
            ),
          );
          continue;
        }

        final remarks = _remarksControllers[studentId]?.text.trim() ?? '';
        final percentage = (marksObtained / maxMark) * 100;
        final grade = _calculateGrade(percentage);

        // Check if result already exists
        final existingResults = await FirebaseFirestore.instance
            .collection('schools')
            .doc(AppConfig.schoolId)
            .collection('exam_results')
            .where('examId', isEqualTo: _selectedExam)
            .where('studentId', isEqualTo: studentId)
            .where('subject', isEqualTo: _selectedSubject)
            .get();

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
          'uploadedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (existingResults.docs.isNotEmpty) {
          // Update existing result
          batch.update(
            existingResults.docs.first.reference,
            resultData,
          );
        } else {
          // Create new result
          final resultRef = FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('exam_results')
              .doc();
          batch.set(resultRef, resultData);
        }
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marks saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Error saving marks: $e');
    }

    setState(() => _isSaving = false);
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
              setState(() {});
              if (_selectedSubject != null) {
                _loadStudents();
              }
            },
          ),
        ],
      ),
      body: _isLoading
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
            if (_selectedSubject != null && _students.isNotEmpty)
              _buildMarksTable(),
            const SizedBox(height: 24),
            if (_selectedSubject != null && _students.isNotEmpty)
              _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildClassSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Class', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedClass,
            hint: const Text('Choose Class'),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _availableClasses.map<DropdownMenuItem<String>>((className) {
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
              });
              _loadExams();
              _loadSections();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionSelector() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('students')
          .where('class', isEqualTo: _selectedClass)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final sections = snapshot.data!.docs
            .map((doc) => doc['section'] as String)
            .where((section) => section.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Section', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedSection,
                hint: const Text('Choose Section'),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: sections.map<DropdownMenuItem<String>>((section) {
                  return DropdownMenuItem<String>(
                    value: section,
                    child: Text(section),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Exam', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedExam,
            hint: const Text('Choose Exam'),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _exams.map<DropdownMenuItem<String>>((exam) {
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
        child: const Center(
          child: Text('No subjects found for this exam'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Subject', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedSubject,
            hint: const Text('Choose Subject'),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: subjects.map<DropdownMenuItem<String>>((subject) {
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
              Text(
                'Total Students: ${_students.length}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                SizedBox(width: 60, child: Text('Roll No', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold))),
                SizedBox(width: 100, child: Text('Marks', style: TextStyle(fontWeight: FontWeight.bold))),
                SizedBox(width: 8),
                Expanded(flex: 2, child: Text('Remarks', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _students.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final student = _students[index];
              final studentId = student['id'];
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(
                        student['rollNo'],
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
                        controller: _marksControllers[studentId],
                        decoration: const InputDecoration(
                          hintText: 'Marks',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _remarksControllers[studentId],
                        decoration: const InputDecoration(
                          hintText: 'Remarks',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            },
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
        child: _isSaving
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
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}