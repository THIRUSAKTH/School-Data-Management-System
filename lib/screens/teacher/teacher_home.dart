import 'package:flutter/material.dart';
import 'package:schoolprojectjan/screens/teacher/class_students_page.dart';
import 'package:schoolprojectjan/screens/teacher/teacher_timetable_page.dart';
import 'homework_post_page.dart';
import 'teacher_dashboard.dart';

class TeacherHome extends StatefulWidget {
  const TeacherHome({super.key});

  @override
  State<TeacherHome> createState() => _TeacherHomeState();
}

class _TeacherHomeState extends State<TeacherHome> {
  int _index = 0;

  final List<Widget> _pages = const [
    TeacherDashboard(),
    ClassStudentsPage(),
    HomeworkPostPage(),
    TeacherTimetablePage(),
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
        selectedItemColor: Colors.green,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
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
            icon: Icon(Icons.calendar_month_outlined),
            label: "TimeTable",
          ),
        ],
      ),
    );
  }
}