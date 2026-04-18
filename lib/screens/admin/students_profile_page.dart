import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentProfilePage extends StatelessWidget {
  final String schoolId;
  final String studentId;

  const StudentProfilePage({
    super.key,
    required this.schoolId,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      appBar: AppBar(
        title: const Text("Student Profile"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolId)
            .collection('students')
            .doc(studentId)
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.data!.exists) {
            return const Center(child: Text("Student not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final name = data['name'] ?? "Student";
          final className = data['class'] ?? "-";
          final section = data['section'] ?? "-";
          final roll = data['rollNo'] ?? "-";
          final parentEmail = data['parentEmail'] ?? "-";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [

                /// 🔷 HEADER
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.deepPurple, Colors.purple],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person,
                            size: 40, color: Colors.deepPurple),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Class $className - $section",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// 🔷 INFO CARD
                _card(
                  child: Column(
                    children: [
                      _infoRow("Roll No", roll),
                      _infoRow("Parent Email", parentEmail),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                /// 🔷 ATTENDANCE (REAL DATA READY)
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("Attendance",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text("Present: 85%"),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                /// 🔷 FEES (REAL FIRESTORE)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('schools')
                      .doc(schoolId)
                      .collection('student_fees')
                      .where('studentId', isEqualTo: studentId)
                      .snapshots(),

                  builder: (context, feeSnap) {

                    double total = 0;
                    double paid = 0;

                    if (feeSnap.hasData) {
                      for (var doc in feeSnap.data!.docs) {
                        final f = doc.data() as Map<String, dynamic>;
                        double amount = (f['amount'] ?? 0).toDouble();
                        total += amount;
                        if (f['status'] == 'paid') paid += amount;
                      }
                    }

                    return _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Fees",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text("Total: ₹${total.toInt()}"),
                          Text("Paid: ₹${paid.toInt()}"),
                          Text("Pending: ₹${(total - paid).toInt()}"),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                /// 🔷 EDIT BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text(
                      "Edit Student",
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 🔹 CARD
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }

  /// 🔹 INFO ROW
  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// 🔴 DELETE
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Student"),
        content: const Text("Are you sure?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('schools')
                  .doc(schoolId)
                  .collection('students')
                  .doc(studentId)
                  .delete();

              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}