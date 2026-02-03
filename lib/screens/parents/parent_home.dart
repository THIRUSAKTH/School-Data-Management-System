
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'parent_dashboard.dart';
import 'parent_attendance_page.dart';
import 'homework_view_page.dart';
import 'fee_status_page.dart';
import 'notices_page.dart';

class ParentHome extends StatefulWidget {
  const ParentHome({super.key});

  @override
  State<ParentHome> createState() => _ParentHomeState();
}

class _ParentHomeState extends State<ParentHome> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    ParentDashboard(),
    ParentAttendancePage(),
    HomeworkViewPage(),
    FeeStatusPage(),
    NoticesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: (index) {
          HapticFeedback.lightImpact();
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fact_check_outlined),
            label: "Attendance",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: "Homework",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: "Fees",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: "Notices",
          ),
        ],
      ),
    );
  }
}