import 'package:flutter/material.dart';

import 'student_management_page.dart';
import 'admin_attendance_overview.dart';
import 'admin_feeupload_page.dart';
import 'admin_fee_report_page.dart';

import 'teacher_management_page.dart';
import 'create_class_page.dart';
import 'class_management_page.dart';

class AdminDashboard extends StatelessWidget {
  final String schoolId;

  const AdminDashboard({
    super.key,
    required this.schoolId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Center(
                child: Text(
                  "Admin Panel",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ),

            _drawerItem(
              context,
              Icons.school,
              "Teachers",
              TeacherManagementPage(schoolId: schoolId),
            ),

            _drawerItem(
              context,
              Icons.groups,
              "Students",
              StudentManagementPage(schoolId: schoolId),
            ),

            // ⭐ CLASS SYSTEM
            _drawerItem(
              context,
              Icons.add_box,
              "Create Class",
              CreateClassPage(schoolId: schoolId),
            ),

            _drawerItem(
              context,
              Icons.class_,
              "Manage Classes",
              ClassManagementPage(schoolId: schoolId),
            ),

            _drawerItem(
              context,
              Icons.fact_check,
              "Attendance Overview",
              AdminAttendanceOverviewPage(),
            ),

            _drawerItem(
              context,
              Icons.currency_rupee,
              "Upload Fees",
              AdminFeeUploadPage(),
            ),

            _drawerItem(
              context,
              Icons.analytics,
              "Fees Report",
              AdminFeeReportPage(),
            ),
          ],
        ),
      ),

      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text("Admin Dashboard"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount:
          MediaQuery.of(context).size.width > 800 ? 4 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: const [
            DashboardCard("Students", "520", Icons.people, Colors.blue),
            DashboardCard("Teachers", "42", Icons.school, Colors.purple),
            DashboardCard("Fees Pending", "₹1,24,000",
                Icons.currency_rupee, Colors.orange),
            DashboardCard("Attendance", "94%",
                Icons.check_circle, Colors.green),
          ],
        ),
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
      leading: Icon(icon),
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
}

/* ================= DASHBOARD CARD ================= */

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const DashboardCard(
      this.title,
      this.value,
      this.icon,
      this.color, {
        super.key,
      });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(title,
              style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}