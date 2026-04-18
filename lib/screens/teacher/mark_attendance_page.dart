import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MarkAttendancePage extends StatefulWidget {
  final String schoolId;
  final String className;
  final String section;

  const MarkAttendancePage({
    super.key,
    required this.schoolId,
    required this.className,
    required this.section,
  });

  @override
  State<MarkAttendancePage> createState() => _MarkAttendancePageState();
}

class _MarkAttendancePageState extends State<MarkAttendancePage> {
  final Map<String, bool> attendance = {};
  final Map<String, String> remarks = {};
  final Map<String, TimeOfDay?> checkInTimes = {};
  final Map<String, TimeOfDay?> checkOutTimes = {};

  bool isSaving = false;
  bool _isEditing = false;
  DateTime? _selectedDate;

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
    _loadExistingAttendance();
  }

  String get today => DateFormat('yyyy-MM-dd').format(_selectedDate ?? DateTime.now());

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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolId)
            .collection('students')
            .where('class', isEqualTo: widget.className)
            .where('section', isEqualTo: widget.section)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final students = snapshot.data!.docs;

          // Initialize default values for new students
          for (var doc in students) {
            if (!attendance.containsKey(doc.id)) {
              attendance[doc.id] = true; // Default Present
            }
          }

          int present = attendance.values.where((e) => e).length;
          int absent = attendance.length - present;
          int lateCount = remarks.values.where((r) => r.isNotEmpty).length;

          return Column(
            children: [
              _buildSummaryCard(present, absent, lateCount),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final doc = students[index];
                    final id = doc.id;
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'No Name';
                    final rollNo = data['rollNo'] ?? '';
                    final isPresent = attendance[id] ?? true;
                    final hasRemark = remarks[id]?.isNotEmpty ?? false;

                    return _buildStudentCard(
                      id: id,
                      name: name,
                      rollNo: rollNo,
                      isPresent: isPresent,
                      hasRemark: hasRemark,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildSaveButton(),
      bottomNavigationBar: _buildQuickActionsBar(),
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

  Widget _buildSummaryCard(int present, int absent, int lateCount) {
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

  Widget _buildQuickActionsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _QuickActionChip(
            label: "All Present",
            icon: Icons.check_circle,
            color: Colors.green,
            onTap: () {
              setState(() {
                attendance.updateAll((key, value) => true);
                remarks.clear();
              });
            },
          ),
          _QuickActionChip(
            label: "All Absent",
            icon: Icons.cancel,
            color: Colors.red,
            onTap: () {
              setState(() {
                attendance.updateAll((key, value) => false);
                remarks.clear();
              });
            },
          ),
          _QuickActionChip(
            label: "Reset",
            icon: Icons.refresh,
            color: Colors.blue,
            onTap: () {
              setState(() {
                attendance.clear();
                remarks.clear();
                _loadExistingAttendance();
              });
            },
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
        _isEditing = false;
      });
      _loadExistingAttendance();
    }
  }

  Future<void> _saveAttendance() async {
    try {
      setState(() => isSaving = true);

      final batch = FirebaseFirestore.instance.batch();

      final attendanceRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('attendance')
          .doc(today)
          .collection('records');

      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('students')
          .where('class', isEqualTo: widget.className)
          .where('section', isEqualTo: widget.section)
          .get();

      for (var doc in studentsSnapshot.docs) {
        final studentId = doc.id;
        final data = doc.data();
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
          "name": data['name'] ?? "",
          "rollNo": data['rollNo'] ?? "",
          "className": widget.className,
          "section": widget.section,
          "status": status,
          "date": today,
          "updatedAt": FieldValue.serverTimestamp(),
          "updatedBy": "Teacher", // You can add teacher ID here
        };

        // Add optional fields
        if (remarks[studentId]?.isNotEmpty ?? false) {
          recordData["remark"] = remarks[studentId];
        }

        if (checkInTimes[studentId] != null) {
          recordData["checkInTime"] = checkInTimes[studentId]!.format(context);
        }

        if (checkOutTimes[studentId] != null) {
          recordData["checkOutTime"] = checkOutTimes[studentId]!.format(context);
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
        "totalStudents": studentsSnapshot.docs.length,
        "present": attendance.values.where((e) => e).length,
        "absent": attendance.values.where((e) => !e).length,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();

      setState(() => isSaving = false);

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
      setState(() => isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

class _QuickActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}