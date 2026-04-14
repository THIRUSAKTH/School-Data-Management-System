import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:schoolprojectjan/app_config.dart'; // ✅ ADDED
import 'package:schoolprojectjan/screens/admin/exam_management_page.dart';
import 'package:schoolprojectjan/screens/admin/school_settings_page.dart';
import 'package:schoolprojectjan/screens/admin/select_class_for_attendance_page.dart';
import 'admin_analytics_page.dart';
import 'admin_attendance_overview.dart';
import 'admin_feeupload_page.dart';
import 'class_management_page.dart';
import 'create_class_page.dart';
import 'student_management_page.dart';
import 'teacher_management_page.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key}); // ✅ REMOVED schoolId

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      drawer: _buildDrawer(context),

      /// ================= APPBAR =================
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .snapshots(), // ✅ FIXED
          builder: (context, snapshot) {
            String schoolName = "School";
            String logoUrl = "";

            if (snapshot.hasData && snapshot.data!.exists) {
              final school = snapshot.data!;
              schoolName = school['schoolName'] ?? "School";
              logoUrl = school['logoUrl'] ?? "";
            }

            return Row(
              children: [
                if (logoUrl.isNotEmpty)
                  CircleAvatar(
                    backgroundImage: NetworkImage(logoUrl),
                    radius: 18,
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schoolName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        "Admin Dashboard",
                        style: TextStyle(
                            fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      /// ================= BODY =================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// ================= CARDS =================
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _liveAnimatedCard(
                  "Students",
                  Icons.people,
                  Colors.blue,
                  FirebaseFirestore.instance
                      .collection('schools')
                      .doc(AppConfig.schoolId)
                      .collection('students')
                      .snapshots(),
                ),
                _liveAnimatedCard(
                  "Teachers",
                  Icons.school,
                  Colors.purple,
                  FirebaseFirestore.instance
                      .collection('schools')
                      .doc(AppConfig.schoolId)
                      .collection('teachers')
                      .snapshots(),
                ),
                _liveAnimatedCard(
                  "Fees Records",
                  Icons.currency_rupee,
                  Colors.orange,
                  FirebaseFirestore.instance
                      .collection('schools')
                      .doc(AppConfig.schoolId)
                      .collection('fees')
                      .snapshots(),
                ),
                _liveAnimatedCard(
                  "Attendance Days",
                  Icons.check_circle,
                  Colors.green,
                  FirebaseFirestore.instance
                      .collection('schools')
                      .doc(AppConfig.schoolId)
                      .collection('attendance')
                      .snapshots(),
                ),
              ],
            ),

            const SizedBox(height: 28),

            /// ================= OVERVIEW =================
            const Text(
              "Today's Overview",
              style:
              TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                  )
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("• Attendance marked for 4 classes"),
                  SizedBox(height: 6),
                  Text("• 2 students absent today"),
                  SizedBox(height: 6),
                  Text("• No fee updates today"),
                ],
              ),
            ),

            const SizedBox(height: 28),

            /// ================= QUICK ACTION =================
            const Text(
              "Quick Actions",
              style:
              TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                _quickAction(Icons.person_add, "Add Student"),
                _quickAction(Icons.school, "Add Teacher"),
                _quickAction(Icons.bar_chart, "Reports"),
              ],
            ),

            const SizedBox(height: 30),

            /// ================= CHARTS =================
            attendanceChart(),
            feesChart(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// ================= DRAWER =================
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [

          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            child: const Text("Admin Panel",
                style: TextStyle(color: Colors.white)),
          ),

          _drawerItem(context, Icons.school, "Teachers",
              TeacherManagementPage(schoolId: AppConfig.schoolId)),
          _drawerItem(context, Icons.groups, "Students",
              StudentManagementPage(schoolId: AppConfig.schoolId)),
          _drawerItem(context, Icons.add_box, "Create Class",
              CreateClassPage(schoolId: AppConfig.schoolId)),
          _drawerItem(context, Icons.class_, "Manage Classes",
              ClassManagementPage(schoolId: AppConfig.schoolId)),
          _drawerItem(context, Icons.fact_check,
              "Attendance Overview",
              AdminAttendanceOverviewPage(schoolId: AppConfig.schoolId)),
          _drawerItem(context, Icons.bar_chart,
              "Attendance Reports",
              SelectClassForAttendancePage(schoolId: AppConfig.schoolId)),
          _drawerItem(context, Icons.currency_rupee,
              "Upload Fees",
              AdminFeeUploadPage(schoolId: AppConfig.schoolId)),
          _drawerItem(context, FontAwesomeIcons.bookOpen,
              "Exam Management",
              ExamManagementPage(schoolId: AppConfig.schoolId)),
          _drawerItem(context, Icons.analytics,
              "Analytics",
              AdminAnalyticsPage(schoolId: AppConfig.schoolId)),
          _drawerItem(context, Icons.settings,
              "School Settings",
              SchoolSettingsPage(schoolId: AppConfig.schoolId)),
        ],
      ),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String title, Widget page) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueGrey),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },
    );
  }

  /// ================= CARDS =================
  Widget _liveAnimatedCard(String title, IconData icon, Color color, Stream<QuerySnapshot> stream) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        int count = snapshot.hasData ? snapshot.data!.docs.length : 0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 10),
              Text("$count"),
              Text(title),
            ],
          ),
        );
      },
    );
  }

  Widget attendanceChart() => Container(height: 200);
  Widget feesChart() => Container(height: 200);

  Widget _quickAction(IconData icon, String label) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}