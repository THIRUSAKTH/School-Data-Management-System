import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:schoolprojectjan/screens/authentication_page/login_page.dart';
import 'package:schoolprojectjan/screens/parents/parent_attendance_view_page.dart';
import 'package:schoolprojectjan/screens/parents/fee_history_page.dart';
import 'package:schoolprojectjan/screens/parents/fee_status_page.dart';
import 'package:schoolprojectjan/screens/parents/homework_view_page.dart';
import 'package:schoolprojectjan/screens/parents/parent_complaint_page.dart';
import 'package:schoolprojectjan/screens/parents/parent_exam_schedule.dart';
import 'package:schoolprojectjan/screens/parents/parent_notices_page.dart';
import 'package:schoolprojectjan/screens/parents/parent_notifications_page.dart';
import 'package:schoolprojectjan/screens/parents/parent_profile_page.dart';
import 'package:schoolprojectjan/screens/parents/parent_settings_page.dart';
import 'package:schoolprojectjan/screens/parents/parent_view_results.dart';

class ParentHomePage extends StatefulWidget {
  const ParentHomePage({super.key});

  @override
  State<ParentHomePage> createState() => _ParentHomePageState();
}

class _ParentHomePageState extends State<ParentHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Student related variables
  String? _selectedStudentId;
  String? _selectedStudentName;
  String? _selectedClassName;
  String? _selectedSection;
  String? _selectedRollNo;

  // School related
  String? _schoolId;

  // Counters for badges
  int _unreadNotifications = 0;
  int _unreadNotices = 0;
  int _unreadComplaints = 0;
  int _pendingHomeworkCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUnreadCounts() async {
    if (_selectedStudentId == null || _schoolId == null) return;

    try {
      // Load unread notifications
      final notifications = await FirebaseFirestore.instance
          .collection('schools')
          .doc(_schoolId)
          .collection('notifications')
          .where('studentId', isEqualTo: _selectedStudentId)
          .where('isRead', isEqualTo: false)
          .get();

      // Load pending complaints
      final complaints = await FirebaseFirestore.instance
          .collection('schools')
          .doc(_schoolId)
          .collection('complaints')
          .where('studentId', isEqualTo: _selectedStudentId)
          .where('status', isEqualTo: 'pending')
          .get();

      // Load pending homework
      final homework = await FirebaseFirestore.instance
          .collection('schools')
          .doc(_schoolId)
          .collection('homework')
          .where('className', isEqualTo: _selectedClassName)
          .where('section', isEqualTo: _selectedSection)
          .get();

      setState(() {
        _unreadNotifications = notifications.docs.length;
        _unreadComplaints = complaints.docs.length;
        _pendingHomeworkCount = homework.docs.length;
      });
    } catch (e) {
      debugPrint("Error loading unread counts: $e");
    }
  }

  void _selectStudent(String studentId, Map<String, dynamic> studentData) {
    setState(() {
      _selectedStudentId = studentId;
      _selectedStudentName = studentData['name'] ?? 'Student';
      _selectedClassName = studentData['class'] ?? '';
      _selectedSection = studentData['section'] ?? '';
      _selectedRollNo = studentData['rollNo'] ?? '';
      _loadUnreadCounts();
    });
  }

  void _logout(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Logging out...")),
              );
              try {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginPage(role: 'Parent'),
                    ),
                        (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  void _showSelectChildSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please select a child first"),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Help & Support"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("📞 Contact School:"),
            SizedBox(height: 8),
            Text("Phone: +91 98765 43210"),
            Text("Email: support@school.com"),
            SizedBox(height: 16),
            Text("🕒 Support Hours:"),
            SizedBox(height: 8),
            Text("Monday - Friday: 9:00 AM - 5:00 PM"),
            Divider(),
            Text("For urgent issues, please contact the school office directly."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: "Smart School Management System",
      applicationVersion: "1.0.0",
      applicationIcon: const Icon(Icons.school, size: 48, color: Colors.orange),
      children: const [
        Text(
          "A complete school ERP solution for parents, teachers, and administrators.\n\n"
              "Features:\n"
              "• Real-time attendance tracking\n"
              "• Homework management\n"
              "• Exam results and report cards\n"
              "• Fee payment and tracking\n"
              "• Complaint management\n"
              "• Notifications and announcements\n\n"
              "© 2024 Smart School. All rights reserved.",
        ),
      ],
    );
  }

  void _showQuickActionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "Quick Actions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            _quickActionItem(
              icon: Icons.calendar_today,
              title: "Attendance",
              color: Colors.green,
              onTap: () {
                Navigator.pop(context);
                if (_selectedStudentId != null && _selectedStudentName != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ParentAttendanceViewPage(
                        studentId: _selectedStudentId!,
                        studentName: _selectedStudentName!,
                        className: _selectedClassName!,
                        section: _selectedSection!,
                      ),
                    ),
                  );
                } else {
                  _showSelectChildSnackbar();
                }
              },
            ),
            _quickActionItem(
              icon: Icons.assignment,
              title: "Homework",
              color: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                if (_selectedStudentId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomeworkViewPage(
                        studentId: _selectedStudentId!,
                        className: _selectedClassName!,
                        section: _selectedSection!,
                      ),
                    ),
                  );
                } else {
                  _showSelectChildSnackbar();
                }
              },
            ),
            _quickActionItem(
              icon: Icons.assessment,
              title: "Results",
              color: Colors.purple,
              onTap: () {
                Navigator.pop(context);
                if (_selectedStudentId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ParentViewResultsPage(
                        studentId: _selectedStudentId!,
                        studentName: _selectedStudentName!,
                      ),
                    ),
                  );
                } else {
                  _showSelectChildSnackbar();
                }
              },
            ),
            _quickActionItem(
              icon: Icons.calendar_month,
              title: "Exam Schedule",
              color: Colors.teal,
              onTap: () {
                Navigator.pop(context);
                if (_selectedStudentId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ParentExamSchedulePage(
                        className: _selectedClassName,
                        section: _selectedSection,
                      ),
                    ),
                  );
                } else {
                  _showSelectChildSnackbar();
                }
              },
            ),
            _quickActionItem(
              icon: Icons.receipt,
              title: "Fee Status",
              color: Colors.deepPurple,
              onTap: () {
                Navigator.pop(context);
                if (_selectedStudentId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FeeStatusPage(studentId: _selectedStudentId!),
                    ),
                  );
                } else {
                  _showSelectChildSnackbar();
                }
              },
            ),
            _quickActionItem(
              icon: Icons.receipt_long,
              title: "Fee History",
              color: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                if (_selectedStudentId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FeeHistoryPage(studentId: _selectedStudentId!),
                    ),
                  );
                } else {
                  _showSelectChildSnackbar();
                }
              },
            ),
            _quickActionItem(
              icon: Icons.announcement,
              title: "Notices",
              color: Colors.orange,
              onTap: () {
                Navigator.pop(context);
                if (_selectedStudentId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ParentNoticesPage(
                        className: _selectedClassName,
                        section: _selectedSection,
                      ),
                    ),
                  );
                } else {
                  _showSelectChildSnackbar();
                }
              },
            ),
            _quickActionItem(
              icon: Icons.feedback,
              title: "Complaint",
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                if (_selectedStudentId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ParentComplaintPage(studentId: _selectedStudentId!),
                    ),
                  ).then((_) => _loadUnreadCounts());
                } else {
                  _showSelectChildSnackbar();
                }
              },
            ),
            _quickActionItem(
              icon: Icons.notifications,
              title: "Notifications",
              color: Colors.teal,
              onTap: () {
                Navigator.pop(context);
                if (_selectedStudentId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ParentNotificationsPage(studentId: _selectedStudentId!),
                    ),
                  ).then((_) => _loadUnreadCounts());
                } else {
                  _showSelectChildSnackbar();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActionItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    _schoolId = ModalRoute.of(context)!.settings.arguments as String;
    final parentUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Parent Dashboard",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_selectedStudentName != null)
              Text(_selectedStudentName!, style: const TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.school), text: "My Children"),
            Tab(icon: Icon(Icons.analytics), text: "Analytics"),
          ],
        ),
        actions: [
          // Notifications Button with Badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  if (_selectedStudentId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ParentNotificationsPage(studentId: _selectedStudentId!),
                      ),
                    ).then((_) => _loadUnreadCounts());
                  } else {
                    _showSelectChildSnackbar();
                  }
                },
                tooltip: "Notifications",
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_unreadNotifications',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: "Logout",
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('schools')
            .doc(_schoolId)
            .collection('students')
            .where('parentUid', isEqualTo: parentUid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildNoChildrenWidget();
          }

          final students = snapshot.data!.docs;

          // Set default selected student if not set
          if (_selectedStudentId == null && students.isNotEmpty) {
            final firstStudent = students.first;
            final data = firstStudent.data() as Map<String, dynamic>;
            _selectStudent(firstStudent.id, data);
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildChildrenList(students),
              _buildAnalyticsTab(students),
            ],
          );
        },
      ),
      floatingActionButton: _buildQuickActionFab(),
    );
  }

  // ================= DRAWER =================
  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange, Colors.deepOrange],
              ),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 45, color: Colors.orange),
                ),
                const SizedBox(height: 10),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('schools')
                      .doc(_schoolId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    String schoolName = "School";
                    if (snapshot.hasData && snapshot.data!.exists) {
                      schoolName = snapshot.data!['schoolName'] ?? "School";
                    }
                    return Text(
                      schoolName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  "Parent Portal",
                  style: TextStyle(color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ),
          // Drawer Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerItem(
                  icon: Icons.dashboard,
                  title: "Dashboard",
                  onTap: () {
                    Navigator.pop(context);
                    _tabController.animateTo(0);
                  },
                ),
                _drawerItem(
                  icon: Icons.analytics,
                  title: "Analytics",
                  onTap: () {
                    Navigator.pop(context);
                    _tabController.animateTo(1);
                  },
                ),
                const Divider(),
                _drawerItem(
                  icon: Icons.calendar_today,
                  title: "Attendance",
                  onTap: () {
                    Navigator.pop(context);
                    if (_selectedStudentId != null && _selectedStudentName != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ParentAttendanceViewPage(
                            studentId: _selectedStudentId!,
                            studentName: _selectedStudentName!,
                            className: _selectedClassName!,
                            section: _selectedSection!,
                          ),
                        ),
                      );
                    } else {
                      _showSelectChildSnackbar();
                    }
                  },
                ),
                _drawerItem(
                  icon: Icons.assignment,
                  title: "Homework",
                  badge: _pendingHomeworkCount > 0 ? _pendingHomeworkCount.toString() : null,
                  onTap: () {
                    Navigator.pop(context);
                    if (_selectedStudentId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HomeworkViewPage(
                            studentId: _selectedStudentId!,
                            className: _selectedClassName!,
                            section: _selectedSection!,
                          ),
                        ),
                      );
                    } else {
                      _showSelectChildSnackbar();
                    }
                  },
                ),
                _drawerItem(
                  icon: Icons.assessment,
                  title: "Results",
                  onTap: () {
                    Navigator.pop(context);
                    if (_selectedStudentId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ParentViewResultsPage(
                            studentId: _selectedStudentId!,
                            studentName: _selectedStudentName!,
                          ),
                        ),
                      );
                    } else {
                      _showSelectChildSnackbar();
                    }
                  },
                ),
                _drawerItem(
                  icon: Icons.calendar_month,
                  title: "Exam Schedule",
                  onTap: () {
                    Navigator.pop(context);
                    if (_selectedStudentId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ParentExamSchedulePage(
                            className: _selectedClassName,
                            section: _selectedSection,
                          ),
                        ),
                      );
                    } else {
                      _showSelectChildSnackbar();
                    }
                  },
                ),
                _drawerItem(
                  icon: Icons.receipt,
                  title: "Fee Status",
                  onTap: () {
                    Navigator.pop(context);
                    if (_selectedStudentId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FeeStatusPage(studentId: _selectedStudentId!),
                        ),
                      );
                    } else {
                      _showSelectChildSnackbar();
                    }
                  },
                ),
                _drawerItem(
                  icon: Icons.history,
                  title: "Fee History",
                  onTap: () {
                    Navigator.pop(context);
                    if (_selectedStudentId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FeeHistoryPage(studentId: _selectedStudentId!),
                        ),
                      );
                    } else {
                      _showSelectChildSnackbar();
                    }
                  },
                ),
                _drawerItem(
                  icon: Icons.announcement,
                  title: "Notices",
                  badge: _unreadNotices > 0 ? _unreadNotices.toString() : null,
                  onTap: () {
                    Navigator.pop(context);
                    if (_selectedStudentId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ParentNoticesPage(
                            className: _selectedClassName,
                            section: _selectedSection,
                          ),
                        ),
                      );
                    } else {
                      _showSelectChildSnackbar();
                    }
                  },
                ),
                _drawerItem(
                  icon: Icons.feedback,
                  title: "Complaints",
                  badge: _unreadComplaints > 0 ? _unreadComplaints.toString() : null,
                  onTap: () {
                    Navigator.pop(context);
                    if (_selectedStudentId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ParentComplaintPage(studentId: _selectedStudentId!),
                        ),
                      ).then((_) => _loadUnreadCounts());
                    } else {
                      _showSelectChildSnackbar();
                    }
                  },
                ),
                _drawerItem(
                  icon: Icons.notifications,
                  title: "Notifications",
                  badge: _unreadNotifications > 0 ? _unreadNotifications.toString() : null,
                  onTap: () {
                    Navigator.pop(context);
                    if (_selectedStudentId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ParentNotificationsPage(studentId: _selectedStudentId!),
                        ),
                      ).then((_) => _loadUnreadCounts());
                    } else {
                      _showSelectChildSnackbar();
                    }
                  },
                ),
                const Divider(),
                _drawerItem(
                  icon: Icons.person,
                  title: "My Profile",
                  onTap: () {
                    Navigator.pop(context);
                    if (_selectedStudentId != null && _schoolId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ParentProfilePage(
                            studentId: _selectedStudentId!,
                            schoolId: _schoolId!,
                          ),
                        ),
                      );
                    } else {
                      _showSelectChildSnackbar();
                    }
                  },
                ),
                _drawerItem(
                  icon: Icons.settings,
                  title: "Settings",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ParentSettingsPage(
                          schoolId: _schoolId!,
                          parentUid: FirebaseAuth.instance.currentUser!.uid,
                        ),
                      ),
                    );
                  },
                ),
                const Divider(),
                _drawerItem(
                  icon: Icons.help_outline,
                  title: "Help & Support",
                  onTap: () => _showHelpDialog(),
                ),
                _drawerItem(
                  icon: Icons.info_outline,
                  title: "About",
                  onTap: () => _showAboutDialog(),
                ),
                const Divider(),
                _drawerItem(
                  icon: Icons.logout,
                  title: "Logout",
                  isLogout: true,
                  onTap: () => _logout(context),
                ),
              ],
            ),
          ),
          // Version Text
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "Version 1.0.0",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    bool isLogout = false,
    String? badge,
  }) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? Colors.red : Colors.orange),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? Colors.red : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: badge != null
          ? Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          badge,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      )
          : null,
      onTap: onTap,
    );
  }

  Widget _buildQuickActionFab() {
    return FloatingActionButton.extended(
      onPressed: () => _showQuickActionsMenu(),
      backgroundColor: Colors.orange,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.menu),
      label: const Text("Quick Actions"),
    );
  }

  Widget _buildNoChildrenWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No Child Linked",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            "Please contact the school admin to link your children.",
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showHelpDialog(),
            icon: const Icon(Icons.support_agent),
            label: const Text("Contact Support"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildrenList(List<QueryDocumentSnapshot> students) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final s = students[index];
        final data = s.data() as Map<String, dynamic>;
        final isSelected = _selectedStudentId == s.id;

        return GestureDetector(
          onTap: () {
            _selectStudent(s.id, data);
            _tabController.animateTo(1);
          },
          child: Card(
            elevation: isSelected ? 4 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isSelected
                  ? BorderSide(color: Colors.orange, width: 2)
                  : BorderSide.none,
            ),
            margin: const EdgeInsets.only(bottom: 12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: isSelected
                    ? const LinearGradient(
                  colors: [Colors.white, Colors.orange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null,
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isSelected ? Colors.orange : Colors.orange.shade100,
                  child: Icon(
                    Icons.person,
                    color: isSelected ? Colors.white : Colors.orange,
                  ),
                ),
                title: Text(
                  data['name'] ?? 'Unknown',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.orange.shade800 : Colors.black87,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text("Class: ${data['class'] ?? 'N/A'} ${data['section'] ?? ''}"),
                    Text("Roll No: ${data['rollNo'] ?? 'N/A'}"),
                  ],
                ),
                trailing: isSelected
                    ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'SELECTED',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                )
                    : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsTab(List<QueryDocumentSnapshot> students) {
    if (_selectedStudentId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('Select a child to view details'),
          ],
        ),
      );
    }

    // Find selected student with null safety
    QueryDocumentSnapshot? selectedStudent;
    for (var student in students) {
      if (student.id == _selectedStudentId) {
        selectedStudent = student;
        break;
      }
    }

    if (selectedStudent == null && students.isNotEmpty) {
      final firstStudent = students.first;
      final data = firstStudent.data() as Map<String, dynamic>;
      _selectStudent(firstStudent.id, data);
      selectedStudent = firstStudent;
    }

    if (selectedStudent == null) {
      return const Center(child: Text('No child selected'));
    }

    final data = selectedStudent.data() as Map<String, dynamic>;
    final studentName = data['name'] ?? 'Student';
    final className = data['class'] ?? '';
    final section = data['section'] ?? '';
    final rollNo = data['rollNo'] ?? '';
    final admissionNo = data['admissionNo'] ?? '';
    final fatherName = data['fatherName'] ?? '';
    final motherName = data['motherName'] ?? '';
    final phone = data['phone'] ?? '';

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
        await _loadUnreadCounts();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildStudentHeader(studentName, className, section, rollNo, admissionNo),
            const SizedBox(height: 16),
            _buildStatsRow(_selectedStudentId!),
            const SizedBox(height: 16),
            _buildAttendanceSummary(_selectedStudentId!),
            const SizedBox(height: 16),
            _buildFeeDetails(_selectedStudentId!),
            const SizedBox(height: 16),
            _buildStudentDetails(
              name: studentName,
              className: className,
              section: section,
              rollNo: rollNo,
              admissionNo: admissionNo,
              fatherName: fatherName,
              motherName: motherName,
              phone: phone,
            ),
          ],
        ),
      ),
    );
  }

  // ================= ADDITIONAL WIDGETS =================

  Widget _buildStudentHeader(
      String name,
      String className,
      String section,
      String rollNo,
      String admissionNo,
      ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.orange, Colors.deepOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white,
            child: Icon(Icons.school, size: 40, color: Colors.orange),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Class $className-$section | Roll No: $rollNo",
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          if (admissionNo.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                "Admission No: $admissionNo",
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(String studentId) {
    return FutureBuilder<int>(
      future: _getPresentCount(studentId),
      builder: (context, presentSnapshot) {
        final present = presentSnapshot.data ?? 0;

        return FutureBuilder<int>(
          future: _getTotalCount(),
          builder: (context, totalSnapshot) {
            final total = totalSnapshot.data ?? 0;
            double attendanceRate = total > 0 ? (present / total) * 100 : 0;

            return FutureBuilder<Map<String, double>>(
              future: _getFeeData(studentId),
              builder: (context, feeSnapshot) {
                double totalPaid = feeSnapshot.data?['paid'] ?? 0;
                double totalDue = feeSnapshot.data?['due'] ?? 0;

                return Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: "Attendance",
                        value: "${attendanceRate.toStringAsFixed(1)}%",
                        color: Colors.green,
                        icon: Icons.check_circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: "Fees Paid",
                        value: "₹${totalPaid.toInt()}",
                        color: Colors.blue,
                        icon: Icons.account_balance_wallet,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: "Fees Due",
                        value: "₹${totalDue.toInt()}",
                        color: Colors.red,
                        icon: Icons.pending_actions,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<int> _getPresentCount(String studentId) async {
    final attendanceDates = await FirebaseFirestore.instance
        .collection('schools')
        .doc(_schoolId)
        .collection('attendance')
        .get();

    int present = 0;
    for (var dateDoc in attendanceDates.docs) {
      final record = await dateDoc.reference
          .collection('records')
          .doc(studentId)
          .get();
      if (record.exists && record.data()?['status'] == 'Present') {
        present++;
      }
    }
    return present;
  }

  Future<int> _getTotalCount() async {
    final attendanceDates = await FirebaseFirestore.instance
        .collection('schools')
        .doc(_schoolId)
        .collection('attendance')
        .get();
    return attendanceDates.docs.length;
  }

  Future<Map<String, double>> _getFeeData(String studentId) async {
    final fees = await FirebaseFirestore.instance
        .collection('schools')
        .doc(_schoolId)
        .collection('student_fees')
        .where('studentId', isEqualTo: studentId)
        .get();

    double paid = 0;
    double due = 0;
    for (var doc in fees.docs) {
      final data = doc.data();
      final amount = (data['amount'] ?? 0).toDouble();
      if (data['status'] == 'paid') {
        paid += amount;
      } else {
        due += amount;
      }
    }
    return {'paid': paid, 'due': due};
  }

  Widget _buildAttendanceSummary(String studentId) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getRecentAttendance(studentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Card(
            child: const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No attendance records found')),
            ),
          );
        }

        final records = snapshot.data!;
        int present = records.where((r) => r['status'] == 'Present').length;
        int absent = records.where((r) => r['status'] == 'Absent').length;
        int late = records.where((r) => r['status'] == 'Late').length;

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Recent Attendance',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        value: present.toString(),
                        label: 'Present',
                        color: Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _MiniStat(
                        value: late.toString(),
                        label: 'Late',
                        color: Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _MiniStat(
                        value: absent.toString(),
                        label: 'Absent',
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...records.take(5).map((record) {
                  final date = DateTime.parse(record['date']);
                  final status = record['status'];
                  Color statusColor = status == 'Present'
                      ? Colors.green
                      : (status == 'Late' ? Colors.orange : Colors.red);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: statusColor.withOpacity(0.1),
                      child: Icon(
                        status == 'Present' ? Icons.check_circle : (status == 'Late' ? Icons.access_time : Icons.cancel),
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      DateFormat('EEEE, dd MMM yyyy').format(date),
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getRecentAttendance(String studentId) async {
    final attendanceDates = await FirebaseFirestore.instance
        .collection('schools')
        .doc(_schoolId)
        .collection('attendance')
        .get();

    List<Map<String, dynamic>> records = [];
    for (var dateDoc in attendanceDates.docs) {
      final record = await dateDoc.reference
          .collection('records')
          .doc(studentId)
          .get();

      if (record.exists) {
        records.add({
          'date': dateDoc.id,
          'status': record.data()?['status'] ?? 'Absent',
        });
      }
    }

    records.sort((a, b) => b['date'].compareTo(a['date']));
    return records;
  }

  Widget _buildFeeDetails(String studentId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(_schoolId)
          .collection('student_fees')
          .where('studentId', isEqualTo: studentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.data!.docs.isEmpty) {
          return Card(
            child: const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No fee records found')),
            ),
          );
        }

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.receipt, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Fee Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 24),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final amount = (data['amount'] ?? 0).toDouble();
                    final dueDate = data['dueDate'] != null
                        ? (data['dueDate'] as Timestamp).toDate()
                        : null;
                    final status = data['status'] ?? 'pending';
                    final feeType = data['feeType'] ?? 'Fee';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: status == 'paid' ? Colors.green.shade100 : Colors.red.shade100,
                        radius: 20,
                        child: Icon(
                          status == 'paid' ? Icons.check : Icons.pending,
                          color: status == 'paid' ? Colors.green : Colors.red,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        feeType,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: dueDate != null
                          ? Text('Due: ${DateFormat('dd MMM yyyy').format(dueDate)}')
                          : null,
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${amount.toInt()}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: status == 'paid' ? Colors.green.shade100 : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: status == 'paid' ? Colors.green : Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStudentDetails({
    required String name,
    required String className,
    required String section,
    required String rollNo,
    required String admissionNo,
    required String fatherName,
    required String motherName,
    required String phone,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person_outline, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Student Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _infoRow('Student Name', name),
            _infoRow('Class & Section', '$className - $section'),
            _infoRow('Roll Number', rollNo),
            if (admissionNo.isNotEmpty) _infoRow('Admission No', admissionNo),
            _infoRow('Father\'s Name', fatherName.isNotEmpty ? fatherName : 'Not provided'),
            _infoRow('Mother\'s Name', motherName.isNotEmpty ? motherName : 'Not provided'),
            if (phone.isNotEmpty) _infoRow('Phone', phone),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper Widgets
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _MiniStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: color,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}