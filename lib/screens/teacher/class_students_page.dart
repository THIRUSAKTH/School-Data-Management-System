import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:schoolprojectjan/app_config.dart';

class ClassStudentsPage extends StatefulWidget {
  final String schoolId;
  final String className;
  final String section;

  const ClassStudentsPage({
    super.key,
    required this.schoolId,
    required this.className,
    required this.section,
  });

  @override
  State<ClassStudentsPage> createState() => _ClassStudentsPageState();
}

class _ClassStudentsPageState extends State<ClassStudentsPage> {
  final Map<String, bool> attendance = {};
  final Map<String, String> remarks = {};
  final Map<String, TimeOfDay?> checkInTimes = {};
  final Map<String, TimeOfDay?> checkOutTimes = {};

  bool isSaving = false;
  bool _isEditing = false;
  DateTime? _selectedDate;
  List<Map<String, dynamic>> _students = [];

  // Late reasons options
  final List<String> lateReasons = [
    'Traffic',
    'Weather',
    'Medical',
    'Transport Issue',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadStudents();
    _loadExistingAttendance();
  }

  String get today => DateFormat('yyyy-MM-dd').format(_selectedDate ?? DateTime.now());

  Future<void> _loadStudents() async {
    try {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('students')
          .where('class', isEqualTo: widget.className)
          .where('section', isEqualTo: widget.section)
          .orderBy('rollNo')
          .get();

      final List<Map<String, dynamic>> loadedStudents = [];
      for (var doc in studentsSnapshot.docs) {
        final data = doc.data();
        loadedStudents.add({
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
          'rollNo': data['rollNo'] ?? '',
          'parentUid': data['parentUid'] ?? '',
        });

        // Initialize attendance (default Present)
        if (!attendance.containsKey(doc.id)) {
          attendance[doc.id] = true;
        }
      }

      setState(() {
        _students = loadedStudents;
      });
    } catch (e) {
      debugPrint('Error loading students: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading students: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadExistingAttendance() async {
    try {
      final attendanceDoc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('attendance')
          .doc(today)
          .collection('records')
          .get();

      if (attendanceDoc.docs.isNotEmpty) {
        setState(() {
          _isEditing = true;
          for (var doc in attendanceDoc.docs) {
            final data = doc.data();
            final status = data['status'];
            attendance[doc.id] = status == 'Present' || status == 'Late';
            if (status == 'Late') {
              remarks[doc.id] = data['remark'] ?? '';
            }
            if (data['checkInTime'] != null) {
              // Parse time string to TimeOfDay
              final timeParts = data['checkInTime'].split(':');
              if (timeParts.length == 2) {
                checkInTimes[doc.id] = TimeOfDay(
                  hour: int.parse(timeParts[0]),
                  minute: int.parse(timeParts[1].split(' ')[0]),
                );
              }
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading existing attendance: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: _buildAppBar(),
      body: _students.isEmpty
          ? _buildEmptyState()
          : Column(
        children: [
          _buildSummaryCard(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                final id = student['id'];
                final isPresent = attendance[id] ?? true;
                final hasRemark = remarks[id]?.isNotEmpty ?? false;

                return _buildStudentCard(
                  id: id,
                  name: student['name'],
                  rollNo: student['rollNo'],
                  isPresent: isPresent,
                  hasRemark: hasRemark,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _buildSaveButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Mark Attendance",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            "${widget.className} - ${widget.section}",
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: _selectDate,
          tooltip: "Select Date",
        ),
        if (_selectedDate != DateTime.now())
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              DateFormat('dd MMM').format(_selectedDate!),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'mark_all_present':
                setState(() {
                  attendance.updateAll((key, value) => true);
                  remarks.clear();
                });
                break;
              case 'mark_all_absent':
                setState(() {
                  attendance.updateAll((key, value) => false);
                  remarks.clear();
                });
                break;
              case 'reset':
                setState(() {
                  attendance.clear();
                  remarks.clear();
                  checkInTimes.clear();
                  checkOutTimes.clear();
                  _loadExistingAttendance();
                });
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'mark_all_present',
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 12),
                  Text('Mark All Present'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'mark_all_absent',
              child: Row(
                children: [
                  Icon(Icons.cancel, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Mark All Absent'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'reset',
              child: Row(
                children: [
                  Icon(Icons.refresh, color: Colors.blue),
                  SizedBox(width: 12),
                  Text('Reset'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    int present = attendance.values.where((e) => e).length;
    int absent = attendance.length - present;
    int lateCount = remarks.values.where((r) => r.isNotEmpty).length;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.green, Colors.greenAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(
            label: "Present",
            count: present,
            color: Colors.white,
            icon: Icons.check_circle,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          _SummaryItem(
            label: "Absent",
            count: absent,
            color: Colors.white,
            icon: Icons.cancel,
          ),
          if (lateCount > 0) ...[
            Container(
              width: 1,
              height: 40,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            _SummaryItem(
              label: "Late",
              count: lateCount,
              color: Colors.white,
              icon: Icons.access_time,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStudentCard({
    required String id,
    required String name,
    required String rollNo,
    required bool isPresent,
    required bool hasRemark,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: hasRemark
            ? BorderSide(color: Colors.orange.shade300, width: 1)
            : BorderSide.none,
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isPresent ? Colors.green.shade100 : Colors.red.shade100,
          child: Text(
            rollNo.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isPresent ? Colors.green : Colors.red,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPresent ? "Present" : "Absent",
              style: TextStyle(
                color: isPresent ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (remarks[id]?.isNotEmpty ?? false)
              Text(
                "Note: ${remarks[id]}",
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: Switch(
          value: isPresent,
          activeColor: Colors.green,
          onChanged: (value) {
            setState(() {
              attendance[id] = value;
              if (value) {
                remarks.remove(id);
              }
            });
          },
        ),
        children: [
          if (!isPresent)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Absent Reason (Optional)",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: remarks[id],
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: "Enter reason for absence...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    onChanged: (value) {
                      setState(() {
                        remarks[id] = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          if (isPresent)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _TimePickerButton(
                      label: "Check In",
                      time: checkInTimes[id],
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            checkInTimes[id] = time;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimePickerButton(
                      label: "Check Out",
                      time: checkOutTimes[id],
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            checkOutTimes[id] = time;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No students found",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            "Add students to ${widget.className}-${widget.section} first",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return FloatingActionButton.extended(
      backgroundColor: Colors.green,
      icon: isSaving
          ? const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      )
          : const Icon(Icons.save),
      label: Text(isSaving ? "Saving..." : _isEditing ? "Update Attendance" : "Save Attendance"),
      onPressed: isSaving ? null : _saveAttendance,
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      helpText: 'Select Attendance Date',
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        attendance.clear();
        remarks.clear();
        checkInTimes.clear();
        checkOutTimes.clear();
        _isEditing = false;
      });
      _loadExistingAttendance();
    }
  }

  Future<void> _saveAttendance() async {
    if (_students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No students to save attendance for"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final teacherUid = FirebaseAuth.instance.currentUser!.uid;

      // Get teacher name
      final teacherDoc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('teachers')
          .where('uid', isEqualTo: teacherUid)
          .limit(1)
          .get();

      String teacherName = "Teacher";
      if (teacherDoc.docs.isNotEmpty) {
        teacherName = teacherDoc.docs.first['name'] ?? "Teacher";
      }

      final batch = FirebaseFirestore.instance.batch();

      final attendanceRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('attendance')
          .doc(today)
          .collection('records');

      for (var student in _students) {
        final studentId = student['id'];
        final isPresent = attendance[studentId] ?? true;

        // Determine status
        String status;
        if (isPresent) {
          status = 'Present';
        } else {
          status = 'Absent';
        }

        final recordData = {
          "studentId": studentId,
          "name": student['name'],
          "rollNo": student['rollNo'],
          "className": widget.className,
          "section": widget.section,
          "status": status,
          "date": today,
          "updatedAt": FieldValue.serverTimestamp(),
          "updatedBy": teacherName,
          "updatedByUid": teacherUid,
        };

        // Add optional fields
        if (remarks[studentId]?.isNotEmpty ?? false) {
          recordData["remark"] = remarks[studentId];
        }

        if (checkInTimes[studentId] != null) {
          recordData["checkInTime"] = _formatTimeOfDay(checkInTimes[studentId]!);
        }

        if (checkOutTimes[studentId] != null) {
          recordData["checkOutTime"] = _formatTimeOfDay(checkOutTimes[studentId]!);
        }

        final recordRef = attendanceRef.doc(studentId);
        batch.set(recordRef, recordData);
      }

      // Also save a summary document for quick lookup
      final summaryRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('attendance_summary')
          .doc(today);

      batch.set(summaryRef, {
        "date": today,
        "className": widget.className,
        "section": widget.section,
        "totalStudents": _students.length,
        "present": attendance.values.where((e) => e).length,
        "absent": attendance.values.where((e) => !e).length,
        "updatedAt": FieldValue.serverTimestamp(),
        "updatedBy": teacherName,
      }, SetOptions(merge: true));

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? "Attendance updated successfully" : "Attendance saved successfully"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving attendance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final hour12 = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    return '$hour12:$minute $period';
  }
}

// ================= HELPER WIDGETS =================

class _SummaryItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: color.withValues(alpha: 0.9), fontSize: 12),
        ),
      ],
    );
  }
}

class _TimePickerButton extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final VoidCallback onTap;

  const _TimePickerButton({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                time != null
                    ? "${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}"
                    : label,
                style: TextStyle(
                  color: time != null ? Colors.black : Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}