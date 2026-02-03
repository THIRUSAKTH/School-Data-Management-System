import 'package:flutter/material.dart';

class TeacherTimetablePage extends StatelessWidget {
  const TeacherTimetablePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text("Weekly Timetable"),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _DaySection(
            day: "Monday",
            sessions: [
              _Session("08:00 - 09:00", "Mathematics", "Grade 10-A"),
              _Session("09:00 - 10:00", "Mathematics", "Grade 10-B"),
              _Session("11:00 - 12:00", "Algebra", "Grade 9-A"),
            ],
          ),
          _DaySection(
            day: "Tuesday",
            sessions: [
              _Session("08:00 - 09:00", "Physics", "Grade 10-A"),
              _Session("10:00 - 11:00", "Chemistry", "Grade 9-B"),
            ],
          ),
          _DaySection(
            day: "Wednesday",
            sessions: [
              _Session("09:00 - 10:00", "Mathematics", "Grade 10-C"),
              _Session("11:00 - 12:00", "Algebra", "Grade 9-A"),
            ],
          ),
        ],
      ),
    );
  }
}

/* =========================================================
   DAY SECTION
   ========================================================= */

class _DaySection extends StatelessWidget {
  final String day;
  final List<_Session> sessions;

  const _DaySection({
    required this.day,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          day,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 10),

        ...sessions.map((s) => _SessionCard(session: s)).toList(),

        const SizedBox(height: 20),
      ],
    );
  }
}

/* =========================================================
   SESSION MODEL
   ========================================================= */

class _Session {
  final String time;
  final String subject;
  final String className;

  const _Session(this.time, this.subject, this.className);
}

/* =========================================================
   SESSION CARD
   ========================================================= */

class _SessionCard extends StatelessWidget {
  final _Session session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            Text(
              session.time,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                session.subject,
                style: const TextStyle(fontSize: 15),
              ),
            ),
            Text(
              session.className,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}