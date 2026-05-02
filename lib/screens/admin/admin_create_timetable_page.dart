import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminCreateTimetablePage extends StatefulWidget {
  final String schoolId;

  const AdminCreateTimetablePage({super.key, required this.schoolId});

  @override
  State<AdminCreateTimetablePage> createState() =>
      _AdminCreateTimetablePageState();
}

class _AdminCreateTimetablePageState extends State<AdminCreateTimetablePage> {
  String selectedDay = "Monday";
  int selectedPeriod = 1;
  String selectedTeacherId = "";
  String selectedTeacherName = "";
  String selectedClass = "";
  String selectedSection = "";
  String selectedSubject = "";
  bool _isLoading = false;
  final TextEditingController _customSubjectController =
      TextEditingController();

  Map<int, Map<String, String>> _periodTimings = {
    1: {'start': '09:00 AM', 'end': '10:00 AM'},
    2: {'start': '10:00 AM', 'end': '11:00 AM'},
    3: {'start': '11:00 AM', 'end': '12:00 PM'},
    4: {'start': '12:00 PM', 'end': '01:00 PM'},
    5: {'start': '01:00 PM', 'end': '02:00 PM'},
    6: {'start': '02:00 PM', 'end': '03:00 PM'},
    7: {'start': '03:00 PM', 'end': '04:00 PM'},
    8: {'start': '04:00 PM', 'end': '05:00 PM'},
  };

  final List<String> defaultSubjects = [
    "Mathematics",
    "Physics",
    "Chemistry",
    "Biology",
    "English",
    "Tamil",
    "Social Science",
    "Computer Science",
    "Physical Education",
    "Art",
    "Music",
    "Hindi",
  ];

  List<String> _customSubjects = [];

  List<String> get allSubjects => [...defaultSubjects, ..._customSubjects];

  final List<String> classes = [
    "LKG",
    "UKG",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "10",
    "11",
    "12",
  ];
  final List<String> sections = ["A", "B", "C", "D"];
  final List<String> days = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
  ];
  final List<int> periods = List.generate(8, (i) => i + 1);

  @override
  void initState() {
    super.initState();
    _loadCustomSubjects();
    _loadPeriodTimings();
  }

  @override
  void dispose() {
    _customSubjectController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomSubjects() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('settings')
              .doc('subjects')
              .get();

      if (doc.exists && doc.data()?['customSubjects'] != null) {
        if (mounted) {
          setState(() {
            _customSubjects = List<String>.from(doc.data()!['customSubjects']);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading custom subjects: $e');
    }
  }

  Future<void> _loadPeriodTimings() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('settings')
              .doc('period_timings')
              .get();

      if (doc.exists && doc.data()?['timings'] != null) {
        final data = doc.data()!['timings'] as Map<String, dynamic>;
        for (var entry in data.entries) {
          final period = int.parse(entry.key);
          final timings = entry.value as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _periodTimings[period] = {
                'start': timings['start'] ?? _periodTimings[period]!['start']!,
                'end': timings['end'] ?? _periodTimings[period]!['end']!,
              };
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading period timings: $e');
    }
  }

  Future<void> _savePeriodTimings() async {
    final timingsMap = <String, Map<String, String>>{};
    for (var entry in _periodTimings.entries) {
      timingsMap[entry.key.toString()] = {
        'start': entry.value['start']!,
        'end': entry.value['end']!,
      };
    }

    await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('settings')
        .doc('period_timings')
        .set({
          'timings': timingsMap,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  void _showPeriodTimingDialog() {
    final currentTimings = _periodTimings[selectedPeriod]!;
    TimeOfDay tempStart = _parseTimeOfDay(currentTimings['start']!);
    TimeOfDay tempEnd = _parseTimeOfDay(currentTimings['end']!);

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text("Period $selectedPeriod Timings"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Set custom start and end time for this period",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(
                        Icons.play_arrow,
                        color: Colors.green,
                      ),
                      title: const Text("Start Time"),
                      subtitle: Text(_formatTimeOfDay(tempStart)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: tempStart,
                        );
                        if (picked != null) {
                          setDialogState(() {
                            tempStart = picked;
                          });
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.stop, color: Colors.red),
                      title: const Text("End Time"),
                      subtitle: Text(_formatTimeOfDay(tempEnd)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: tempEnd,
                        );
                        if (picked != null) {
                          setDialogState(() {
                            tempEnd = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _periodTimings[selectedPeriod] = {
                          'start': _formatTimeOfDay(tempStart),
                          'end': _formatTimeOfDay(tempEnd),
                        };
                      });
                      _savePeriodTimings();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Period $selectedPeriod timing updated!",
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Save"),
                  ),
                ],
              );
            },
          ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? "AM" : "PM";
    return "$hour:$minute $period";
  }

  TimeOfDay _parseTimeOfDay(String timeStr) {
    try {
      final parts = timeStr.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final isPM = parts[1] == 'PM';

      if (isPM && hour != 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  Future<void> _saveCustomSubject(String subject) async {
    if (subject.trim().isEmpty) return;
    if (_customSubjects.contains(subject.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Subject already exists!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _customSubjects.add(subject.trim());
      _customSubjectController.clear();
    });

    try {
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('settings')
          .doc('subjects')
          .set({
            'customSubjects': _customSubjects,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Custom subject added successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saving subject: $e"),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _customSubjects.remove(subject.trim()));
    }
  }

  void _showAddSubjectDialog() {
    _customSubjectController.clear();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text("Add Custom Subject"),
            content: TextField(
              controller: _customSubjectController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: "e.g., Economics, Psychology, etc.",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_customSubjectController.text.isNotEmpty) {
                    _saveCustomSubject(_customSubjectController.text);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Add"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          "Create Timetable",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.cyan,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildFormCard(),
                    const SizedBox(height: 20),
                    _buildExistingEntriesCard(),
                  ],
                ),
              ),
    );
  }

  Widget _buildFormCard() {
    final currentTimings = _periodTimings[selectedPeriod]!;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Add Timetable Entry",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Day Selector
            DropdownButtonFormField<String>(
              value: selectedDay,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: "Select Day",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today, color: Colors.cyan),
                filled: true,
                fillColor: Colors.white,
              ),
              items:
                  days
                      .map(
                        (day) => DropdownMenuItem(value: day, child: Text(day)),
                      )
                      .toList(),
              onChanged: (v) => setState(() => selectedDay = v!),
            ),
            const SizedBox(height: 16),

            // Period Selector
            DropdownButtonFormField<int>(
              value: selectedPeriod,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: "Select Period",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.timer, color: Colors.cyan),
                filled: true,
                fillColor: Colors.white,
              ),
              items:
                  periods
                      .map(
                        (period) => DropdownMenuItem(
                          value: period,
                          child: Text("Period $period"),
                        ),
                      )
                      .toList(),
              onChanged: (v) => setState(() => selectedPeriod = v!),
            ),
            const SizedBox(height: 8),

            // Timing Display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.cyan.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: Colors.cyan.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Period Timing",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.cyan.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${currentTimings['start']} - ${currentTimings['end']}",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.cyan.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showPeriodTimingDialog,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text("Edit"),
                    style: TextButton.styleFrom(foregroundColor: Colors.cyan),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Subject Selector
            DropdownButtonFormField<String>(
              value: selectedSubject.isEmpty ? null : selectedSubject,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: "Select Subject",
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.book, color: Colors.cyan),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.cyan),
                  onPressed: _showAddSubjectDialog,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              items:
                  allSubjects
                      .map(
                        (subject) => DropdownMenuItem(
                          value: subject,
                          child: Text(subject),
                        ),
                      )
                      .toList(),
              onChanged: (value) => setState(() => selectedSubject = value!),
            ),
            const SizedBox(height: 16),

            // Class Selector
            DropdownButtonFormField<String>(
              value: selectedClass.isEmpty ? null : selectedClass,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: "Select Class",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.class_, color: Colors.cyan),
                filled: true,
                fillColor: Colors.white,
              ),
              items:
                  classes
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c, child: Text("Class $c")),
                      )
                      .toList(),
              onChanged: (value) => setState(() => selectedClass = value!),
            ),
            const SizedBox(height: 16),

            // Section Selector
            DropdownButtonFormField<String>(
              value: selectedSection.isEmpty ? null : selectedSection,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: "Select Section",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.group, color: Colors.cyan),
                filled: true,
                fillColor: Colors.white,
              ),
              items:
                  sections
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text("Section $s"),
                        ),
                      )
                      .toList(),
              onChanged: (value) => setState(() => selectedSection = value!),
            ),
            const SizedBox(height: 16),

            // Teacher Selector
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('schools')
                      .doc(widget.schoolId)
                      .collection('teachers')
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Loading teachers...",
                    ),
                    items: [],
                    onChanged: null,
                    isExpanded: true,
                  );
                }
                final teachers = snapshot.data!.docs;
                return DropdownButtonFormField<String>(
                  value: selectedTeacherId.isEmpty ? null : selectedTeacherId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: "Select Teacher",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person, color: Colors.cyan),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items:
                      teachers.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text(data['name'] ?? 'Unknown Teacher'),
                        );
                      }).toList(),
                  onChanged: (value) {
                    final doc = teachers.firstWhere((e) => e.id == value);
                    final data = doc.data() as Map<String, dynamic>;
                    setState(() {
                      selectedTeacherId = value!;
                      selectedTeacherName = data['name'] ?? '';
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saveTimetable,
                icon: const Icon(Icons.save),
                label: const Text("Save Timetable Entry"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.white,
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

  Widget _buildExistingEntriesCard() {
    if (selectedClass.isEmpty || selectedSection.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: const Center(
            child: Text(
              "Select a class and section to view existing entries",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Existing Timetable Entries",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('schools')
                      .doc(widget.schoolId)
                      .collection('timetable')
                      .where('class', isEqualTo: selectedClass)
                      .where('section', isEqualTo: selectedSection)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final entries = snapshot.data!.docs;
                if (entries.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text("No entries found"),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final data = entries[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getDayColor(data['day']),
                        child: Text(data['period']?.toString() ?? ''),
                      ),
                      title: Text("${data['day']} - Period ${data['period']}"),
                      subtitle: Text(
                        "${data['subject']} | ${data['teacherName']}",
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteEntry(entries[index].id),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTimetable() async {
    if (selectedDay.isEmpty ||
        selectedClass.isEmpty ||
        selectedSection.isEmpty ||
        selectedSubject.isEmpty ||
        selectedTeacherId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final timings = _periodTimings[selectedPeriod]!;

      final existingQuery =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('timetable')
              .where('day', isEqualTo: selectedDay)
              .where('period', isEqualTo: selectedPeriod)
              .where('class', isEqualTo: selectedClass)
              .where('section', isEqualTo: selectedSection)
              .get();

      if (existingQuery.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Entry already exists for Period $selectedPeriod on $selectedDay",
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('timetable')
          .add({
            "day": selectedDay,
            "period": selectedPeriod,
            "startTime": timings['start'],
            "endTime": timings['end'],
            "class": selectedClass,
            "section": selectedSection,
            "subject": selectedSubject,
            "isCustomSubject": _customSubjects.contains(selectedSubject),
            "teacherId": selectedTeacherId,
            "teacherName": selectedTeacherName,
            "createdAt": FieldValue.serverTimestamp(),
          });

      final teacherDocRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('teacher_timetable')
          .doc(selectedTeacherId);

      await teacherDocRef.set({
        'teacherId': selectedTeacherId,
        'teacherName': selectedTeacherName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await teacherDocRef
          .collection('entries')
          .doc(
            "${selectedDay}_${selectedPeriod}_${selectedClass}_${selectedSection}",
          )
          .set({
            "day": selectedDay,
            "period": selectedPeriod,
            "startTime": timings['start'],
            "endTime": timings['end'],
            "class": selectedClass,
            "section": selectedSection,
            "subject": selectedSubject,
            "isCustomSubject": _customSubjects.contains(selectedSubject),
            "createdAt": FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Timetable entry saved successfully!"),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        selectedSubject = "";
        selectedTeacherId = "";
        selectedTeacherName = "";
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteEntry(String docId) async {
    await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('timetable')
        .doc(docId)
        .delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Entry deleted"),
        backgroundColor: Colors.green,
      ),
    );
  }

  Color _getDayColor(String day) {
    switch (day) {
      case "Monday":
        return Colors.blue;
      case "Tuesday":
        return Colors.green;
      case "Wednesday":
        return Colors.orange;
      case "Thursday":
        return Colors.purple;
      case "Friday":
        return Colors.red;
      case "Saturday":
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
