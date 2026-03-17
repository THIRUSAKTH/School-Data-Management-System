import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:schoolprojectjan/screens/admin/school_settings_page.dart';
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

      drawer: _buildDrawer(context),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('schools')
              .doc(schoolId)
              .snapshots(),
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const Text(
                        "Admin Dashboard",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      )
                    ],
                  ),
                )
              ],
            );
          },
        ),
      ),


      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// SUMMARY CARDS

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [

                _liveAnimatedCard(
                  title: "Students",
                  icon: Icons.people,
                  color: Colors.blue,
                  stream: FirebaseFirestore.instance
                      .collection('schools')
                      .doc(schoolId)
                      .collection('students')
                      .snapshots(),
                ),

                _liveAnimatedCard(
                  title: "Teachers",
                  icon: Icons.school,
                  color: Colors.purple,
                  stream: FirebaseFirestore.instance
                      .collection('schools')
                      .doc(schoolId)
                      .collection('teachers')
                      .snapshots(),
                ),

                _liveAnimatedCard(
                  title: "Fees Records",
                  icon: Icons.currency_rupee,
                  color: Colors.orange,
                  stream: FirebaseFirestore.instance
                      .collection('schools')
                      .doc(schoolId)
                      .collection('fees')
                      .snapshots(),
                ),

                _liveAnimatedCard(
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

            const SizedBox(height: 28),

            /// TODAY OVERVIEW

            const Text(
              "Today's Overview",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
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

            /// QUICK ACTIONS

            const Text(
              "Quick Actions",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _quickAction(Icons.person_add, "Add Student"),
                _quickAction(Icons.school, "Add Teacher"),
                _quickAction(Icons.bar_chart, "Reports"),
              ],
            ),

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

          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('schools')
                .doc(schoolId)
                .snapshots(),
            builder: (context, snapshot) {

              String schoolName = "School";
              String logoUrl = "";

              if (snapshot.hasData && snapshot.data!.exists) {
                final school = snapshot.data!;
                schoolName = school['schoolName'] ?? "School";
                logoUrl = school['logoUrl'] ?? "";
              }

              return DrawerHeader(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    /// LOGO
                    CircleAvatar(
                      radius: 26, // slightly reduced
                      backgroundColor: Colors.white,
                      backgroundImage: logoUrl.isNotEmpty
                          ? NetworkImage(logoUrl)
                          : null,
                      child: logoUrl.isEmpty
                          ? const Icon(Icons.school, size: 26)
                          : null,
                    ),

                    const SizedBox(height: 6),

                    /// SCHOOL NAME
                    Flexible(
                      child: Text(
                        schoolName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 2),

                    const Text(
                      "Admin Panel",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          _drawerItem(context, Icons.school, "Teachers",
              TeacherManagementPage(schoolId: schoolId)),

          _drawerItem(context, Icons.groups, "Students",
              StudentManagementPage(schoolId: schoolId)),

          _drawerItem(context, Icons.add_box, "Create Class",
              CreateClassPage(schoolId: schoolId)),

          _drawerItem(context, Icons.class_, "Manage Classes",
              ClassManagementPage(schoolId: schoolId)),

          _drawerItem(context, Icons.fact_check,
              "Attendance Overview",
              AdminAttendanceOverviewPage()),

          _drawerItem(context, Icons.bar_chart,
              "Attendance Reports",
              SelectClassForAttendancePage(schoolId: schoolId)),

          _drawerItem(context, Icons.currency_rupee,
              "Upload Fees",
              AdminFeeUploadPage()),

          _drawerItem(context, Icons.analytics,
              "Fees Report",
              AdminFeeReportPage()),

          _drawerItem(context, Icons.settings,
              "School Settings",
              SchoolSettingsPage(schoolId: schoolId)),
        ],
      ),
    );
  }

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

  /// ================= LIVE CARD =================

  Widget _liveAnimatedCard({
    required String title,
    required IconData icon,
    required Color color,
    required Stream<QuerySnapshot> stream,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {

        int count = snapshot.hasData ? snapshot.data!.docs.length : 0;

        return TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: count),
          duration: const Duration(milliseconds: 800),
          builder: (context, value, child) {
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
                    value.toString(),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    title,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  //dcDES/ ================= QUICK ACTION =================

  Widget _quickAction(IconData icon, String label) {
    return Container(
      width: 100,
      padding:
      const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(0.05),
            blurRadius: 8,
          )
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(height: 8),
          Text(label,
              style:
              const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
