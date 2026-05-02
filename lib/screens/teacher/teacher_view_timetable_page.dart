import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:schoolprojectjan/app_config.dart';

class TeacherViewTimetable extends StatefulWidget {
  const TeacherViewTimetable({super.key});

  @override
  State<TeacherViewTimetable> createState() => _TeacherViewTimetableState();
}

class _TeacherViewTimetableState extends State<TeacherViewTimetable> {
  String _selectedDay = _getCurrentDay();
  String? _teacherId;
  String? _teacherName;
  Map<String, List<Map<String, dynamic>>> _timetable = {};
  bool _isLoading = true;
  Map<int, Map<String, String>> _periodTimings = {};

  final List<String> _days = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
  ];

  static String _getCurrentDay() {
    final now = DateTime.now();
    const days = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ];
    return days[now.weekday - 1];
  }

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
    _loadPeriodTimings();
  }

  Future<void> _loadPeriodTimings() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('settings')
              .doc('timetable_settings')
              .get();

      if (doc.exists && doc.data()?['periodTimings'] != null) {
        final data = doc.data()!['periodTimings'] as Map<String, dynamic>;
        for (var entry in data.entries) {
          final period = int.parse(entry.key);
          final timings = entry.value as Map<String, dynamic>;
          _periodTimings[period] = {
            'start': timings['start'] ?? 'N/A',
            'end': timings['end'] ?? 'N/A',
          };
        }
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading period timings: $e');
    }
  }

  Future<void> _loadTeacherData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final teacherQuery =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('teachers')
              .where('uid', isEqualTo: user.uid)
              .get();

      if (teacherQuery.docs.isNotEmpty) {
        setState(() {
          _teacherId = teacherQuery.docs.first.id;
          _teacherName = teacherQuery.docs.first.data()['name'];
        });
        _loadTimetable();
      }
    }
  }

  Future<void> _loadTimetable() async {
    if (_teacherId == null) return;
    setState(() => _isLoading = true);

    try {
      // Query from teacher_timetable collection
      final entriesSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('teacher_timetable')
              .doc(_teacherId)
              .collection('entries')
              .get();

      Map<String, List<Map<String, dynamic>>> timetable = {};

      for (var doc in entriesSnapshot.docs) {
        final data = doc.data();
        final day = data['day'] as String;
        final period = data['period'] as int;

        if (!timetable.containsKey(day)) {
          timetable[day] = [];
        }

        timetable[day]!.add({
          'period': period,
          'class': data['class'],
          'section': data['section'],
          'subject': data['subject'],
          'startTime': data['startTime'],
          'endTime': data['endTime'],
          'docId': doc.id,
        });
      }

      // Sort periods
      for (var day in timetable.keys) {
        timetable[day]!.sort((a, b) => a['period'].compareTo(b['period']));
      }

      setState(() {
        _timetable = timetable;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading timetable: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "My Timetable",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_teacherName != null)
              Text(_teacherName!, style: const TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTimetable,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  _buildDaySelector(),
                  Expanded(child: _buildTimetableContent()),
                ],
              ),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      height: 60,
      margin: const EdgeInsets.all(16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _days.length,
        itemBuilder: (context, index) {
          final day = _days[index];
          final isSelected = _selectedDay == day;
          final hasClasses =
              _timetable.containsKey(day) && _timetable[day]!.isNotEmpty;

          return GestureDetector(
            onTap: () => setState(() => _selectedDay = day),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.orange : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? Colors.orange : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  if (hasClasses)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    day,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimetableContent() {
    final dayEntries = _timetable[_selectedDay] ?? [];

    if (dayEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              "No classes scheduled for $_selectedDay",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dayEntries.length,
      itemBuilder: (context, index) {
        final entry = dayEntries[index];
        return _buildPeriodCard(entry);
      },
    );
  }

  Widget _buildPeriodCard(Map<String, dynamic> entry) {
    final period = entry['period'];
    final startTime =
        entry['startTime'] ?? _periodTimings[period]?['start'] ?? 'N/A';
    final endTime = entry['endTime'] ?? _periodTimings[period]?['end'] ?? 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange,
          child: Text(
            period.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          "Period $period - ${entry['subject']}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Time: $startTime - $endTime"),
            const SizedBox(height: 4),
            Text("Class: ${entry['class']} - ${entry['section']}"),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            entry['subject'],
            style: TextStyle(
              color: Colors.orange.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
