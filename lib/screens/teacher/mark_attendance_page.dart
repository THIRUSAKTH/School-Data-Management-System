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
  Map<String, bool> attendance = {};

  @override
  Widget build(BuildContext context) {
    final classKey = "${widget.className}_${widget.section}";

    return Scaffold(
      appBar: AppBar(
        title: Text("Attendance ${widget.className}-${widget.section}"),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolId)
            .collection('students')
            .where('class', isEqualTo: widget.className)
            .where('section', isEqualTo: widget.section)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.data!.docs.isEmpty) {
            return const Center(child: Text("No students found"));
          }

          return ListView(
            children: snap.data!.docs.map((doc) {
              final studentId = doc.id;
              final name = doc['name'];

              attendance.putIfAbsent(studentId, () => false);

              return CheckboxListTile(
                title: Text(name),
                value: attendance[studentId],
                onChanged: (v) {
                  setState(() {
                    attendance[studentId] = v!;
                  });
                },
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
    final date = DateTime.now().toString().split(' ')[0];
    final classKey = "${widget.className}_${widget.section}";

    await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('attendance')
        .doc(date)
        .set({
      classKey: attendance,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Attendance saved")));
  }
}
