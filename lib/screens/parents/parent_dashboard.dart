import 'package:flutter/material.dart';

class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text("Parent Dashboard"),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _InfoCard(
            title: "Attendance",
            value: "95%",
            icon: Icons.fact_check,
            color: Colors.green,
          ),
          _InfoCard(
            title: "Homework",
            value: "2 New Tasks",
            icon: Icons.book,
            color: Colors.blue,
          ),
          _InfoCard(
            title: "Fees",
            value: "₹3,500 Pending",
            icon: Icons.payment,
            color: Colors.red,
          ),
          _InfoCard(
            title: "Results",
            value: "Mid-term Available",
            icon: Icons.bar_chart,
            color: Colors.purple,
          ),
          _InfoCard(
            title: "Notices",
            value: "1 New Notice",
            icon: Icons.notifications,
            color: Colors.orange,
          ),
        ],
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        trailing: Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}