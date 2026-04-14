import 'package:flutter/material.dart';
import 'teacher_dashboard.dart';

class TeacherHome extends StatefulWidget {

  const TeacherHome({super.key}); // ✅ REMOVED schoolId

  @override
  State<TeacherHome> createState() => _TeacherHomeState();
}

class _TeacherHomeState extends State<TeacherHome> {
  int _index = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = const [
      TeacherDashboard(),
      Center(child: Text("Attendance Coming Soon")),
      Center(child: Text("Homework Coming Soon")),
      Center(child: Text("Timetable Coming Soon")),
    ];
  }

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
            icon: Icon(Icons.calendar_month),
            label: "Timetable",
          ),
        ],
      ),
    );
  }
}