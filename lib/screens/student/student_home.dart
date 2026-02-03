import 'package:flutter/material.dart';
import 'package:schoolprojectjan/screens/student/attendance_page.dart';
import 'package:schoolprojectjan/screens/student/marks_page.dart';
import 'package:schoolprojectjan/screens/student/student_profile_page.dart';
import 'student_dashboard.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  int _index = 0;

  final List<Widget> _pages = const [
    StudentDashboard(),
    StudentAttendancePage(),
    StudentMarksPage(),
    StudentProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.check), label: "Attendance"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Results"),
          BottomNavigationBarItem(icon: Icon(Icons.score_outlined), label: "Marks"),
        ],
      ),
    );
  }
}