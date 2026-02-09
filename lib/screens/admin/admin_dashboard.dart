import 'package:flutter/material.dart';
import 'package:schoolprojectjan/screens/admin/admin-add-student-page.dart';
import 'package:schoolprojectjan/screens/admin/admin_attendance_overview.dart';
import 'package:schoolprojectjan/screens/admin/admin_fee_report_page.dart';
import 'package:schoolprojectjan/screens/admin/admin_feeupload_page.dart';
import 'package:schoolprojectjan/screens/admin/student_management_page.dart';
import 'package:schoolprojectjan/screens/admin/admin_add_teacher_page.dart';

class AdminDashboard extends StatelessWidget {
  final String schoolId; // ✅ ADD THIS

  const AdminDashboard({
    super.key,
    required this.schoolId, // ✅ REQUIRED
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      drawer: Drawer(
        width: 250,
        child: ListView(
          children: [
            const DrawerHeader(child: Text("")),

            ListTile(
              leading: const Icon(Icons.fact_check_outlined),
              title: const Text("Attendance Overview"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminAttendanceOverviewPage(),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text("Teacher Management"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AdminAddTeacherPage(schoolId: schoolId), // ✅ FIXED
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.groups_rounded),
              title: const Text("Students Management"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>StudentManagementPage(schoolId: schoolId),

                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.currency_rupee),
              title: const Text("Fees"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminFeeUploadPage(),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text("Fees Report"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminFeeReportPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),

      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text("Admin Dashboard"),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.logout),
          )
        ],
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          int crossAxisCount = 2;
          if (width >= 900) {
            crossAxisCount = 4;
          } else if (width >= 600) {
            crossAxisCount = 3;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Overview",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: width < 600 ? 1.3 : 1.6,
                  children: const [
                    DashboardCard(
                      title: "Students",
                      value: "520",
                      icon: Icons.people,
                      color: Colors.blue,
                    ),
                    DashboardCard(
                      title: "Teachers",
                      value: "42",
                      icon: Icons.school,
                      color: Colors.purple,
                    ),
                    DashboardCard(
                      title: "Fees Pending",
                      value: "₹1,24,000",
                      icon: Icons.currency_rupee,
                      color: Colors.orange,
                    ),
                    DashboardCard(
                      title: "Attendance",
                      value: "94%",
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                const Text(
                  "Quick Actions",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                _QuickActionsCard(),
              ],
            ),
          );
        },
      ),
    );
  }
}

/* ========================================================= */

class _QuickActionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: const [
          ListTile(
            leading: Icon(Icons.person),
            title: Text("Manage Students"),
            trailing: Icon(Icons.arrow_forward_ios, size: 14),
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.school),
            title: Text("Manage Teachers"),
            trailing: Icon(Icons.arrow_forward_ios, size: 14),
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text("Broadcast Notice"),
            trailing: Icon(Icons.arrow_forward_ios, size: 14),
          ),
        ],
      ),
    );
  }
}

/* ========================================================= */

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),

          const SizedBox(height: 10),

          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 2),

          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
