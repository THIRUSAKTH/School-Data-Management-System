import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:schoolprojectjan/app_config.dart';

class TeacherViewTimetable extends StatefulWidget {
  const TeacherViewTimetable({super.key});

  @override
  State<TeacherViewTimetable> createState() => _TeacherViewTimetableState();
}

class _TeacherViewTimetableState extends State<TeacherViewTimetable> {
  String _selectedDay = _getCurrentDay();
  String? _teacherId;
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
    _loadTeacherId();
  }

  Future<void> _loadTeacherId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final teacherDoc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('teachers')
          .doc(user.uid)
          .get();

      if (teacherDoc.exists) {
        setState(() {
          _teacherId = user.uid;
        });
        _loadTimetable();
      }
    }
  }

  Future<void> _loadTimetable() async {
    if (_teacherId == null) return;

    setState(() => _isLoading = true);

    final entries = await FirebaseFirestore.instance
        .collection('schools')
        .doc(AppConfig.schoolId)
        .collection('timetable')
        .where('teacherId', isEqualTo: _teacherId)
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
        'class': data['class'],
        'section': data['section'],
        'subject': data['subject'],
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
        title: const Text(
          "My Timetable",
          style: TextStyle(fontWeight: FontWeight.bold),
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
                      decoration: BoxDecoration(
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
              "You have no classes on this day",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8, // Max 8 periods
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
          entry != null ? "Period $period" : "Period $period - Free Period",
          style: TextStyle(
            fontWeight: entry != null ? FontWeight.bold : FontWeight.normal,
            color: entry != null ? Colors.black87 : Colors.grey,
          ),
        ),
        subtitle: entry != null
            ? Text("${entry['subject']} | Class ${entry['class']}-${entry['section']}")
            : null,
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
}