import 'package:firebase_auth/firebase_auth.dart';
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
  // Attendance status: true = Present/Late, false = Absent
  final Map<String, bool> _attendance = {};

  // For Late status only - stores the reason
  final Map<String, String> _lateReasons = {};

  // For Late status - stores check-in time
  final Map<String, TimeOfDay?> _checkInTimes = {};

  // For Late status - stores check-out time
  final Map<String, TimeOfDay?> _checkOutTimes = {};

  // Track if student is marked as Late separately
  final Map<String, bool> _isLate = {};

  bool _isSaving = false;
  bool _isEditing = false;
  DateTime? _selectedDate;

  // Late reasons options
  final List<String> _lateReasonOptions = [
    'Traffic',
    'Weather',
    'Medical',
    'Transport Issue',
    'Family Emergency',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadExistingAttendance();
  }

  String get _today => DateFormat('yyyy-MM-dd').format(_selectedDate ?? DateTime.now());

  Future<void> _loadExistingAttendance() async {
    try {
      final recordsSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('attendance')
          .doc(_today)
          .collection('records')
          .get();

      if (recordsSnapshot.docs.isNotEmpty) {
        setState(() {
          _isEditing = true;
          for (var doc in recordsSnapshot.docs) {
            final data = doc.data();
            final status = data['status'];
            final studentId = doc.id;

            if (status == 'Present') {
              _attendance[studentId] = true;
              _isLate[studentId] = false;
            } else if (status == 'Late') {
              _attendance[studentId] = true;
              _isLate[studentId] = true;
              _lateReasons[studentId] = data['remark'] ?? '';

              // Load check-in/out times if available
              if (data['checkInTime'] != null) {
                final timeParts = data['checkInTime'].split(':');
                if (timeParts.length == 2) {
                  _checkInTimes[studentId] = TimeOfDay(
                    hour: int.parse(timeParts[0]),
                    minute: int.parse(timeParts[1]),
                  );
                }
              }
              if (data['checkOutTime'] != null) {
                final timeParts = data['checkOutTime'].split(':');
                if (timeParts.length == 2) {
                  _checkOutTimes[studentId] = TimeOfDay(
                    hour: int.parse(timeParts[0]),
                    minute: int.parse(timeParts[1]),
                  );
                }
              }
            } else {
              _attendance[studentId] = false;
              _isLate[studentId] = false;
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
            if (!_attendance.containsKey(doc.id)) {
              _attendance[doc.id] = true; // Default Present
              _isLate[doc.id] = false;
            }
          }

          int present = _attendance.values.where((e) => e).length;
          int absent = _attendance.values.where((e) => !e).length;
          int lateCount = _isLate.values.where((e) => e).length;

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
                    final isPresent = _attendance[id] ?? true;
                    final lateStatus = _isLate[id] ?? false;
                    final hasRemark = _lateReasons[id]?.isNotEmpty ?? false;

                    return _buildStudentCard(
                      id: id,
                      name: name,
                      rollNo: rollNo.toString(),
                      isPresent: isPresent,
                      isLate: lateStatus,
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
          const Text(
            "Mark Attendance",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
        if (_selectedDate != null && _selectedDate != DateTime.now())
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
                  for (var key in _attendance.keys) {
                    _attendance[key] = true;
                    _isLate[key] = false;
                  }
                  _lateReasons.clear();
                  _checkInTimes.clear();
                  _checkOutTimes.clear();
                });
                break;
              case 'mark_all_absent':
                setState(() {
                  for (var key in _attendance.keys) {
                    _attendance[key] = false;
                    _isLate[key] = false;
                  }
                  _lateReasons.clear();
                  _checkInTimes.clear();
                  _checkOutTimes.clear();
                });
                break;
              case 'reset':
                setState(() {
                  _attendance.clear();
                  _isLate.clear();
                  _lateReasons.clear();
                  _checkInTimes.clear();
                  _checkOutTimes.clear();
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
            count: present - lateCount,
            color: Colors.white,
            icon: Icons.check_circle,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          if (lateCount > 0) ...[
            _SummaryItem(
              label: "Late",
              count: lateCount,
              color: Colors.white,
              icon: Icons.access_time,
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ],
          _SummaryItem(
            label: "Absent",
            count: absent,
            color: Colors.white,
            icon: Icons.cancel,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard({
    required String id,
    required String name,
    required String rollNo,
    required bool isPresent,
    required bool isLate,
    required bool hasRemark,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isLate
            ? BorderSide(color: Colors.orange.shade300, width: 1)
            : BorderSide.none,
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isPresent
              ? (isLate ? Colors.orange.shade100 : Colors.green.shade100)
              : Colors.red.shade100,
          child: Text(
            rollNo,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isPresent
                  ? (isLate ? Colors.orange : Colors.green)
                  : Colors.red,
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
              isPresent ? (isLate ? "Late" : "Present") : "Absent",
              style: TextStyle(
                color: isPresent
                    ? (isLate ? Colors.orange : Colors.green)
                    : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_lateReasons[id]?.isNotEmpty ?? false)
              Text(
                "Reason: ${_lateReasons[id]}",
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: Switch(
          value: isPresent,
          activeThumbColor: Colors.green,
          activeTrackColor: Colors.green.withValues(alpha: 0.5),
          onChanged: (value) {
            setState(() {
              _attendance[id] = value;
              if (!value) {
                // If marked absent, clear late-related data
                _isLate[id] = false;
                _lateReasons.remove(id);
                _checkInTimes.remove(id);
                _checkOutTimes.remove(id);
              } else if (value && (_isLate[id] == false)) {
                // If marked present, reset late status
                _isLate[id] = false;
                _lateReasons.remove(id);
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
                    initialValue: _lateReasons[id],
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
                        if (value.isNotEmpty) {
                          _lateReasons[id] = value;
                        } else {
                          _lateReasons.remove(id);
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          if (isPresent)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Late Status Switch
                  Row(
                    children: [
                      const Text(
                        "Mark as Late:",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: isLate,
                        activeThumbColor: Colors.orange,
                        activeTrackColor: Colors.orange.withValues(alpha: 0.5),
                        onChanged: (value) {
                          setState(() {
                            _isLate[id] = value;
                            if (!value) {
                              _lateReasons.remove(id);
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  if (isLate) ...[
                    const SizedBox(height: 12),
                    const Text(
                      "Late Reason",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _lateReasons.containsKey(id) ? _lateReasons[id] : null,
                      hint: const Text("Select reason for being late"),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      items: _lateReasonOptions.map((reason) {
                        return DropdownMenuItem(
                          value: reason,
                          child: Text(reason),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          if (value != null) {
                            _lateReasons[id] = value;
                          }
                        });
                      },
                    ),
                    if (_lateReasons[id] == 'Other')
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: TextFormField(
                          decoration: InputDecoration(
                            hintText: "Please specify...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _lateReasons[id] = value;
                            });
                          },
                        ),
                      ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _TimePickerButton(
                          label: "Check In Time",
                          time: _checkInTimes[id],
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null) {
                              setState(() {
                                _checkInTimes[id] = time;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TimePickerButton(
                          label: "Check Out Time",
                          time: _checkOutTimes[id],
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null) {
                              setState(() {
                                _checkOutTimes[id] = time;
                              });
                            }
                          },
                        ),
                      ),
                    ],
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
                for (var key in _attendance.keys) {
                  _attendance[key] = true;
                  _isLate[key] = false;
                }
                _lateReasons.clear();
                _checkInTimes.clear();
                _checkOutTimes.clear();
              });
            },
          ),
          _QuickActionChip(
            label: "All Absent",
            icon: Icons.cancel,
            color: Colors.red,
            onTap: () {
              setState(() {
                for (var key in _attendance.keys) {
                  _attendance[key] = false;
                  _isLate[key] = false;
                }
                _lateReasons.clear();
                _checkInTimes.clear();
                _checkOutTimes.clear();
              });
            },
          ),
          _QuickActionChip(
            label: "Reset",
            icon: Icons.refresh,
            color: Colors.blue,
            onTap: () {
              setState(() {
                _attendance.clear();
                _isLate.clear();
                _lateReasons.clear();
                _checkInTimes.clear();
                _checkOutTimes.clear();
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
      foregroundColor: Colors.white,
      icon: _isSaving
          ? const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      )
          : const Icon(Icons.save),
      label: Text(_isSaving ? "Saving..." : _isEditing ? "Update Attendance" : "Save Attendance"),
      onPressed: _isSaving ? null : _saveAttendance,
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
        _attendance.clear();
        _isLate.clear();
        _lateReasons.clear();
        _checkInTimes.clear();
        _checkOutTimes.clear();
        _isEditing = false;
      });
      _loadExistingAttendance();
    }
  }

  Future<void> _saveAttendance() async {
    if (!mounted) return;

    setState(() => _isSaving = true);

    try {
      final batch = FirebaseFirestore.instance.batch();

      final attendanceDocRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('attendance')
          .doc(_today);

      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('students')
          .where('class', isEqualTo: widget.className)
          .where('section', isEqualTo: widget.section)
          .get();

      for (var doc in studentsSnapshot.docs) {
        final studentId = doc.id;
        final studentData = doc.data();
        final isPresent = _attendance[studentId] ?? true;
        final lateStatus = _isLate[studentId] ?? false;

        // Determine final status
        String status;
        if (!isPresent) {
          status = 'Absent';
        } else if (lateStatus) {
          status = 'Late';
        } else {
          status = 'Present';
        }

        // Prepare record data
        final recordData = <String, dynamic>{
          "studentId": studentId,
          "name": studentData['name'] ?? "",
          "rollNo": studentData['rollNo'] ?? "",
          "className": widget.className,
          "section": widget.section,
          "status": status,
          "date": _today,
          "updatedAt": FieldValue.serverTimestamp(),
          "updatedBy": FirebaseAuth.instance.currentUser?.uid ?? "",
          "updatedByName": FirebaseAuth.instance.currentUser?.email ?? "Teacher",
        };

        // Add late-specific fields
        if (status == 'Late') {
          recordData["remark"] = _lateReasons[studentId] ?? "Not specified";

          // Add check-in time if available
          if (_checkInTimes.containsKey(studentId) && _checkInTimes[studentId] != null) {
            final time = _checkInTimes[studentId]!;
            recordData["checkInTime"] = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
          }

          // Add check-out time if available
          if (_checkOutTimes.containsKey(studentId) && _checkOutTimes[studentId] != null) {
            final time = _checkOutTimes[studentId]!;
            recordData["checkOutTime"] = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
          }
        } else if (status == 'Present') {
          // For regular present, add check-in/out times if available
          if (_checkInTimes.containsKey(studentId) && _checkInTimes[studentId] != null) {
            final time = _checkInTimes[studentId]!;
            recordData["checkInTime"] = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
          }
          if (_checkOutTimes.containsKey(studentId) && _checkOutTimes[studentId] != null) {
            final time = _checkOutTimes[studentId]!;
            recordData["checkOutTime"] = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
          }
        } else if (status == 'Absent') {
          // Add absence reason if provided
          if (_lateReasons.containsKey(studentId) && _lateReasons[studentId]!.isNotEmpty) {
            recordData["remark"] = _lateReasons[studentId];
          }
        }

        final recordRef = attendanceDocRef
            .collection('records')
            .doc(studentId);

        batch.set(recordRef, recordData);
      }

      // Also update a summary document for quick access
      final summaryData = <String, dynamic>{
        "date": _today,
        "className": widget.className,
        "section": widget.section,
        "totalStudents": studentsSnapshot.docs.length,
        "present": _attendance.values.where((e) => e).length,
        "absent": _attendance.values.where((e) => !e).length,
        "late": _isLate.values.where((e) => e).length,
        "updatedAt": FieldValue.serverTimestamp(),
      };

      final summaryRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('attendance_summary')
          .doc(_today);

      batch.set(summaryRef, summaryData);

      await batch.commit();

      if (mounted) {
        setState(() => _isSaving = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Attendance saved successfully!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving attendance: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Error saving attendance: $e');
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