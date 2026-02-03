import 'package:flutter/material.dart';

class TeacherManagementPage extends StatefulWidget {
  const TeacherManagementPage({super.key});

  @override
  State<TeacherManagementPage> createState() => _TeacherManagementPageState();
}

class _TeacherManagementPageState extends State<TeacherManagementPage> {
  String searchText = "";
  String selectedSubject = "All";

  final List<String> subjects = [
    "All",
    "Maths",
    "Science",
    "English",
    "Social",
  ];

  final List<Map<String, String>> teachers = List.generate(
    10,
        (i) => {
      "name": "Teacher ${i + 1}",
      "subject": i % 2 == 0 ? "Maths" : "Science",
      "phone": "98765432${i}",
      "classes": "8-A, 9-A",
    },
  );

  @override
  Widget build(BuildContext context) {
    final filteredTeachers = teachers.where((t) {
      final matchSearch =
      t["name"]!.toLowerCase().contains(searchText.toLowerCase());
      final matchSubject =
          selectedSubject == "All" || t["subject"] == selectedSubject;
      return matchSearch && matchSubject;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text("Teacher Management"),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTeacherDialog,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _filters(),
          _summaryCard(filteredTeachers.length),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredTeachers.length,
              itemBuilder: (_, i) {
                return _teacherCard(filteredTeachers[i]);
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

  Widget _filters() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search teacher",
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
            value: selectedSubject,
            items: subjects
                .map(
                  (s) => DropdownMenuItem(
                value: s,
                child: Text(s),
              ),
            )
                .toList(),
            onChanged: (v) => setState(() => selectedSubject = v!),
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
        color: Colors.green,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.school, color: Colors.white, size: 30),
          const SizedBox(width: 12),
          Text(
            "Total Teachers: $count",
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
     TEACHER CARD
     ========================================================= */

  Widget _teacherCard(Map<String, String> teacher) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(teacher["name"]!),
        subtitle: Text(
          "Subject: ${teacher["subject"]}\nClasses: ${teacher["classes"]}",
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () => _openTeacherDetails(teacher),
      ),
    );
  }

  /* =========================================================
     DETAILS & ACTIONS
     ========================================================= */

  void _openTeacherDetails(Map<String, String> teacher) {
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
              teacher["name"]!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text("Subject: ${teacher["subject"]}"),
            Text("Classes: ${teacher["classes"]}"),
            Text("Phone: ${teacher["phone"]}"),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              child: const Text("View Timetable"),
            ),
            ElevatedButton(
              onPressed: () {},
              child: const Text("View Attendance Records"),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTeacherDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Teacher"),
        content: const Text("Teacher add form will be here"),
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