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
  final Map<String, bool> attendance = {};

  String get today =>
      DateTime.now().toIso8601String().split("T")[0];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text("Attendance ${widget.className}-${widget.section}"),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolId)
            .collection('students')
            .where('class', isEqualTo: widget.className.trim())
            .where('section', isEqualTo: widget.section.trim())
            .snapshots(), // 🔥 removed orderBy (avoid index issue)
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No students found for this class",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final students = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 90),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final doc = students[index];
              final id = doc.id;
              final data = doc.data() as Map<String, dynamic>;

              final name = data['name'] ?? "No Name";
              final rollNo = data['rollNo'] ?? "";

              attendance.putIfAbsent(id, () => true); // default Present

              return Card(
                margin: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withOpacity(0.2),
                    child: Text(
                      rollNo.toString(),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    attendance[id]! ? "Present" : "Absent",
                    style: TextStyle(
                      color: attendance[id]!
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Switch(
                    value: attendance[id]!,
                    activeColor: Colors.green,
                    onChanged: (v) {
                      setState(() {
                        attendance[id] = v;
                      });
                    },
                  ),
                ),
              );
            },
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
    try {
      final ref = FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('attendance')
          .doc(today);

      await ref.set({
        '${widget.className}_${widget.section}': attendance,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Attendance saved successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
}
