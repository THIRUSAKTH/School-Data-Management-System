import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ParentDashboard extends StatelessWidget {
  final String schoolId;

  const ParentDashboard({super.key, required this.schoolId});

  @override
  Widget build(BuildContext context) {
    final parentUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text("Parent Dashboard"),centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolId)
            .collection('students')
            .where('parentUid', isEqualTo: parentUid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No child linked to this parent"),
            );
          }

          final student = snapshot.data!.docs.first;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StudentHeader(
                name: student['name'],
                className: student['class'],
                section: student['section'],
                rollNo: student['rollNo'],
              ),

              const SizedBox(height: 20),

              const _InfoCard(
                title: "Attendance",
                value: "Coming Soon",
                icon: Icons.fact_check,
                color: Colors.green,
              ),

              const _InfoCard(
                title: "Homework",
                value: "Coming Soon",
                icon: Icons.book,
                color: Colors.blue,
              ),

              const _InfoCard(
                title: "Fees",
                value: "Coming Soon",
                icon: Icons.payment,
                color: Colors.red,
              ),

              const _InfoCard(
                title: "Results",
                value: "Coming Soon",
                icon: Icons.bar_chart,
                color: Colors.purple,
              ),

              const _InfoCard(
                title: "Notices",
                value: "Coming Soon",
                icon: Icons.notifications,
                color: Colors.orange,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StudentHeader extends StatelessWidget {
  final String name;
  final String className;
  final String section;
  final String rollNo;

  const _StudentHeader({
    required this.name,
    required this.className,
    required this.section,
    required this.rollNo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.orange,
              child: Icon(Icons.person, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text("Class: $className  |  Section: $section"),
            Text("Roll No: $rollNo"),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        trailing: Text(
          value,
          style: TextStyle(
              fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }
}
