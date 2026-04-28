import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';
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

  final List<String> _days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

  static String _getCurrentDay() {
    final now = DateTime.now();
    const days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
    return days[now.weekday - 1];
  }

  @override
  void initState() {
    super.initState();
    _loadTimetable();
  }

  Future<void> _loadTimetable() async {
    setState(() => _isLoading = true);

    final entries = await FirebaseFirestore.instance
        .collection('schools')
        .doc(AppConfig.schoolId)
        .collection('timetable')
        .where('class', isEqualTo: widget.className)
        .where('section', isEqualTo: widget.section)
        .get();

    Map<String, List<Map<String, dynamic>>> timetable = {};

    for (var entry in entries.docs) {
      final data = entry.data();
      final day = data['day'] as String;
      final period = data['period'] as int;

      if (!timetable.containsKey(day)) {
        timetable[day] = [];
      }

      timetable[day]!.add({
        'period': period,
        'subject': data['subject'],
        'teacherName': data['teacherName'],
        'id': entry.id,
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
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTimetable,
            tooltip: "Refresh",
          ),
        ],
      ),
      body: _isLoading
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
          colors: [Colors.orange, Colors.deepOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white,
            child: Icon(Icons.school, size: 30, color: Colors.orange),
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
          final hasClasses = _timetable.containsKey(day) && _timetable[day]!.isNotEmpty;

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
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
                    : null,
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
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      itemBuilder: (context, period) {
        final periodNumber = period + 1;
        final entry = dayEntries.firstWhere(
              (e) => e['period'] == periodNumber,
          orElse: () => {},
        );

        return _buildPeriodCard(periodNumber, entry.isNotEmpty ? entry : null);
      },
    );
  }

  Widget _buildPeriodCard(int period, Map<String, dynamic>? entry) {
    final timeRange = _getTimeRange(period);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: entry != null ? Colors.orange : Colors.grey.shade200,
          child: Text(
            period.toString(),
            style: TextStyle(
              color: entry != null ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          entry != null ? "${entry['subject']} (Period $period)" : "Period $period - Free Period",
          style: TextStyle(
            fontWeight: entry != null ? FontWeight.bold : FontWeight.normal,
            color: entry != null ? Colors.black87 : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry != null) ...[
              Text(timeRange),
              const SizedBox(height: 4),
              Text("Teacher: ${entry['teacherName']}"),
            ] else
              Text(timeRange),
          ],
        ),
        trailing: entry != null
            ? Container(
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
              fontSize: 12,
            ),
          ),
        )
            : null,
      ),
    );
  }

  String _getTimeRange(int period) {
    const startTimes = [
      "9:00 AM", "10:00 AM", "11:00 AM", "12:00 PM",
      "1:00 PM", "2:00 PM", "3:00 PM", "4:00 PM"
    ];
    const endTimes = [
      "10:00 AM", "11:00 AM", "12:00 PM", "1:00 PM",
      "2:00 PM", "3:00 PM", "4:00 PM", "5:00 PM"
    ];

    if (period - 1 < startTimes.length) {
      return "${startTimes[period - 1]} - ${endTimes[period - 1]}";
    }
    return "Time not set";
  }
}