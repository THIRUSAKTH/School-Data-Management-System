import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminFeeUploadPage extends StatefulWidget {
  final String schoolId;

  const AdminFeeUploadPage({super.key, required this.schoolId});

  @override
  State<AdminFeeUploadPage> createState() =>
      _AdminFeeUploadPageState();
}

class _AdminFeeUploadPageState
    extends State<AdminFeeUploadPage> {

  final _amountController = TextEditingController();

  String selectedClass = "Class 6";
  String selectedSection = "A";
  String selectedFeeType = "Tuition Fee";
  DateTime? dueDate;

  final classes = ["Class 6", "Class 7", "Class 8", "Class 9", "Class 10"];
  final sections = ["A", "B", "C"];
  final feeTypes = [
    "Tuition Fee",
    "Exam Fee",
    "Transport Fee",
    "Library Fee",
    "Other"
  ];

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text("Upload Fees"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _sectionTitle("Class & Section"),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: _dropdown("Class", selectedClass, classes,
                          (v) => setState(() => selectedClass = v)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _dropdown("Section", selectedSection, sections,
                          (v) => setState(() => selectedSection = v)),
                ),
              ],
            ),

            const SizedBox(height: 20),

            _sectionTitle("Fee Details"),
            const SizedBox(height: 8),

            _dropdown(
              "Fee Type",
              selectedFeeType,
              feeTypes,
                  (v) => setState(() => selectedFeeType = v),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Amount (₹)",
                filled: true,
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            _datePicker(),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: isLoading
                    ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.upload),
                label: Text(isLoading ? "Publishing..." : "Publish Fee"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                onPressed: isLoading ? null : _publishFee,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= UI =================

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _dropdown(
      String label,
      String value,
      List<String> items,
      ValueChanged<String> onChanged,
      ) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (v) => onChanged(v!),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _datePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          initialDate: DateTime.now(),
        );

        if (picked != null) {
          setState(() => dueDate = picked);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: "Due Date",
          filled: true,
          border: OutlineInputBorder(),
        ),
        child: Text(
          dueDate == null
              ? "Select due date"
              : "${dueDate!.day}-${dueDate!.month}-${dueDate!.year}",
        ),
      ),
    );
  }

  /// ================= MAIN LOGIC =================

  Future<void> _publishFee() async {
    if (_amountController.text.isEmpty || dueDate == null) {
      _msg("Fill all fields");
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null) {
      _msg("Enter valid amount");
      return;
    }

    setState(() => isLoading = true);

    try {
      /// 🔥 1. CREATE FEE RECORD
      final feeDoc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('fees')
          .add({
        "class": selectedClass,
        "section": selectedSection,
        "type": selectedFeeType,

        "total": amount,
        "collected": 0,

        "dueDate": Timestamp.fromDate(dueDate!),
        "createdAt": Timestamp.now(),
      });

      /// 🔥 2. FETCH STUDENTS
      final students = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('students')
          .where('class', isEqualTo: selectedClass)
          .where('section', isEqualTo: selectedSection)
          .get();

      /// 🔥 3. CREATE STUDENT FEE RECORDS
      for (var student in students.docs) {
        await FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolId)
            .collection('student_fees')
            .add({
          "studentId": student.id,
          "feeId": feeDoc.id,
          "amount": amount,
          "status": "pending",
          "dueDate": Timestamp.fromDate(dueDate!),
          "createdAt": Timestamp.now(),
        });
      }

      _msg("Fee published successfully");

      _amountController.clear();
      setState(() => dueDate = null);

    } catch (e) {
      _msg("Error: $e");
    }

    setState(() => isLoading = false);
  }

  void _msg(String t) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(t)));
  }
}