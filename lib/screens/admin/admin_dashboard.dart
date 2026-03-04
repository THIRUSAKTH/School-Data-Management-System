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

      /// 🔷 Drawer (UNCHANGED)
      drawer: _buildDrawer(context),

      appBar: AppBar(
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      /// 🔷 UPDATED BODY ONLY
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// ================= SUMMARY CARDS =================
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

            /// ================= ATTENDANCE INFO BOX =================
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

            /// ================= QUICK ACTIONS =================
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

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// ================= Drawer (UNCHANGED) =================

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [

          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
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

          _drawerItem(context, Icons.school, "Teachers",
              TeacherManagementPage(schoolId: schoolId)),

          _drawerItem(context, Icons.groups, "Students",
              StudentManagementPage(schoolId: schoolId)),

          _drawerItem(context, Icons.add_box, "Create Class",
              CreateClassPage(schoolId: schoolId)),

          _drawerItem(context, Icons.class_, "Manage Classes",
              ClassManagementPage(schoolId: schoolId)),

          _drawerItem(context, Icons.fact_check,
              "Attendance Overview", AdminAttendanceOverviewPage()),

          _drawerItem(context, Icons.bar_chart,
              "Attendance Reports",
              SelectClassForAttendancePage(schoolId: schoolId)),

          _drawerItem(context, Icons.currency_rupee,
              "Upload Fees", AdminFeeUploadPage()),

          _drawerItem(context, Icons.analytics,
              "Fees Report", AdminFeeReportPage()),
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

  /// ================= Animated Live Card =================

  Widget _liveAnimatedCard({
    required String title,
    required IconData icon,
    required Color color,
    required Stream<QuerySnapshot> stream,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {

        int count =
        snapshot.hasData ? snapshot.data!.docs.length : 0;

        return TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 500),
          builder: (context, double value, child) {
            return Transform.scale(
              scale: value,
              child: child,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color:
                  Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                )
              ],
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor:
                  color.withOpacity(.15),
                  child:
                  Icon(icon, color: color),
                ),
                const Spacer(),
                Text(
                  count.toString(),
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight:
                      FontWeight.bold),
                ),
                Text(title,
                    style: const TextStyle(
                        color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }

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