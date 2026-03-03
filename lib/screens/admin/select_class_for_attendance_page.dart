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
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text("Attendance Reports"),
        elevation: 0,
      ),
      body: Column(
        children: [

          /// 🔍 Search Box (Card Style)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(12),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: "Search class (10 A)",
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (value) =>
                    setState(() => searchText = value.toLowerCase()),
              ),
            ),
          ),

          /// 📅 Month + Year Selector (Styled)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  Row(
                    children: [
                      const Icon(Icons.calendar_month,
                          color: Colors.blueGrey),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: selectedMonth,
                        underline: const SizedBox(),
                        items: List.generate(12, (index) {
                          return DropdownMenuItem(
                            value: index + 1,
                            child: Text(months[index]),
                          );
                        }),
                        onChanged: (value) =>
                            setState(() => selectedMonth = value!),
                      ),
                    ],
                  ),

                  DropdownButton<int>(
                    value: selectedYear,
                    underline: const SizedBox(),
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
            ),
          ),

          const SizedBox(height: 16),

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
                  return const Center(
                    child: Text(
                      "No matching classes",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        elevation: 2,
                        borderRadius: BorderRadius.circular(14),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          title: Text(
                            "Class ${doc['class']} - ${doc['section']}",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 18,
                            color: Colors.grey,
                          ),
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
                        ),
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