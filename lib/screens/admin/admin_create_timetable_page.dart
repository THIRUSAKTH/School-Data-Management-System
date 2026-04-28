import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';

class AdminCreateTimetablePage extends StatefulWidget {
  final String schoolId;

  const AdminCreateTimetablePage({
    super.key,
    required this.schoolId,
  });

  @override
  State<AdminCreateTimetablePage> createState() => _AdminCreateTimetablePageState();
}

class _AdminCreateTimetablePageState extends State<AdminCreateTimetablePage> {
  String selectedDay = "Monday";
  String selectedTeacherId = "";
  String selectedTeacherName = "";
  String selectedClass = "";
  String selectedSection = "";
  String selectedSubject = "";
  int selectedPeriod = 1;
  bool _isLoading = false;

  final List<String> subjects = [
    "Mathematics", "Physics", "Chemistry", "Biology",
    "English", "Tamil", "Social Science", "Computer Science",
    "Physical Education", "Art", "Music", "Hindi"
  ];

  final List<String> classes = ["LKG", "UKG", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"];
  final List<String> sections = ["A", "B", "C", "D"];
  final List<String> days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
  final List<int> periods = List.generate(8, (i) => i + 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          "Create Timetable",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.cyan,
        foregroundColor: Colors.white,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: "Refresh",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFormCard(),
            const SizedBox(height: 20),
            _buildExistingEntriesCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Add Timetable Entry",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Day Selector
          _buildDropdown(
            label: "Select Day",
            value: selectedDay,
            items: days,
            onChanged: (v) => setState(() => selectedDay = v!),
            icon: Icons.calendar_today,
          ),
          const SizedBox(height: 16),

          // Period Selector
          _buildDropdown(
            label: "Select Period",
            value: selectedPeriod,
            items: periods,
            itemBuilder: (value) => "Period $value",
            onChanged: (v) => setState(() => selectedPeriod = v!),
            icon: Icons.timer,
          ),
          const SizedBox(height: 16),

          // Class Selector
          _buildDropdown(
            label: "Select Class",
            value: selectedClass.isEmpty ? null : selectedClass,
            items: classes,
            itemBuilder: (value) => "Class $value",
            onChanged: (v) => setState(() => selectedClass = v!),
            icon: Icons.class_,
          ),
          const SizedBox(height: 16),

          // Section Selector
          _buildDropdown(
            label: "Select Section",
            value: selectedSection.isEmpty ? null : selectedSection,
            items: sections,
            itemBuilder: (value) => "Section $value",
            onChanged: (v) => setState(() => selectedSection = v!),
            icon: Icons.group,
          ),
          const SizedBox(height: 16),

          // Subject Selector
          _buildDropdown(
            label: "Select Subject",
            value: selectedSubject.isEmpty ? null : selectedSubject,
            items: subjects,
            onChanged: (v) => setState(() => selectedSubject = v!),
            icon: Icons.book,
          ),
          const SizedBox(height: 16),

          // Teacher Selector
          _buildTeacherDropdown(),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _saveTimetable,
              icon: const Icon(Icons.save),
              label: const Text("Save Timetable Entry"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required Function(T?) onChanged,
    required IconData icon,
    String Function(T)? itemBuilder,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: Icon(icon, color: Colors.cyan),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items.map((item) {
        final displayText = itemBuilder != null ? itemBuilder(item) : item.toString();
        return DropdownMenuItem(value: item, child: Text(displayText));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTeacherDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('teachers')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return DropdownButtonFormField(
            decoration: InputDecoration(labelText: "Loading teachers..."),
            items: [],
            onChanged: null,
          );
        }

        final teachers = snapshot.data!.docs;

        return DropdownButtonFormField<String>(
          value: selectedTeacherId.isEmpty ? null : selectedTeacherId,
          decoration: const InputDecoration(
            labelText: "Select Teacher",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person, color: Colors.cyan),
            filled: true,
            fillColor: Colors.white,
          ),
          items: teachers.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return DropdownMenuItem(
              value: doc.id,
              child: Text(data['name'] ?? 'Unknown Teacher'),
            );
          }).toList(),
          onChanged: (value) {
            final doc = teachers.firstWhere((e) => e.id == value);
            final data = doc.data() as Map<String, dynamic>;
            setState(() {
              selectedTeacherId = value!;
              selectedTeacherName = data['name'] ?? '';
            });
          },
        );
      },
    );
  }

  Widget _buildExistingEntriesCard() {
    if (selectedClass.isEmpty || selectedSection.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: const Center(
          child: Text(
            "Select a class and section to view existing entries",
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Existing Timetable Entries",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('schools')
                .doc(widget.schoolId)
                .collection('timetable')
                .where('class', isEqualTo: selectedClass)
                .where('section', isEqualTo: selectedSection)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final entries = snapshot.data!.docs;

              if (entries.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text("No entries found for this class"),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entries.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final data = entries[index].data() as Map<String, dynamic>;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getDayColor(data['day']),
                      child: Text(
                        data['period']?.toString() ?? '',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text("${data['day']} - Period ${data['period']}"),
                    subtitle: Text("${data['subject']} | ${data['teacherName']}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteEntry(entries[index].id),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveTimetable() async {
    // Validation
    if (selectedDay.isEmpty) {
      _showError("Please select a day");
      return;
    }
    if (selectedClass.isEmpty) {
      _showError("Please select a class");
      return;
    }
    if (selectedSection.isEmpty) {
      _showError("Please select a section");
      return;
    }
    if (selectedSubject.isEmpty) {
      _showError("Please select a subject");
      return;
    }
    if (selectedTeacherId.isEmpty) {
      _showError("Please select a teacher");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if entry already exists for this day/period/class/section
      final existingQuery = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('timetable')
          .where('day', isEqualTo: selectedDay)
          .where('period', isEqualTo: selectedPeriod)
          .where('class', isEqualTo: selectedClass)
          .where('section', isEqualTo: selectedSection)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        _showError("An entry already exists for $selectedDay Period $selectedPeriod");
        setState(() => _isLoading = false);
        return;
      }

      final docRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('timetable')
          .doc();

      await docRef.set({
        "day": selectedDay,
        "period": selectedPeriod,
        "class": selectedClass,
        "section": selectedSection,
        "subject": selectedSubject,
        "teacherId": selectedTeacherId,
        "teacherName": selectedTeacherName,
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      });

      // Also save teacher-specific entry
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('teacher_timetable')
          .doc(selectedTeacherId)
          .collection('entries')
          .doc("${selectedDay}_${selectedPeriod}_${selectedClass}_${selectedSection}")
          .set({
        "day": selectedDay,
        "period": selectedPeriod,
        "class": selectedClass,
        "section": selectedSection,
        "subject": selectedSubject,
        "createdAt": FieldValue.serverTimestamp(),
      });

      _showSuccess("Timetable entry saved successfully");

      // Reset form
      setState(() {
        selectedSubject = "";
        selectedTeacherId = "";
        selectedTeacherName = "";
      });
    } catch (e) {
      _showError("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteEntry(String docId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Entry"),
        content: const Text("Are you sure you want to delete this timetable entry?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection('schools')
                  .doc(widget.schoolId)
                  .collection('timetable')
                  .doc(docId)
                  .delete();
              _showSuccess("Entry deleted");
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Color _getDayColor(String day) {
    switch (day) {
      case "Monday": return Colors.blue;
      case "Tuesday": return Colors.green;
      case "Wednesday": return Colors.orange;
      case "Thursday": return Colors.purple;
      case "Friday": return Colors.red;
      case "Saturday": return Colors.teal;
      default: return Colors.grey;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}