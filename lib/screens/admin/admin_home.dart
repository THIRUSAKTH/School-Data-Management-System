import 'package:flutter/material.dart';
import 'package:schoolprojectjan/screens/admin/class_section_page.dart';
import 'package:schoolprojectjan/screens/admin/notice_post_page.dart';
import 'admin_dashboard.dart';

class AdminHome extends StatefulWidget {
  final String schoolId;

  const AdminHome({
    super.key,
    required this.schoolId,
  });

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      AdminDashboard(),
      const ClassSectionPage(),
      const NoticePostPage(),
    ];
  }

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
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
        ),
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard, size: 24),
            activeIcon: Icon(Icons.dashboard, size: 24),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.class_, size: 24),
            activeIcon: Icon(Icons.class_, size: 24),
            label: "Class & Section",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.announcement, size: 24),
            activeIcon: Icon(Icons.announcement, size: 24),
            label: "Notices",
          ),
        ],
      ),
    );
  }
}