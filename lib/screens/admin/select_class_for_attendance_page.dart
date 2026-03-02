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

          /// 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search class (10 A)",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) =>
                  setState(() => searchText = value.toLowerCase()),
            ),
          ),

          /// 📅 Month + Year Picker
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              DropdownButton<int>(
                value: selectedMonth,
                items: List.generate(12, (index) {
                  return DropdownMenuItem(
                    value: index + 1,
                    child: Text(months[index]),
                  );
                }),
                onChanged: (value) =>
                    setState(() => selectedMonth = value!),
              ),

              const SizedBox(width: 20),

              DropdownButton<int>(
                value: selectedYear,
                items: List.generate(5, (index) {
                  int year = 2024 + index;
                  return DropdownMenuItem(
                    value: year,
                    child: Text(year.toString()),
                  );
                }),
                onChanged: (value) =>
                    setState(() => selectedYear = value!),
              ),
            ],
          ),

          const SizedBox(height: 10),

          /// 📚 Class List
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

                final filtered = snapshot.data!.docs.where((doc) {
                  final name =
                  "${doc['class']} ${doc['section']}".toLowerCase();
                  return name.contains(searchText);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text("No matching classes"));
                }

                return ListView(
                  children: filtered.map((doc) {
                    return ListTile(
                      title: Text(
                          "Class ${doc['class']} - ${doc['section']}"),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AdminMonthlyAttendancePage(
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