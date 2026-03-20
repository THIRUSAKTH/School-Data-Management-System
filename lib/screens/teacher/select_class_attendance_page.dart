import 'package:flutter/material.dart';
import 'mark_attendance_page.dart';

class SelectClassAttendancePage extends StatefulWidget {
  final String schoolId;

  const SelectClassAttendancePage({
    super.key,
    required this.schoolId,
  });

  @override
  State<SelectClassAttendancePage> createState() =>
      _SelectClassAttendancePageState();
}

class _SelectClassAttendancePageState extends State<SelectClassAttendancePage> {
  final classController = TextEditingController();
  final sectionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Select Class",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// CLASS FIELD
            _field(classController, "Class (eg: 6)"),

            const SizedBox(height: 12),

            /// SECTION FIELD
            _field(sectionController, "Section (eg: A)"),

            const SizedBox(height: 20),

            /// BUTTON
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                child: const Text("Load Students"),
                onPressed: () {

                  String rawClass = classController.text.trim();
                  String section = sectionController.text.trim().toUpperCase();

                  /// ✅ VALIDATION
                  if (rawClass.isEmpty || section.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Enter class & section")),
                    );
                    return;
                  }

                  /// ✅ AUTO FORMAT CLASS
                  String className = rawClass.startsWith("Class")
                      ? rawClass
                      : "Class $rawClass";

                  /// DEBUG PRINT
                  print("Class: $className");
                  print("Section: $section");

                  /// NAVIGATE
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MarkAttendancePage(
                        schoolId: widget.schoolId,
                        className: className,
                        section: section,
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
  Widget _field(TextEditingController c, String hint) {
    return TextField(
      controller: c,
      decoration: InputDecoration(
        labelText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }
}