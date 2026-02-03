import 'package:flutter/material.dart';

class StudentManagementPage extends StatefulWidget {
  const StudentManagementPage({super.key});

  @override
  State<StudentManagementPage> createState() => _StudentManagementPageState();
}

class _StudentManagementPageState extends State<StudentManagementPage> {
  String selectedClass = "All";
  String searchText = "";

  final List<String> classes = ["All", "8-A", "8-B", "9-A", "10-A"];

  final List<Map<String, String>> students = List.generate(
    20,
        (i) => {
      "name": "Student ${i + 1}",
      "class": i % 2 == 0 ? "8-A" : "9-A",
      "roll": "${i + 1}",
    },
  );

  @override
  Widget build(BuildContext context) {
    final filteredStudents = students.where((s) {
      final matchClass =
          selectedClass == "All" || s["class"] == selectedClass;
      final matchSearch =
      s["name"]!.toLowerCase().contains(searchText.toLowerCase());
      return matchClass && matchSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text("Student Management"),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddStudentDialog();
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _topFilters(),
          _summaryCard(filteredStudents.length),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredStudents.length,
              itemBuilder: (_, i) {
                final student = filteredStudents[i];
                return _studentCard(student);
              },
            ),
          ),
        ],
      ),
    );
  }

  /* =========================================================
     FILTERS
     ========================================================= */

  Widget _topFilters() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search student",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => searchText = v),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: selectedClass,
            items: classes
                .map(
                  (c) => DropdownMenuItem(
                value: c,
                child: Text(c),
              ),
            )
                .toList(),
            onChanged: (v) => setState(() => selectedClass = v!),
          ),
        ],
      ),
    );
  }

  /* =========================================================
     SUMMARY CARD
     ========================================================= */

  Widget _summaryCard(int count) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.people, color: Colors.white, size: 30),
          const SizedBox(width: 12),
          Text(
            "Total Students: $count",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /* =========================================================
     STUDENT CARD
     ========================================================= */

  Widget _studentCard(Map<String, String> student) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.deepPurple,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(student["name"]!),
        subtitle: Text("Class ${student["class"]} | Roll ${student["roll"]}"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () {
          _openStudentDetails(student);
        },
      ),
    );
  }

  /* =========================================================
     ACTIONS
     ========================================================= */

  void _openStudentDetails(Map<String, String> student) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              student["name"]!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text("Class: ${student["class"]}"),
            Text("Roll No: ${student["roll"]}"),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              child: const Text("View Attendance"),
            ),
            ElevatedButton(
              onPressed: () {},
              child: const Text("View Results"),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddStudentDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Student"),
        content: const Text("This will open add student form"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () {},
            child: const Text("ADD"),
          ),
        ],
      ),
    );
  }
}