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

  bool isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text("Attendance ${widget.className}-${widget.section}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle),
            tooltip: "Mark All Present",
            onPressed: () {
              setState(() {
                attendance.updateAll((key, value) => true);
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.cancel),
            tooltip: "Mark All Absent",
            onPressed: () {
              setState(() {
                attendance.updateAll((key, value) => false);
              });
            },
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolId)
            .collection('students')
            .where('class', isEqualTo: widget.className)
            .where('section', isEqualTo: widget.section)
            .snapshots(),
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

          /// INIT DEFAULT VALUES
          for (var doc in students) {
            attendance.putIfAbsent(doc.id, () => true);
          }

          int present = attendance.values.where((e) => e).length;
          int absent = attendance.length - present;

          return Column(
            children: [

              /// SUMMARY BOX
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text("Present: $present",
                        style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold)),
                    Text("Absent: $absent",
                        style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

              /// STUDENT LIST
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: students.length,
                  itemBuilder: (context, index) {

                    final doc = students[index];
                    final id = doc.id;
                    final data = doc.data() as Map<String, dynamic>;

                    final name = data['name'] ?? "No Name";
                    final rollNo = data['rollNo'] ?? "";

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
                        title: Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
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
                ),
              ),
            ],
          );
        },
      ),

      /// SAVE BUTTON
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green,
        icon: isSaving
            ? const SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        )
            : const Icon(Icons.save),
        label: Text(isSaving ? "Saving..." : "Save Attendance"),
        onPressed: isSaving ? null : _saveAttendance,
      ),
    );
  }

  /// SAVE FUNCTION (PRO STRUCTURE)
  Future<void> _saveAttendance() async {
    try {
      setState(() => isSaving = true);

      final batch = FirebaseFirestore.instance.batch();

      final attendanceRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('attendance')
          .doc(today)
          .collection('records');

      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('students')
          .where('class', isEqualTo: widget.className)
          .where('section', isEqualTo: widget.section)
          .get();

      for (var doc in studentsSnapshot.docs) {
        final studentId = doc.id;
        final data = doc.data();

        final recordRef = attendanceRef.doc(studentId);

        batch.set(recordRef, {
          "studentId": studentId,
          "name": data['name'] ?? "",
          "rollNo": data['rollNo'] ?? "",
          "class": widget.className,
          "section": widget.section,
          "status": attendance[studentId]! ? "Present" : "Absent",
          "date": today,
          "updatedAt": FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      setState(() => isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Attendance saved successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() => isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
}