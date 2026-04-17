import 'package:flutter/material.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reports")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: const [
            Text("Attendance: 85%"),
            SizedBox(height: 10),
            Text("Fees Paid: ₹5000"),
          ],
        ),
      ),
    );
  }
}