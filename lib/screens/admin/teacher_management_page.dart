import 'package:flutter/material.dart';
import 'admin_add_teacher_page.dart';
import 'teacher_list_page.dart';

class TeacherManagementPage extends StatelessWidget {
  final String schoolId;

  const TeacherManagementPage({
    super.key,
    required this.schoolId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Teacher Management"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            _card(
              context,
              icon: Icons.person_add,
              title: "Add Teacher",
              subtitle: "Create new teacher account",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AdminAddTeacherPage(schoolId: schoolId),
                ),
              ),
            ),

            _card(
              context,
              icon: Icons.list,
              title: "Teachers List",
              subtitle: "View all teachers",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      TeacherListPage(schoolId: schoolId),
                ),
              ),
            ),

            _card(
              context,
              icon: Icons.school,
              title: "Assign Classes",
              subtitle: "Select teacher and assign class",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      TeacherListPage(
                        schoolId: schoolId,
                        isAssignMode: true, // 👈 important
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }
}