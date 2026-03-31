import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ParentDashboard extends StatefulWidget {
  final String schoolId;

  const ParentDashboard({super.key, required this.schoolId});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {

  final String parentUid = FirebaseAuth.instance.currentUser!.uid;

  String? selectedStudentId;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Reports"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolId)
            .collection('students')
            .where('parentUid', isEqualTo: parentUid)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No child linked to this parent"));
          }

          final students = snapshot.data!.docs;

          selectedStudentId ??= students.first.id;

          final student = students.firstWhere(
                (doc) => doc.id == selectedStudentId,
          );

          String name = student['name'] ?? "Student";
          String className = student['class'] ?? "";
          String section = student['section'] ?? "";
          String rollNo = student['rollNo'] ?? "";

          return SingleChildScrollView(
            child: Column(
              children: [

                /// HEADER
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange, Colors.deepOrange],
                    ),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                  ),
                  child: Column(
                    children: [

                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person,
                            size: 45, color: Colors.orange),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "Class $className - $section | Roll No: $rollNo",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// STUDENT SELECT
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonFormField<String>(
                    value: selectedStudentId,
                    decoration: const InputDecoration(
                      labelText: "Select Child",
                      border: OutlineInputBorder(),
                    ),
                    items: students.map((doc) {
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(
                          "${doc['name']} (Class ${doc['class']}-${doc['section']})",
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedStudentId = value;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 20),

                /// ================= FEES + STATS =================
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('schools')
                      .doc(widget.schoolId)
                      .collection('student_fees')
                      .where('studentId', isEqualTo: selectedStudentId)
                      .snapshots(),
                  builder: (context, feeSnapshot) {

                    if (!feeSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    double totalDue = 0;
                    double totalPaid = 0;

                    for (var doc in feeSnapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;

                      double amount = (data['amount'] ?? 0).toDouble();
                      String status = data['status'] ?? "pending";

                      if (status == "paid") {
                        totalPaid += amount;
                      } else {
                        totalDue += amount;
                      }
                    }

                    return Column(
                      children: [

                        /// STATS
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const _StatCard(
                                title: "Attendance",
                                value: "92%",
                                color: Colors.green,
                              ),
                              _StatCard(
                                title: "Fees Due",
                                value: "₹${totalDue.toInt()}",
                                color: Colors.red,
                              ),
                              _StatCard(
                                title: "Paid",
                                value: "₹${totalPaid.toInt()}",
                                color: Colors.blue,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 25),

                        /// TITLE
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Fee Details",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        /// LIST
                        if (feeSnapshot.data!.docs.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text("No fees assigned"),
                          )
                        else
                          Column(
                            children: feeSnapshot.data!.docs.map((doc) {
                              final data =
                              doc.data() as Map<String, dynamic>;

                              double amount =
                              (data['amount'] ?? 0).toDouble();
                              String status =
                                  data['status'] ?? "pending";

                              Timestamp? dueTs = data['dueDate'];
                              DateTime? dueDate = dueTs?.toDate();

                              bool isOverdue = dueDate != null &&
                                  dueDate.isBefore(DateTime.now()) &&
                                  status != "paid";

                              return Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                  BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 6,
                                    )
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "₹${amount.toInt()}",
                                          style: const TextStyle(
                                              fontWeight:
                                              FontWeight.bold),
                                        ),
                                        if (dueDate != null)
                                          Text(
                                            "Due: ${dueDate.day}-${dueDate.month}-${dueDate.year}",
                                            style: TextStyle(
                                              color: isOverdue
                                                  ? Colors.red
                                                  : Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                    Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        color: status == "paid"
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// ================= STAT CARD =================

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}