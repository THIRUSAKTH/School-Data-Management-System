import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_monthly_attendance_page.dart';

class SelectClassForAttendancePage extends StatefulWidget {
  final String schoolId;

  const SelectClassForAttendancePage({
    super.key,
    required this.schoolId,
  });

  @override
  State<SelectClassForAttendancePage> createState() =>
      _SelectClassForAttendancePageState();
}

class _SelectClassForAttendancePageState
    extends State<SelectClassForAttendancePage> {

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Class for Attendance"),
      ),
      body: Column(
        children: [
          /// 📅 Simple month display (we can upgrade later)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              "Month: $selectedMonth / $selectedYear",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('schools')
                  .doc(widget.schoolId)
                  .collection('classes')
                  .orderBy('class')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No classes created yet"));
                }
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final classId = doc.id;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(
                          "Class ${doc['class']} - ${doc['section']}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing:
                        const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AdminMonthlyAttendancePage(
                                    schoolId: widget.schoolId,
                                    classId: classId,
                                    month: selectedMonth,
                                    year: selectedYear,
                                  ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}