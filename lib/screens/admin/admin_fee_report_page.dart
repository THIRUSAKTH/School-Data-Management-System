import 'package:flutter/material.dart';

class AdminFeeReportPage extends StatelessWidget {
  const AdminFeeReportPage({super.key});

  // Mock summary data (later from Firebase)
  Map<String, dynamic> get summary => {
    "total": 850000,
    "collected": 620000,
    "pending": 230000,
  };

  // Mock class-wise fee data
  final List<Map<String, dynamic>> classFees = const [
    {"class": "6-A", "collected": 45000, "total": 60000},
    {"class": "6-B", "collected": 52000, "total": 65000},
    {"class": "7-A", "collected": 61000, "total": 70000},
    {"class": "7-B", "collected": 58000, "total": 72000},
    {"class": "8-A", "collected": 67000, "total": 80000},
  ];

  @override
  Widget build(BuildContext context) {
    final percent =
    ((summary["collected"] / summary["total"]) * 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text("Fee Collection Report"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// SUMMARY CARDS
            _summarySection(percent),

            const SizedBox(height: 24),

            const Text(
              "Class-wise Fee Status",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ...classFees.map(_classFeeCard).toList(),
          ],
        ),
      ),
    );
  }

  /* =========================================================
     SUMMARY SECTION
     ========================================================= */

  Widget _summarySection(int percent) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

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
          child: isWide
              ? Row(children: _summaryItems(percent))
              : Column(children: _summaryItems(percent)),
        );
      },
    );
  }

  List<Widget> _summaryItems(int percent) => [
    _summaryTile(
      "Total Fees",
      "₹${summary["total"]}",
      Icons.account_balance_wallet,
      Colors.blue,
    ),
    _summaryTile(
      "Collected",
      "₹${summary["collected"]}",
      Icons.check_circle,
      Colors.green,
    ),
    _summaryTile(
      "Pending",
      "₹${summary["pending"]}",
      Icons.warning,
      Colors.red,
    ),
    const SizedBox(height: 12),
    Column(
      children: [
        Text(
          "$percent%",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: percent >= 75 ? Colors.green : Colors.red,
          ),
        ),
        const Text("Collected"),
      ],
    ),
  ];

  Widget _summaryTile(
      String title, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 20, bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(title, style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }

  /* =========================================================
     CLASS-WISE CARD
     ========================================================= */

  Widget _classFeeCard(Map<String, dynamic> data) {
    final percent =
    ((data["collected"] / data["total"]) * 100).round();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.class_),
        title: Text("Class ${data["class"]}"),
        subtitle: Text(
          "₹${data["collected"]} / ₹${data["total"]}",
        ),
        trailing: Text(
          "$percent%",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: percent >= 75 ? Colors.green : Colors.red,
          ),
        ),
        onTap: () {
          // 🔜 Next page: student-wise fee details
          debugPrint("Open fee details for ${data["class"]}");
        },
      ),
    );
  }
}