import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeworkPostPage extends StatefulWidget {
  const HomeworkPostPage({super.key});

  @override
  State<HomeworkPostPage> createState() => _HomeworkPostPageState();
}

class _HomeworkPostPageState extends State<HomeworkPostPage> {
  final TextEditingController _homeworkController = TextEditingController();

  String selectedClass = "Grade 10 - A";
  String selectedSubject = "Mathematics";
  DateTime? dueDate;

  bool isLoading = false;

  final List<String> classes = [
    "Grade 10 - A",
    "Grade 10 - B",
    "Grade 9 - A",
  ];

  final List<String> subjects = [
    "Mathematics",
    "Physics",
    "Chemistry",
    "English",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Post Homework"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label("Homework Details"),
            _homeworkField(),

            const SizedBox(height: 20),

            _label("Class"),
            _dropdown(classes, selectedClass, (val) {
              setState(() => selectedClass = val!);
            }),

            const SizedBox(height: 20),

            _label("Subject"),
            _dropdown(subjects, selectedSubject, (val) {
              setState(() => selectedSubject = val!);
            }),

            const SizedBox(height: 20),

            _label("Due Date"),
            _datePicker(),

            const SizedBox(height: 30),

            _submitButton(),
          ],
        ),
      ),
    );
  }

  /* =========================================================
     WIDGETS
     ========================================================= */

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _homeworkField() {
    return TextField(
      controller: _homeworkController,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: "Enter homework details",
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _dropdown(
      List<String> items,
      String value,
      ValueChanged<String?> onChanged,
      ) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map(
            (e) => DropdownMenuItem(
          value: e,
          child: Text(e),
        ),
      )
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _datePicker() {
    return InkWell(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18),
            const SizedBox(width: 12),
            Text(
              dueDate == null
                  ? "Select due date"
                  : DateFormat("dd MMM yyyy").format(dueDate!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : _publishHomework,
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("Publish Homework"),
      ),
    );
  }

  /* =========================================================
     LOGIC
     ========================================================= */

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => dueDate = picked);
    }
  }

  Future<void> _publishHomework() async {
    if (_homeworkController.text.trim().isEmpty || dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    final homeworkPayload = {
      "class": selectedClass,
      "subject": selectedSubject,
      "description": _homeworkController.text.trim(),
      "dueDate": DateFormat("yyyy-MM-dd").format(dueDate!),
      "createdAt": DateTime.now().toIso8601String(),
      "teacherId": "teacher_001",
    };

    // 🔥 Firebase upload here
    debugPrint(homeworkPayload.toString());

    await Future.delayed(const Duration(seconds: 1));

    setState(() => isLoading = false);

    _homeworkController.clear();
    dueDate = null;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Homework published successfully")),
    );
  }
}