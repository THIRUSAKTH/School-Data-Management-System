import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminFeeReportPage extends StatelessWidget {
  final String schoolId;

  const AdminFeeReportPage({super.key, required this.schoolId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text("Fee Report"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolId)
            .collection('fees')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No fee data available"));
          }

          final docs = snapshot.data!.docs;

          double total = 0;
          double collected = 0;

          List<Map<String, dynamic>> classData = [];

          for (var doc in docs) {
            final raw = doc.data() as Map<String, dynamic>;

            /// ✅ SUPPORT OLD + NEW DATA
            double totalValue =
            (raw['total'] ?? raw['amount'] ?? 0).toDouble();

            double collectedValue =
            (raw['collected'] ?? 0).toDouble();

            total += totalValue;
            collected += collectedValue;

            classData.add({
              "class": raw['class'] ?? 'Unknown',
              "total": totalValue,
              "collected": collectedValue,
            });
          }

          double percent =
          total == 0 ? 0 : (collected / total) * 100;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _summary(total, collected, percent),
                const SizedBox(height: 20),
                _title("Class-wise Report"),
                const SizedBox(height: 10),
                ...classData.map((e) => _classCard(e)).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  /// ================= SUMMARY =================

  Widget _summary(double total, double collected, double percent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            "₹${collected.toInt()} / ₹${total.toInt()}",
            style: const TextStyle(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          LinearProgressIndicator(
            value: percent.isNaN ? 0 : percent / 100,
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
            backgroundColor: Colors.white24,
          ),

          const SizedBox(height: 10),

          Text(
            "${percent.toStringAsFixed(1)}% Collected",
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// ================= TITLE =================

  Widget _title(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// ================= CLASS CARD =================

  Widget _classCard(Map<String, dynamic> data) {
    double collected = (data['collected'] ?? 0).toDouble();
    double total = (data['total'] ?? 1).toDouble();

    double percent = (collected / total) * 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.shade50,
            child: const Icon(Icons.school, color: Colors.blue),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Class ${data['class'] ?? 'Unknown'}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "₹${collected.toInt()} / ₹${total.toInt()}",
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                "${percent.toStringAsFixed(0)}%",
                style: TextStyle(
                  color: percent >= 75 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 60,
                child: LinearProgressIndicator(
                  value: percent.isNaN ? 0 : percent / 100,
                  backgroundColor: Colors.grey.shade300,
                  color: percent >= 75 ? Colors.green : Colors.red,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}