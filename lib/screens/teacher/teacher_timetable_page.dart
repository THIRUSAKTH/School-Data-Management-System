import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:schoolprojectjan/app_config.dart';

class TeacherTimetablePage extends StatefulWidget {
  const TeacherTimetablePage({super.key});

  @override
  State<TeacherTimetablePage> createState() => _TeacherTimetablePageState();
}

class _TeacherTimetablePageState extends State<TeacherTimetablePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _teacherId;
  String? _teacherName;
  List<Map<String, dynamic>> _teacherClasses = [];
  bool _isLoading = true;
  Map<String, List<Map<String, dynamic>>> _timetable = {};

  // Days of week
  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _days.length, vsync: this);
    _loadTeacherData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTeacherData() async {
    setState(() => _isLoading = true);

    try {
      final teacherUid = FirebaseAuth.instance.currentUser!.uid;

      // Get teacher details
      final teacherQuery = await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('teachers')
          .where('uid', isEqualTo: teacherUid)
          .limit(1)
          .get();

      if (teacherQuery.docs.isNotEmpty) {
        final teacherDoc = teacherQuery.docs.first;
        _teacherId = teacherDoc.id;
        _teacherName = teacherDoc['name'] ?? 'Teacher';

        // Get teacher's assigned classes
        final assignedClasses = teacherDoc['assignedClasses'] as List<dynamic>? ?? [];

        for (var classInfo in assignedClasses) {
          final className = classInfo['className'];
          final section = classInfo['section'];

          _teacherClasses.add({
            'className': className,
            'section': section,
            'subject': classInfo['subject'] ?? 'General',
          });
        }

        // If no assigned classes, try to get from timetable collection
        if (_teacherClasses.isEmpty) {
          await _loadTimetableFromCollection();
        } else {
          await _buildTimetable();
        }
      } else {
        // Demo data for testing
        _loadDemoData();
      }
    } catch (e) {
      debugPrint('Error loading teacher data: $e');
      _loadDemoData();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadTimetableFromCollection() async {
    final timetableSnapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(AppConfig.schoolId)
        .collection('timetable')
        .where('teacherId', isEqualTo: _teacherId)
        .get();

    for (var doc in timetableSnapshot.docs) {
      final data = doc.data();
      final day = data['day'] ?? '';
      final time = data['time'] ?? '';
      final subject = data['subject'] ?? '';
      final className = data['className'] ?? '';
      final section = data['section'] ?? '';
      final roomNo = data['roomNo'] ?? '';

      if (!_timetable.containsKey(day)) {
        _timetable[day] = [];
      }

      _timetable[day]!.add({
        'time': time,
        'subject': subject,
        'className': className,
        'section': section,
        'roomNo': roomNo,
        'id': doc.id,
      });
    }

    // Sort by time
    _timetable.forEach((day, sessions) {
      sessions.sort((a, b) => a['time'].compareTo(b['time']));
    });
  }

  Future<void> _buildTimetable() async {
    // Build a default timetable structure based on assigned classes
    // In a real app, you'd fetch from a 'timetable' collection

    for (var day in _days) {
      _timetable[day] = [];

      // Sample timetable slots
      final timeSlots = [
        '08:00 - 09:00',
        '09:00 - 10:00',
        '10:00 - 11:00',
        '11:00 - 12:00',
        '12:00 - 13:00',
        '14:00 - 15:00',
        '15:00 - 16:00',
      ];

      for (int i = 0; i < _teacherClasses.length && i < timeSlots.length; i++) {
        final classInfo = _teacherClasses[i];
        _timetable[day]!.add({
          'time': timeSlots[i],
          'subject': classInfo['subject'],
          'className': classInfo['className'],
          'section': classInfo['section'],
          'roomNo': 'Room ${i + 1}',
        });
      }
    }
  }

  void _loadDemoData() {
    // Demo timetable data
    _timetable = {
      'Monday': [
        {'time': '08:00 - 09:00', 'subject': 'Mathematics', 'className': 'Grade 10', 'section': 'A', 'roomNo': '101'},
        {'time': '09:00 - 10:00', 'subject': 'Mathematics', 'className': 'Grade 10', 'section': 'B', 'roomNo': '102'},
        {'time': '11:00 - 12:00', 'subject': 'Algebra', 'className': 'Grade 9', 'section': 'A', 'roomNo': '103'},
        {'time': '14:00 - 15:00', 'subject': 'Mathematics', 'className': 'Grade 8', 'section': 'A', 'roomNo': '104'},
      ],
      'Tuesday': [
        {'time': '08:00 - 09:00', 'subject': 'Physics', 'className': 'Grade 10', 'section': 'A', 'roomNo': '101'},
        {'time': '10:00 - 11:00', 'subject': 'Chemistry', 'className': 'Grade 9', 'section': 'B', 'roomNo': '102'},
        {'time': '13:00 - 14:00', 'subject': 'Mathematics', 'className': 'Grade 10', 'section': 'C', 'roomNo': '103'},
      ],
      'Wednesday': [
        {'time': '09:00 - 10:00', 'subject': 'Mathematics', 'className': 'Grade 10', 'section': 'C', 'roomNo': '101'},
        {'time': '11:00 - 12:00', 'subject': 'Algebra', 'className': 'Grade 9', 'section': 'A', 'roomNo': '102'},
        {'time': '14:00 - 15:00', 'subject': 'Mathematics', 'className': 'Grade 8', 'section': 'B', 'roomNo': '103'},
      ],
      'Thursday': [
        {'time': '08:00 - 09:00', 'subject': 'Mathematics', 'className': 'Grade 10', 'section': 'B', 'roomNo': '101'},
        {'time': '10:00 - 11:00', 'subject': 'Physics', 'className': 'Grade 10', 'section': 'A', 'roomNo': '102'},
        {'time': '13:00 - 14:00', 'subject': 'Mathematics', 'className': 'Grade 9', 'section': 'B', 'roomNo': '103'},
      ],
      'Friday': [
        {'time': '08:00 - 09:00', 'subject': 'Algebra', 'className': 'Grade 9', 'section': 'A', 'roomNo': '101'},
        {'time': '10:00 - 11:00', 'subject': 'Mathematics', 'className': 'Grade 10', 'section': 'A', 'roomNo': '102'},
        {'time': '14:00 - 15:00', 'subject': 'Mathematics', 'className': 'Grade 10', 'section': 'B', 'roomNo': '103'},
      ],
      'Saturday': [
        {'time': '08:00 - 09:00', 'subject': 'Mathematics', 'className': 'Grade 8', 'section': 'A', 'roomNo': '101'},
        {'time': '10:00 - 11:00', 'subject': 'Algebra', 'className': 'Grade 9', 'section': 'B', 'roomNo': '102'},
      ],
    };

    _teacherName = 'Demo Teacher';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("My Timetable"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTeacherData,
            tooltip: "Refresh",
          ),
          if (_teacherName != null)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: Text(
                _teacherName!,
                style: const TextStyle(fontSize: 14),
              ),
            ),
        ],
        bottom: _isLoading
            ? null
            : TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: _days.map((day) => Tab(text: day.substring(0, 3))).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _teacherClasses.isEmpty && _timetable.isEmpty
          ? _buildEmptyState()
          : TabBarView(
        controller: _tabController,
        children: _days.map((day) => _buildDaySchedule(day)).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No Timetable Assigned",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            "Your timetable will appear here once assigned by admin",
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadTeacherData,
            icon: const Icon(Icons.refresh),
            label: const Text("Refresh"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySchedule(String day) {
    final sessions = _timetable[day] ?? [];

    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.free_breakfast, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              "No classes on $day",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return _SessionCard(
          time: session['time'],
          subject: session['subject'],
          className: session['className'],
          section: session['section'],
          roomNo: session['roomNo'],
          isBreak: session['subject'] == 'Break',
        );
      },
    );
  }
}

// ================= SESSION CARD WIDGET =================

class _SessionCard extends StatelessWidget {
  final String time;
  final String subject;
  final String className;
  final String section;
  final String roomNo;
  final bool isBreak;

  const _SessionCard({
    required this.time,
    required this.subject,
    required this.className,
    required this.section,
    required this.roomNo,
    this.isBreak = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isBreak) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade100, Colors.orange.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.free_breakfast, color: Colors.orange),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    time,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Break / Lunch",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showSessionDetails(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Time Column
                Container(
                  width: 90,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Colors.deepPurple),
                      const SizedBox(height: 4),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.deepPurple,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Subject & Class Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "$className - $section",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.meeting_room, size: 10, color: Colors.blue.shade700),
                                const SizedBox(width: 2),
                                Text(
                                  roomNo,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSessionDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.school, size: 30, color: Colors.deepPurple),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "$className - $section",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            _DetailRow(icon: Icons.access_time, label: "Time", value: time),
            _DetailRow(icon: Icons.meeting_room, label: "Room", value: roomNo),
            _DetailRow(icon: Icons.person, label: "Teacher", value: "You"),
            _DetailRow(icon: Icons.calendar_today, label: "Day", value: DateFormat('EEEE').format(DateTime.now())),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                label: const Text("Close"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}