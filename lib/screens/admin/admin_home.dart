import 'package:flutter/material.dart';
import 'admin_dashboard.dart';
import 'class_section_page.dart';
import 'teacher_management_page.dart';
import 'student_management.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    AdminDashboard(),
    ClassSectionPage(),
    TeacherManagementPage(),
    StudentManagementPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isWeb = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),

      /// ✅ Bottom Navigation ONLY for Mobile
      bottomNavigationBar: isWeb
          ? null
          : BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: "Attendance",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.currency_rupee),
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
