import 'package:flutter/material.dart';

class FeeStatusPage extends StatelessWidget {
  const FeeStatusPage({super.key});

  // Mock fee data (later from Firebase)
  List<Map<String, dynamic>> get feeList => [
    {
      "title": "Tuition Fee",
      "amount": 25000,
      "dueDate": "10 Jan 2026",
      "status": "paid", // paid | pending | overdue
    },
    {
      "title": "Exam Fee",
      "amount": 2000,
      "dueDate": "18 Jan 2026",
      "status": "pending",
    },
    {
      "title": "Bus Fee",
      "amount": 8000,
      "dueDate": "05 Jan 2026",
      "status": "overdue",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final totalAmount =
    feeList.fold<int>(0, (sum, f) => sum + f["amount"] as int);

    final pendingAmount = feeList
        .where((f) => f["status"] != "paid")
        .fold<int>(0, (sum, f) => sum + f["amount"] as int);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text("Fee Status"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// SUMMARY CARD
            _summaryCard(totalAmount, pendingAmount),

            const SizedBox(height: 24),

            const Text(
              "Fee Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            /// FEE LIST
            ...feeList.map((fee) => _feeTile(context, fee)).toList(),
          ],
        ),
      ),
    );
  }

  /* =========================================================
     SUMMARY CARD
     ========================================================= */

  Widget _summaryCard(int total, int pending) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.deepPurple,
            child: Icon(Icons.currency_rupee, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Total Fees: ₹$total",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  pending == 0
                      ? "No Pending Fees 🎉"
                      : "Pending Amount: ₹$pending",
                  style: TextStyle(
                    color: pending == 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /* =========================================================
     FEE TILE
     ========================================================= */

  Widget _feeTile(BuildContext context, Map<String, dynamic> fee) {
    final status = fee["status"];

    Color statusColor;
    String statusText;

    switch (status) {
      case "paid":
        statusColor = Colors.green;
        statusText = "PAID";
        break;
      case "overdue":
        statusColor = Colors.red;
        statusText = "OVERDUE";
        break;
      default:
        statusColor = Colors.orange;
        statusText = "PENDING";
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TITLE + STATUS
            Row(
              children: [
                Text(
                  fee["title"],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            /// DETAILS
            Text("Amount: ₹${fee["amount"]}"),
            Text("Due Date: ${fee["dueDate"]}"),

            const SizedBox(height: 12),

            /// PAY BUTTON
            if (status != "paid")
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: statusColor,
                      foregroundColor: Colors.white
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Payment gateway integration coming soon"),
                      ),
                    );
                  },
                  child: const Text("Pay Now"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}