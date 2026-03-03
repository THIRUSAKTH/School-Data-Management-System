import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:schoolprojectjan/screens/admin/select_class_for_attendance_page.dart';

import 'student_management_page.dart';
import 'admin_attendance_overview.dart';
import 'admin_feeupload_page.dart';
import 'admin_fee_report_page.dart';
import 'teacher_management_page.dart';
import 'create_class_page.dart';
import 'class_management_page.dart';

class AdminDashboard extends StatelessWidget {
  final String schoolId;

  const AdminDashboard({super.key, required this.schoolId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      /// 🔷 Drawer (unchanged)
      drawer: _buildDrawer(context),

      /// 🔷 Gradient AppBar
      appBar: AppBar(iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
            ),
          ),
        ),
        title: const Text("Admin Dashboard",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
        centerTitle: true,
      ),

      /// 🔷 Real-time Dashboard Body
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolId)
            .snapshots(),
        builder: (context, snapshot) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              crossAxisCount:
              MediaQuery.of(context).size.width > 800 ? 4 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [

                /// 👨‍🎓 Students Count
                _liveCountCard(
                  title: "Students",
                  icon: Icons.people,
                  color: Colors.blue,
                  stream: FirebaseFirestore.instance
                      .collection('schools')
                      .doc(schoolId)
                      .collection('students')
                      .snapshots(),
                ),

                /// 👩‍🏫 Teachers Count
                _liveCountCard(
                  title: "Teachers",
                  icon: Icons.school,
                  color: Colors.purple,
                  stream: FirebaseFirestore.instance
                      .collection('schools')
                      .doc(schoolId)
                      .collection('teachers')
                      .snapshots(),
                ),

                /// 💰 Fees Documents Count
                _liveCountCard(
                  title: "Fees Records",
                  icon: Icons.currency_rupee,
                  color: Colors.orange,
                  stream: FirebaseFirestore.instance
                      .collection('schools')
                      .doc(schoolId)
                      .collection('fees')
                      .snapshots(),
                ),

                /// 📊 Attendance Days Count
                _liveCountCard(
                  title: "Attendance Days",
                  icon: Icons.check_circle,
                  color: Colors.green,
                  stream: FirebaseFirestore.instance
                      .collection('schools')
                      .doc(schoolId)
                      .collection('attendance')
                      .snapshots(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 🔷 Drawer Builder
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [

          const DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.admin_panel_settings,
                    color: Colors.white, size: 40),
                SizedBox(height: 8),
                Text("Admin Panel",
                    style:
                    TextStyle(color: Colors.white, fontSize: 20)),
              ],
            ),
          ),

          _sectionTitle("Management"),

          _drawerItem(context, Icons.school, "Teachers",
              TeacherManagementPage(schoolId: schoolId)),

          _drawerItem(context, Icons.groups, "Students",
              StudentManagementPage(schoolId: schoolId)),

          _sectionTitle("Class System"),

          _drawerItem(context, Icons.add_box, "Create Class",
              CreateClassPage(schoolId: schoolId)),

          _drawerItem(context, Icons.class_, "Manage Classes",
              ClassManagementPage(schoolId: schoolId)),

          _sectionTitle("Attendance"),

          _drawerItem(context, Icons.fact_check,
              "Attendance Overview", AdminAttendanceOverviewPage()),

          _drawerItem(context, Icons.bar_chart,
              "Attendance Reports",
              SelectClassForAttendancePage(schoolId: schoolId)),

          _sectionTitle("Fees"),

          _drawerItem(context, Icons.currency_rupee,
              "Upload Fees", AdminFeeUploadPage()),

          _drawerItem(context, Icons.analytics,
              "Fees Report", AdminFeeReportPage()),
        ],
      ),
    );
  }

  /// 🔷 Reusable Drawer Item
  Widget _drawerItem(
      BuildContext context,
      IconData icon,
      String title,
      Widget page,
      ) {
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

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 0, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  /// 🔷 Live Count Card
  Widget _liveCountCard({
    required String title,
    required IconData icon,
    required Color color,
    required Stream<QuerySnapshot> stream,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {

        int count = snapshot.hasData ? snapshot.data!.docs.length : 0;

        return Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              CircleAvatar(
                backgroundColor: color.withOpacity(.15),
                child: Icon(icon, color: color),
              ),

              const Spacer(),

              Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(title,
                  style: const TextStyle(color: Colors.grey)),
            ],
          ),
        );
      },
    );
  }
}