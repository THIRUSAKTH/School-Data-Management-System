import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAttendanceOverviewPage extends StatelessWidget {
  final String schoolId;

  const AdminAttendanceOverviewPage({
    super.key,
    required this.schoolId,
  });

  String get today =>
      DateTime.now().toIso8601String().split("T")[0];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      appBar: AppBar(
        title: const Text("Attendance Overview"),
        elevation: 0,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolId)
            .collection('attendance')
            .doc(today)
            .collection('records')
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = snapshot.data!.docs;

          if (records.isEmpty) {
            return const Center(child: Text("No attendance today"));
          }

          int total = records.length;
          int present = records
              .where((e) => e['status'] == "Present")
              .length;
          int absent = total - present;

          int percentage = ((present / total) * 100).round();

          /// CLASS-WISE GROUPING
          Map<String, Map<String, int>> classMap = {};

          for (var doc in records) {
            final data = doc.data() as Map<String, dynamic>;

            String key = "${data['class']}-${data['section']}";

            classMap.putIfAbsent(key, () => {
              "present": 0,
              "total": 0,
            });

            classMap[key]!["total"] =
                classMap[key]!["total"]! + 1;

            if (data['status'] == "Present") {
              classMap[key]!["present"] =
                  classMap[key]!["present"]! + 1;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// 🔥 MODERN SUMMARY CARD
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.blue, Colors.indigo],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [

                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceAround,
                        children: [
                          _topItem("Total", total, Icons.groups),
                          _topItem("Present", present, Icons.check),
                          _topItem("Absent", absent, Icons.close),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Text(
                        "$percentage%",
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      const Text(
                        "Today's Attendance",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  "Class-wise Attendance",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                /// 🔥 CLASS LIST
                ...classMap.entries.map((entry) {

                  final key = entry.key;
                  final present = entry.value["present"]!;
                  final total = entry.value["total"]!;
                  final percent =
                  ((present / total) * 100).round();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [

                        CircleAvatar(
                          backgroundColor:
                          Colors.blue.withOpacity(.1),
                          child: const Icon(Icons.class_),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text("Class $key",
                                  style: const TextStyle(
                                      fontWeight:
                                      FontWeight.bold)),
                              Text(
                                  "$present / $total Present",
                                  style: const TextStyle(
                                      color: Colors.grey)),
                            ],
                          ),
                        ),

                        Text(
                          "$percent%",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: percent >= 75
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _topItem(String title, int value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(height: 6),
        Text(
          value.toString(),
          style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
        Text(title, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}