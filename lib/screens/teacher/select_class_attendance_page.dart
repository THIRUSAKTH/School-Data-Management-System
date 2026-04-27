import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:schoolprojectjan/app_config.dart';
import 'package:schoolprojectjan/screens/teacher/teacher_add_student_page.dart';
import 'mark_attendance_page.dart';

class SelectClassAttendancePage extends StatefulWidget {
  final String schoolId;

  const SelectClassAttendancePage({
    super.key,
    required this.schoolId,
  });

  @override
  State<SelectClassAttendancePage> createState() =>
      _SelectClassAttendancePageState();
}

class _SelectClassAttendancePageState extends State<SelectClassAttendancePage> {
  final classController = TextEditingController();
  final sectionController = TextEditingController();

  List<String> _availableClasses = [];
  List<String> _availableSections = [];
  bool _isLoadingClasses = true;

  String? _selectedClass;
  String? _selectedSection;

  @override
  void initState() {
    super.initState();
    _loadAvailableClasses();
  }

  @override
  void dispose() {
    classController.dispose();
    sectionController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableClasses() async {
    setState(() => _isLoadingClasses = true);

    try {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('students')
          .get();

      final Set<String> classesSet = {};
      final Map<String, Set<String>> classSectionsMap = {};

      for (var doc in studentsSnapshot.docs) {
        final data = doc.data();
        final className = data['class'] as String?;
        final section = data['section'] as String?;

        if (className != null && className.isNotEmpty) {
          classesSet.add(className);

          if (section != null && section.isNotEmpty) {
            if (!classSectionsMap.containsKey(className)) {
              classSectionsMap[className] = {};
            }
            classSectionsMap[className]!.add(section);
          }
        }
      }

      setState(() {
        _availableClasses = classesSet.toList()..sort();
        _isLoadingClasses = false;
      });
    } catch (e) {
      debugPrint('Error loading classes: $e');
      setState(() => _isLoadingClasses = false);
    }
  }

  Future<void> _loadSectionsForClass(String className) async {
    setState(() {
      _availableSections = [];
      _selectedSection = null;
      sectionController.clear();
    });

    try {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('students')
          .where('class', isEqualTo: className)
          .get();

      final Set<String> sectionsSet = {};

      for (var doc in studentsSnapshot.docs) {
        final data = doc.data();
        final section = data['section'] as String?;
        if (section != null && section.isNotEmpty) {
          sectionsSet.add(section);
        }
      }

      setState(() {
        _availableSections = sectionsSet.toList()..sort();
      });
    } catch (e) {
      debugPrint('Error loading sections: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Mark Attendance",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 24),
            _buildClassSelector(),
            const SizedBox(height: 20),
            _buildSectionSelector(),
            const SizedBox(height: 30),
            _buildRecentAttendanceCard(),
            const SizedBox(height: 20),
            _buildSubmitButton(),
            // Add this after _buildSubmitButton() in the Column

            const SizedBox(height: 12),

// Add Student Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  String className = classController.text.trim();
                  String section = sectionController.text.trim().toUpperCase();

                  if (className.isEmpty || section.isEmpty) {
                    _showErrorSnackBar("Please select class and section first");
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TeacherAddStudentPage(
                        className: className,
                        section: section,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.person_add),
                label: const Text(
                  "Add New Student to this Class",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.green, Colors.greenAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.checklist, size: 50, color: Colors.white),
          const SizedBox(height: 12),
          const Text(
            "Mark Student Attendance",
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Select class and section to mark today's attendance",
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
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
          const Row(
            children: [
              Icon(Icons.class_, color: Colors.green),
              SizedBox(width: 8),
              Text("Select Class", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingClasses)
            const Center(child: CircularProgressIndicator())
          else if (_availableClasses.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
              child: const Column(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange),
                  SizedBox(height: 8),
                  Text("No classes found.\nPlease add students first.", textAlign: TextAlign.center, style: TextStyle(color: Colors.orange)),
                ],
              ),
            )
          else
            Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedClass,
                  hint: const Text("Select Class"),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    prefixIcon: const Icon(Icons.school),
                  ),
                  items: _availableClasses.map((className) {
                    return DropdownMenuItem(value: className, child: Text(className));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedClass = value;
                      classController.text = value ?? '';
                      if (value != null) {
                        _loadSectionsForClass(value);
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: classController,
                  decoration: InputDecoration(
                    labelText: "Or Enter Class Manually",
                    hintText: "e.g., Class 5, Grade 10",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _selectedClass = null;
                    });
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSectionSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.group, color: Colors.green),
              SizedBox(width: 8),
              Text("Select Section", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          if (_selectedClass != null && _availableSections.isNotEmpty)
            DropdownButtonFormField<String>(
              value: _selectedSection,
              hint: const Text("Select Section"),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
                prefixIcon: const Icon(Icons.group),
              ),
              items: _availableSections.map((section) {
                return DropdownMenuItem(value: section, child: Text(section));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSection = value;
                  sectionController.text = value ?? '';
                });
              },
            )
          else
            TextFormField(
              controller: sectionController,
              decoration: InputDecoration(
                labelText: "Enter Section",
                hintText: "e.g., A, B, C",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
                prefixIcon: const Icon(Icons.group),
              ),
              onChanged: (value) {
                setState(() {
                  _selectedSection = null;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRecentAttendanceCard() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('attendance_summary')
          .orderBy('date', descending: true)
          .limit(5)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.history, color: Colors.green),
                  SizedBox(width: 8),
                  Text("Recent Attendance", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              ...snapshot.data!.docs.take(3).map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final dateStr = data['date'] ?? '';
                final className = data['className'] ?? '';
                final section = data['section'] ?? '';
                final present = data['present'] ?? 0;
                final total = data['totalStudents'] ?? 0;
                final rate = total > 0 ? (present / total) * 100 : 0;

                // FIXED: Safely parse date
                String formattedDate = '';
                if (dateStr.isNotEmpty) {
                  try {
                    final date = DateFormat('yyyy-MM-dd').parse(dateStr);
                    formattedDate = DateFormat('dd MMM yyyy').format(date);
                  } catch (e) {
                    formattedDate = dateStr;
                  }
                }

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    child: Text(present.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ),
                  title: Text("$className - $section"),
                  subtitle: Text(formattedDate),
                  trailing: Text(
                    "${rate.toStringAsFixed(0)}%",
                    style: TextStyle(fontWeight: FontWeight.bold, color: rate >= 75 ? Colors.green : Colors.orange),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _validateAndNavigate,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        child: const Text(
          "Load Students & Mark Attendance",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _validateAndNavigate() async {
    String className = classController.text.trim();
    String section = sectionController.text.trim().toUpperCase();

    if (className.isEmpty) {
      _showErrorSnackBar("Please enter or select a class");
      return;
    }

    if (section.isEmpty) {
      _showErrorSnackBar("Please enter or select a section");
      return;
    }

    setState(() => _isLoadingClasses = true);

    try {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('students')
          .where('class', isEqualTo: className)
          .where('section', isEqualTo: section)
          .limit(1)
          .get();

      if (studentsSnapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("No students found in $className - $section", style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        setState(() => _isLoadingClasses = false);
        return;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MarkAttendancePage(
              schoolId: widget.schoolId,
              className: className,
              section: section,
            ),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar("Error: $e");
    } finally {
      setState(() => _isLoadingClasses = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
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
          offset: const Offset(0, 2.1),
        ),
      ],
    );
  }
}