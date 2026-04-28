import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:schoolprojectjan/app_config.dart';
import 'package:schoolprojectjan/screens/authentication_page/login_page.dart';
import 'package:schoolprojectjan/screens/parents/attendance_view_page.dart';
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
import 'package:schoolprojectjan/screens/parents/select_child_page.dart';
import 'package:schoolprojectjan/screens/parents/student_timetable_page.dart';

class ParentDashboard extends StatefulWidget {
  final String? selectedChildId;
  final String? selectedChildName;

  const ParentDashboard({
    super.key,
    this.selectedChildId,
    this.selectedChildName,
  });

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard>
    with SingleTickerProviderStateMixin {
  final String parentUid = FirebaseAuth.instance.currentUser!.uid;
  String? selectedStudentId;
  late TabController _tabController;
  int _unreadNotifications = 0;
  int _unreadComplaints = 0;

  // Store current student data
  String _currentStudentName = '';
  String _currentClassName = '';
  String _currentSection = '';
  String _currentRollNo = '';
  String _currentAdmissionNo = '';

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
    if (selectedStudentId == null) return;

    try {
      final notifications =
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('notifications')
          .where('studentId', isEqualTo: selectedStudentId)
          .where('isRead', isEqualTo: false)
          .get();

      final complaints =
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('complaints')
          .where('studentId', isEqualTo: selectedStudentId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (mounted) {
        setState(() {
          _unreadNotifications = notifications.docs.length;
          _unreadComplaints = complaints.docs.length;
        });
      }
    } catch (e) {
      debugPrint("Error loading counts: $e");
    }
  }

  void _logout(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
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
                    SnackBar(
                      content: Text("Error: $e"),
                      backgroundColor: Colors.red,
                    ),
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

  void _switchChild() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SelectChildPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Parent Dashboard',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (_currentStudentName.isNotEmpty)
              Text(_currentStudentName, style: const TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.switch_account),
            onPressed: _switchChild,
            tooltip: "Switch Child",
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 22),
                onPressed: () {
                  if (selectedStudentId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => ParentNotificationsPage(
                          studentId: selectedStudentId!,
                        ),
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
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      '$_unreadNotifications',
                      style: const TextStyle(color: Colors.white, fontSize: 9),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
          await _loadUnreadCounts();
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            return StreamBuilder<QuerySnapshot>(
              stream:
              FirebaseFirestore.instance
                  .collection('schools')
                  .doc(AppConfig.schoolId)
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

                // Initialize selected student if not set
                if (selectedStudentId == null && students.isNotEmpty) {
                  if (widget.selectedChildId != null) {
                    QueryDocumentSnapshot? matchingDoc;
                    for (var doc in students) {
                      if (doc.id == widget.selectedChildId) {
                        matchingDoc = doc;
                        break;
                      }
                    }
                    matchingDoc ??= students.first;
                    selectedStudentId = matchingDoc.id;
                    _updateCurrentStudentData(
                      matchingDoc.data() as Map<String, dynamic>,
                    );
                  } else {
                    selectedStudentId = students.first.id;
                    _updateCurrentStudentData(
                      students.first.data() as Map<String, dynamic>,
                    );
                  }
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _loadUnreadCounts();
                  });
                }

                // Find selected student document
                QueryDocumentSnapshot? selectedDoc;
                for (var doc in students) {
                  if (doc.id == selectedStudentId) {
                    selectedDoc = doc;
                    break;
                  }
                }

                if (selectedDoc == null && students.isNotEmpty) {
                  selectedDoc = students.first;
                  selectedStudentId = selectedDoc.id;
                  _updateCurrentStudentData(
                    selectedDoc.data() as Map<String, dynamic>,
                  );
                }

                if (selectedDoc == null) {
                  return _buildNoChildrenWidget();
                }

                final data = selectedDoc.data() as Map<String, dynamic>;
                _updateCurrentStudentData(data);

                final name = data['name'] ?? "Student";
                final className = data['class'] ?? "";
                final section = data['section'] ?? "";
                final rollNo = data['rollNo'] ?? "";

                return Column(
                  children: [
                    _buildHeader(name, className, section, rollNo),
                    if (students.length > 1) _buildChildSelector(students),
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Colors.orange,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Colors.orange,
                        tabs: const [
                          Tab(
                            icon: Icon(Icons.dashboard, size: 18),
                            text: 'Overview',
                          ),
                          Tab(
                            icon: Icon(Icons.calendar_month, size: 18),
                            text: 'Attendance',
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                _buildStatsRow(selectedStudentId!),
                                const SizedBox(height: 12),
                                _buildStudentDetailsCard(data),
                                const SizedBox(height: 12),
                                _buildFeeSection(),
                                const SizedBox(height: 12),
                                _buildQuickActions(),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                          _buildAttendanceTab(selectedStudentId!, name),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _updateCurrentStudentData(Map<String, dynamic> data) {
    _currentStudentName = data['name'] ?? 'Student';
    _currentClassName = data['class'] ?? '';
    _currentSection = data['section'] ?? '';
    _currentRollNo = data['rollNo'] ?? '';
    _currentAdmissionNo = data['admissionNo'] ?? '';
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange, Colors.deepOrange],
              ),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 35, color: Colors.orange),
                ),
                const SizedBox(height: 8),
                StreamBuilder<DocumentSnapshot>(
                  stream:
                  FirebaseFirestore.instance
                      .collection('schools')
                      .doc(AppConfig.schoolId)
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
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  "Parent Portal",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
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
                const Divider(),
                _drawerItem(
                  icon: Icons.calendar_today,
                  title: "Attendance",
                  onTap: () {
                    Navigator.pop(context);
                    if (selectedStudentId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ParentAttendanceViewPage(
                            studentId: selectedStudentId!,
                            studentName: _currentStudentName,
                            className: _currentClassName,
                            section: _currentSection,
                          ),
                        ),
                      );
                    } else {
                      _showSelectChildSnackbar();
                    }
                  },
                ),
                _drawerItem(
                  icon: Icons.switch_account,
                  title: "Switch Child",
                  onTap: _switchChild,
                ),
                const Divider(),
                _drawerItem(
                  icon: Icons.assignment,
                  title: "Homework",
                  onTap: () {
                    Navigator.pop(context);
                    if (selectedStudentId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => HomeworkViewPage(
                            studentId: selectedStudentId!,
                            className: _currentClassName,
                            section: _currentSection,
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
                    if (selectedStudentId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ParentViewResultsPage(
                            studentId: selectedStudentId!,
                            studentName: _currentStudentName,
                          ),
                        ),
                      );
                    } else {
                      _showSelectChildSnackbar();
                    }
                  },
                ),
                _drawerItem(
                  icon: Icons.schedule,
                  title: "Timetable",
                  onTap: () {
                    Navigator.pop(context);
                    if (selectedStudentId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => StudentTimetablePage(
                            studentId: selectedStudentId!,
                            studentName: _currentStudentName,
                            className: _currentClassName,
                            section: _currentSection,
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
                    if (selectedStudentId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ParentExamSchedulePage(
                            className: _currentClassName,
                            section: _currentSection,
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
                  title: "Fee History",
                  onTap: () {
                    Navigator.pop(context);
                    if (selectedStudentId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) =>
                              FeeHistoryPage(studentId: selectedStudentId!),
                        ),
                      );
                    } else {
                      _showSelectChildSnackbar();
                    }
                  },
                ),
                _drawerItem(
                  icon: Icons.payment,
                  title: "Fee Status",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => FeeStatusPage(studentId: selectedStudentId),
                      ),
                    );
                  },
                ),
                _drawerItem(
                  icon: Icons.announcement,
                  title: "Notices",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => ParentNoticesPage(
                          className: _currentClassName,
                          section: _currentSection,
                        ),
                      ),
                    );
                  },
                ),
                _drawerItem(
                  icon: Icons.feedback,
                  title: "Complaints",
                  badge:
                  _unreadComplaints > 0
                      ? _unreadComplaints.toString()
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    if (selectedStudentId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ParentComplaintPage(
                            studentId: selectedStudentId!,
                          ),
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
                    if (selectedStudentId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ParentProfilePage(
                            studentId: selectedStudentId!,
                            schoolId: AppConfig.schoolId,
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
                        builder:
                            (_) => ParentSettingsPage(
                          schoolId: AppConfig.schoolId,
                          parentUid: parentUid,
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
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              "Version 1.0.0",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
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
      dense: true,
      leading: Icon(
        icon,
        size: 20,
        color: isLogout ? Colors.red : Colors.orange,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? Colors.red : Colors.black87,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
      trailing:
      badge != null
          ? Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          badge,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      )
          : null,
      onTap: onTap,
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
        title: const Text("Help & Support"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("📞 Contact School:"),
            SizedBox(height: 6),
            Text("Phone: +91 98765 43210"),
            Text("Email: support@school.com"),
            SizedBox(height: 12),
            Text("🕒 Support Hours:"),
            SizedBox(height: 6),
            Text("Monday - Friday: 9:00 AM - 5:00 PM"),
            Divider(),
            Text(
              "For urgent issues, please contact the school office directly.",
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Close",
              style: TextStyle(color: Colors.orange),
            ),
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
      applicationIcon: const Icon(Icons.school, size: 40, color: Colors.orange),
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
              "© 2025 Smart School. All rights reserved.",
        ),
      ],
    );
  }

  Widget _buildNoChildrenWidget() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No Children Linked',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please contact the school admin to link your children.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showHelpDialog(),
              icon: const Icon(Icons.support_agent, size: 16),
              label: const Text("Contact Support"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      String name,
      String className,
      String section,
      String rollNo,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 25, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(Icons.school, size: 35, color: Colors.orange),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            "Class $className-$section | Roll No: $rollNo",
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildChildSelector(List<QueryDocumentSnapshot> students) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Child',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: students.length,
              itemBuilder: (context, index) {
                final doc = students[index];
                final d = doc.data() as Map<String, dynamic>;
                final isSelected = selectedStudentId == doc.id;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedStudentId = doc.id;
                      _updateCurrentStudentData(d);
                      _loadUnreadCounts();
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.orange : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? Colors.orange : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 12,
                          color: isSelected ? Colors.white : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          d['name'] ?? 'Student',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        title: "Homework",
                        value: "View",
                        color: Colors.blue,
                        icon: Icons.assignment,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => HomeworkViewPage(
                                studentId: studentId,
                                className: _currentClassName,
                                section: _currentSection,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        title: "Complaint",
                        value: "Raise",
                        color: Colors.orange,
                        icon: Icons.feedback,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) =>
                                  ParentComplaintPage(studentId: studentId),
                            ),
                          ).then((_) => _loadUnreadCounts());
                        },
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
    final attendanceDates =
    await FirebaseFirestore.instance
        .collection('schools')
        .doc(AppConfig.schoolId)
        .collection('attendance')
        .get();

    int present = 0;
    for (var dateDoc in attendanceDates.docs) {
      final record =
      await dateDoc.reference.collection('records').doc(studentId).get();
      if (record.exists && record.data()?['status'] == 'Present') {
        present++;
      }
    }
    return present;
  }

  Future<int> _getTotalCount() async {
    final attendanceDates =
    await FirebaseFirestore.instance
        .collection('schools')
        .doc(AppConfig.schoolId)
        .collection('attendance')
        .get();
    return attendanceDates.docs.length;
  }

  Future<Map<String, double>> _getFeeData(String studentId) async {
    final fees =
    await FirebaseFirestore.instance
        .collection('schools')
        .doc(AppConfig.schoolId)
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

  Widget _buildStudentDetailsCard(Map<String, dynamic> data) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person_outline, color: Colors.orange, size: 16),
                SizedBox(width: 6),
                Text(
                  'Student Info',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 12),
            _infoRow('Name', data['name'] ?? 'N/A'),
            _infoRow(
              'Class',
              '${data['class'] ?? ''}-${data['section'] ?? ''}',
            ),
            _infoRow('Roll No', data['rollNo'] ?? 'N/A'),
            if (_currentAdmissionNo.isNotEmpty)
              _infoRow('Admission No', _currentAdmissionNo),
            if (data['fatherName'] != null &&
                data['fatherName'].toString().isNotEmpty)
              _infoRow('Father', data['fatherName']),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeSection() {
    return StreamBuilder<QuerySnapshot>(
      stream:
      FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('student_fees')
          .where('studentId', isEqualTo: selectedStudentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Center(
                child: Text(
                  'No fee records found',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          );
        }

        double totalPaid = 0;
        double totalDue = 0;

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final amount = (data['amount'] ?? 0).toDouble();
          final status = data['status'] ?? 'pending';
          if (status == 'paid') {
            totalPaid += amount;
          } else {
            totalDue += amount;
          }
        }

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.receipt_outlined,
                      color: Colors.orange,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Fee Summary',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'Paid',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                          Text(
                            '₹${totalPaid.toInt()}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 25,
                      color: Colors.grey.shade300,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'Due',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                          Text(
                            '₹${totalDue.toInt()}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
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
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _actionChip(Icons.calendar_today, "Attendance", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ParentAttendanceViewPage(
                        studentId: selectedStudentId!,
                        studentName: _currentStudentName,
                        className: _currentClassName,
                        section: _currentSection,
                      ),
                    ),
                  );
                }),
                _actionChip(Icons.assignment, "Homework", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => HomeworkViewPage(
                        studentId: selectedStudentId!,
                        className: _currentClassName,
                        section: _currentSection,
                      ),
                    ),
                  );
                }),
                _actionChip(Icons.assessment, "Results", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ParentViewResultsPage(
                        studentId: selectedStudentId!,
                        studentName: _currentStudentName,
                      ),
                    ),
                  );
                }),
                _actionChip(Icons.schedule, "Timetable", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => StudentTimetablePage(
                        studentId: selectedStudentId!,
                        studentName: _currentStudentName,
                        className: _currentClassName,
                        section: _currentSection,
                      ),
                    ),
                  );
                }),
                _actionChip(Icons.calendar_month, "Exam Schedule", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ParentExamSchedulePage(
                        className: _currentClassName,
                        section: _currentSection,
                      ),
                    ),
                  );
                }),
                _actionChip(Icons.receipt, "Fee History", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => FeeHistoryPage(studentId: selectedStudentId!),
                    ),
                  );
                }),
                _actionChip(Icons.payment, "Fee Status", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => FeeStatusPage(studentId: selectedStudentId),
                    ),
                  );
                }),
                _actionChip(Icons.announcement, "Notices", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ParentNoticesPage(
                        className: _currentClassName,
                        section: _currentSection,
                      ),
                    ),
                  );
                }),
                _actionChip(Icons.feedback, "Complaint", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ParentComplaintPage(
                        studentId: selectedStudentId!,
                      ),
                    ),
                  ).then((_) => _loadUnreadCounts());
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionChip(IconData icon, String label, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 14, color: Colors.orange),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: onTap,
      backgroundColor: Colors.grey.shade100,
      padding: const EdgeInsets.all(4),
    );
  }

  Widget _buildAttendanceTab(String studentId, String studentName) {
    return FutureBuilder<QuerySnapshot>(
      future:
      FirebaseFirestore.instance
          .collectionGroup('records')
          .where('studentId', isEqualTo: studentId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 40, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'No attendance records found',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        }

        int present = 0;
        int absent = 0;
        int late = 0;
        List<Map<String, dynamic>> records = [];

        for (var doc in snapshot.data!.docs) {
          final parentDoc = doc.reference.parent.parent;
          final date = parentDoc?.id ?? '';
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'Absent';

          if (status == 'Present')
            present++;
          else if (status == 'Late')
            late++;
          else
            absent++;

          if (date.isNotEmpty) {
            records.add({'date': date, 'status': status});
          }
        }

        records.sort((a, b) => b['date'].compareTo(a['date']));
        if (records.length > 10) records = records.sublist(0, 10);

        int total = present + absent + late;
        double attendanceRate = total > 0 ? (present / total) * 100 : 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: "Present",
                      value: present.toString(),
                      color: Colors.green,
                      icon: Icons.check_circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (late > 0)
                    Expanded(
                      child: _StatCard(
                        title: "Late",
                        value: late.toString(),
                        color: Colors.orange,
                        icon: Icons.access_time,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      title: "Absent",
                      value: absent.toString(),
                      color: Colors.red,
                      icon: Icons.cancel,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      title: "Rate",
                      value: "${attendanceRate.toStringAsFixed(1)}%",
                      color: Colors.orange,
                      icon: Icons.trending_up,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recent Records',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: records.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final record = records[index];
                          final date =
                              DateTime.tryParse(record['date']) ??
                                  DateTime.now();
                          final status = record['status'];
                          final statusColor =
                          status == 'Present'
                              ? Colors.green
                              : (status == 'Late'
                              ? Colors.orange
                              : Colors.red);

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            leading: Icon(
                              status == 'Present'
                                  ? Icons.check_circle
                                  : (status == 'Late'
                                  ? Icons.access_time
                                  : Icons.cancel),
                              color: statusColor,
                              size: 18,
                            ),
                            title: Text(
                              DateFormat('dd MMM yyyy').format(date),
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(fontSize: 9, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}