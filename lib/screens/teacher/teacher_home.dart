import 'package:flutter/material.dart';
import 'package:schoolprojectjan/app_config.dart';
import 'package:schoolprojectjan/screens/teacher/homework_post_page.dart';
import 'package:schoolprojectjan/screens/teacher/mark_attendance_page.dart';
import 'package:schoolprojectjan/screens/teacher/select_class_attendance_page.dart';
import 'package:schoolprojectjan/screens/teacher/teacher_timetable_page.dart';
import 'package:schoolprojectjan/screens/teacher/teacher_upload_marks.dart';
import 'teacher_dashboard.dart';

class TeacherHome extends StatefulWidget {
  const TeacherHome({super.key});

  @override
  State<TeacherHome> createState() => _TeacherHomeState();
}

class _TeacherHomeState extends State<TeacherHome> {
  int _index = 0;

  late final List<Widget> _pages;

  final List<String> _titles = [
    "Dashboard",
    "Attendance",
    "Homework",
    "Marks",
    "Timetable",
  ];

  @override
  void initState() {
    super.initState();

    _pages = const [
      TeacherDashboard(),
      SelectClassAttendancePage(
        schoolId: AppConfig.schoolId,
      ),
      HomeworkPostPage(),
      TeacherUploadMarksPage(),
      TeacherTimetablePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      /// 🔥 APP BAR (NEW)
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text(
          _titles[_index],
          style: const TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),

      /// 🔥 BODY
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),

      /// 🔥 BOTTOM NAV
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: "Attendance",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: "Homework",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: "Timetable",
          ),
        ],
      ),
    );
  }
}

/// 🔥 EMPTY PAGE (PRO LOOK)
class _EmptyPage extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyPage({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 70, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}