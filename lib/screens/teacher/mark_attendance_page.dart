import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MarkAttendancePage extends StatefulWidget {
  final String schoolId;
  final String className;
  final String section;

  const MarkAttendancePage({
    super.key,
    required this.schoolId,
    required this.className,
    required this.section,
  });

  @override
  State<MarkAttendancePage> createState() => _MarkAttendancePageState();
}

class _MarkAttendancePageState extends State<MarkAttendancePage> {
  final Map<String, bool> _attendance = {};

  String get today =>
      DateTime.now().toIso8601String().split("T")[0];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          "Attendance ${widget.className}-${widget.section}",
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolId)
            .collection('students')
            .where('class', isEqualTo: widget.className)
            .where('section', isEqualTo: widget.section)
            .orderBy('rollNo')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No students found"));
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: snapshot.data!.docs.map((doc) {
              final studentId = doc.id;
              final name = doc['name'];

              _attendance.putIfAbsent(studentId, () => true);

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: ListTile(
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: Switch(
                    value: _attendance[studentId]!,
                    activeColor: Colors.green,
                    onChanged: (v) {
                      setState(() {
                        _attendance[studentId] = v;
                      });
                    },
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green,
        icon: const Icon(Icons.save),
        label: const Text("Save Attendance"),
        onPressed: _saveAttendance,
      ),
    );
  }

  Future<void> _saveAttendance() async {
    final ref = FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('attendance')
        .doc(today);

    // create date doc
    await ref.set({
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // save class attendance
    await ref
        .collection('${widget.className}-${widget.section}')
        .doc('records')
        .set(_attendance);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Attendance saved successfully")),
    );
  }
}
