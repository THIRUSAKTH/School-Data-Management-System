import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app_config.dart';

class FeeHistoryPage extends StatelessWidget {
  const FeeHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fee History")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('schools')
            .doc(AppConfig.schoolId)
            .collection('student_fees')
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const CircularProgressIndicator();
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No fees found"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data();

              return ListTile(
                title: Text("₹${data['amount']}"),
                subtitle: Text("Status: ${data['status']}"),
              );
            },
          );
        },
      ),
    );
  }
}