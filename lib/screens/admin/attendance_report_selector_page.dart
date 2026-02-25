import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_monthly_attendance_page.dart';

class AttendanceReportSelectorPage extends StatefulWidget {
  final String schoolId;

  const AttendanceReportSelectorPage({super.key, required this.schoolId});

  @override
  State<AttendanceReportSelectorPage> createState() =>
      _AttendanceReportSelectorPageState();
}

class _AttendanceReportSelectorPageState
    extends State<AttendanceReportSelectorPage> {

  String searchText = "";
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  final months = const [
    "Jan","Feb","Mar","Apr","May","Jun",
    "Jul","Aug","Sep","Oct","Nov","Dec"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Attendance Reports")),
      body: Column(
        children: [

          /// 🔍 Search
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search class (10 A)",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => searchText = v.toLowerCase()),
            ),
          ),

          /// 📅 Month selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<int>(
                value: selectedMonth,
                items: List.generate(12, (i) {
                  return DropdownMenuItem(
                    value: i + 1,
                    child: Text(months[i]),
                  );
                }),
                onChanged: (v) => setState(() => selectedMonth = v!),
              ),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: selectedYear,
                items: List.generate(6, (i) {
                  final year = 2024 + i;
                  return DropdownMenuItem(
                    value: year,
                    child: Text(year.toString()),
                  );
                }),
                onChanged: (v) => setState(() => selectedYear = v!),
              ),
            ],
          ),

          /// 📚 Classes
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('schools')
                  .doc(widget.schoolId)
                  .collection('classes')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final classes = snapshot.data!.docs.where((doc) {
                  final name =
                  "${doc['class']} ${doc['section']}".toLowerCase();
                  return name.contains(searchText);
                }).toList();

                return ListView(
                  children: classes.map((doc) {
                    return ListTile(
                      title: Text(
                          "Class ${doc['class']} - ${doc['section']}"),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminMonthlyAttendancePage(
                              schoolId: widget.schoolId,
                              classId: doc.id,
                              month: selectedMonth,
                              year: selectedYear,
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}