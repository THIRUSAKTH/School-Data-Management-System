import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceReportPage extends StatefulWidget {
  final String schoolId;

  const AttendanceReportPage({
    super.key,
    required this.schoolId,
  });

  @override
  State<AttendanceReportPage> createState() => _AttendanceReportPageState();
}

class _AttendanceReportPageState extends State<AttendanceReportPage> {
  String selectedDate =
  DateTime.now().toIso8601String().split("T")[0];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(iconTheme: IconThemeData(color: Colors.white

      ),
        backgroundColor: Colors.indigo,
        title: const Text("Attendance Report",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
      ),

      body: Column(
        children: [
          /// DATE PICKER
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text("Date: ",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(selectedDate),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _pickDate,
                )
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('schools')
                  .doc(widget.schoolId)
                  .collection('attendance')
                  .doc(selectedDate)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                if (!snapshot.data!.exists) {
                  return const Center(
                      child: Text("No attendance for this date"));
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;

                data.remove('updatedAt');

                return ListView(
                  children: data.entries.map((entry) {
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text("Class ${entry.key}"),
                        subtitle:
                        Text("Students marked: ${entry.value.length}"),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked.toIso8601String().split("T")[0];
      });
    }
  }
}
