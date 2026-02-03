import 'package:flutter/material.dart';
import 'package:schoolprojectjan/screens/admin/class_section_page.dart';
import 'package:schoolprojectjan/screens/admin/notice_post_page.dart';
import 'admin_dashboard.dart';

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
    NoticePostPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      bottomNavigationBar: BottomNavigationBar(
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
            icon: Icon(Icons.class_),
            label: "Class & Section",
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