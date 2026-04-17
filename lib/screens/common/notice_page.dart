import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app_config.dart';

class NoticePage extends StatelessWidget {
  const NoticePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notices")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('schools')
            .doc(AppConfig.schoolId)
            .collection('notices')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No notices available"));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data();

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(data['title'] ?? ""),
                  subtitle: Text(data['message'] ?? ""),
                ),
              );
            },
          );
        },
      ),
    );
  }
}