import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SelectChildPage extends StatefulWidget {
  final String parentId;

  const SelectChildPage({super.key, required this.parentId});

  @override
  State<SelectChildPage> createState() => _SelectChildPageState();
}

class _SelectChildPageState extends State<SelectChildPage> {
  List<String> childrenIds = [];

  @override
  void initState() {
    super.initState();
    fetchChildren();
  }

  Future<void> fetchChildren() async {
    final parentDoc = await FirebaseFirestore.instance
        .collection('parents')
        .doc(widget.parentId)
        .get();

    if (parentDoc.exists) {
      List<dynamic> children = parentDoc['children'] ?? [];
      setState(() {
        childrenIds = List<String>.from(children);
      });
    }
  }

  Future<DocumentSnapshot> getStudentData(String studentId) {
    return FirebaseFirestore.instance
        .collection('students')
        .doc(studentId)
        .get();
  }

  void onChildSelected(String studentId) {
    Navigator.pushReplacementNamed(
      context,
      '/parent_home',
      arguments: studentId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Your Child"),
        centerTitle: true,
      ),
      body: childrenIds.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: childrenIds.length,
        itemBuilder: (context, index) {
          String studentId = childrenIds[index];

          return FutureBuilder<DocumentSnapshot>(
            future: getStudentData(studentId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const ListTile(
                  title: Text("Loading..."),
                );
              }

              var data = snapshot.data!;
              String name = data['name'] ?? '';
              String className = data['class'] ?? '';

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(name),
                  subtitle: Text("Class: $className"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => onChildSelected(studentId),
                ),
              );
            },
          );
        },
      ),
    );
  }
}