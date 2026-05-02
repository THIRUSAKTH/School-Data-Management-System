import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:schoolprojectjan/app_config.dart';

class StudentTimetablePage extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String className;
  final String section;

  const StudentTimetablePage({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.section,
  });

  @override
  State<StudentTimetablePage> createState() => _StudentTimetablePageState();
}

class _StudentTimetablePageState extends State<StudentTimetablePage> {
  String _selectedDay = _getCurrentDay();
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
    _loadPeriodTimings();
    _loadTimetable();
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

  Future<void> _loadTimetable() async {
    setState(() => _isLoading = true);

    try {
      final entries =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('timetable')
              .where('class', isEqualTo: widget.className)
              .where('section', isEqualTo: widget.section)
              .get();

      Map<String, List<Map<String, dynamic>>> timetable = {};

      for (var doc in entries.docs) {
        final data = doc.data();
        final day = data['day'] as String;
        final period = data['period'] as int;

        if (!timetable.containsKey(day)) {
          timetable[day] = [];
        }

        timetable[day]!.add({
          'period': period,
          'subject': data['subject'],
          'teacherName': data['teacherName'],
          'startTime': data['startTime'],
          'endTime': data['endTime'],
          'isCustomSubject': data['isCustomSubject'] ?? false,
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Class Timetable",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              "${widget.className} - ${widget.section}",
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.deepPurple,
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
                  _buildStudentInfoCard(),
                  _buildDaySelector(),
                  Expanded(child: _buildTimetableContent()),
                ],
              ),
    );
  }

  Widget _buildStudentInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.deepPurple, Colors.purple],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white,
            child: Icon(Icons.school, size: 30, color: Colors.deepPurple),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.studentName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Class ${widget.className} - ${widget.section}",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                color: isSelected ? Colors.deepPurple : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
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
            const SizedBox(height: 8),
            Text(
              "Enjoy your free day! 🎉",
              style: TextStyle(color: Colors.grey.shade500),
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
    final isCustomSubject = entry['isCustomSubject'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            isCustomSubject ? Border.all(color: Colors.orange.shade300) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple,
          child: Text(
            period.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                "${entry['subject']} (Period $period)",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (isCustomSubject)
              const Icon(Icons.star, size: 16, color: Colors.orange),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Time: $startTime - $endTime"),
            const SizedBox(height: 4),
            Text("Teacher: ${entry['teacherName']}"),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            entry['subject'],
            style: TextStyle(
              color: Colors.deepPurple.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
