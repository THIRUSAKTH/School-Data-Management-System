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
      appBar: AppBar(title: const Text("Select Class",style: TextStyle(fontWeight: FontWeight.bold),)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _field(classController, "Class (eg: 10)"),
            const SizedBox(height: 12),
            _field(sectionController, "Section (eg: A)"),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                child: const Text("Load Students"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MarkAttendancePage(
                        schoolId: widget.schoolId,
                        className: classController.text.trim(),
                        section: sectionController.text.trim(),
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
