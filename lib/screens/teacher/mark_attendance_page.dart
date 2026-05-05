import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/attendance_service.dart';

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
  final Map<String, String> _attendanceStatus =
      {}; // studentId -> Present/Absent/Late
  final Map<String, String> _remarks = {};
  final Map<String, String> _checkInTimes = {};
  final Map<String, String> _checkOutTimes = {};
  final Map<String, String> _studentNames = {};
  final Map<String, String> _studentRollNos = {};

  bool _isSaving = false;
  bool _isEditing = false;
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  List<QueryDocumentSnapshot> _students = [];

  final List<String> _statusOptions = ['Present', 'Absent', 'Late'];
  final Map<String, Color> _statusColors = {
    'Present': Colors.green,
    'Absent': Colors.red,
    'Late': Colors.orange,
  };
  final Map<String, IconData> _statusIcons = {
    'Present': Icons.check_circle,
    'Absent': Icons.cancel,
    'Late': Icons.access_time,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _loadStudents();
    await _loadExistingAttendance();
    setState(() => _isLoading = false);
  }

  Future<void> _loadStudents() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('students')
              .where('class', isEqualTo: widget.className)
              .where('section', isEqualTo: widget.section)
              .get();

      _students = snapshot.docs;

      for (var doc in _students) {
        final data = doc.data() as Map<String, dynamic>;
        _studentNames[doc.id] = data['name'] ?? 'Unknown';
        _studentRollNos[doc.id] = data['rollNo']?.toString() ?? '';

        if (!_attendanceStatus.containsKey(doc.id)) {
          _attendanceStatus[doc.id] = 'Present';
        }
      }
    } catch (e) {
      debugPrint('Error loading students: $e');
    }
  }

  Future<void> _loadExistingAttendance() async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('attendance')
              .doc(dateStr)
              .collection('records')
              .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final studentId = doc.id;
        _attendanceStatus[studentId] = data['status'] ?? 'Present';
        if (data['remark'] != null && data['remark'].toString().isNotEmpty) {
          _remarks[studentId] = data['remark'];
        }
        if (data['checkInTime'] != null &&
            data['checkInTime'].toString().isNotEmpty) {
          _checkInTimes[studentId] = data['checkInTime'];
        }
        if (data['checkOutTime'] != null &&
            data['checkOutTime'].toString().isNotEmpty) {
          _checkOutTimes[studentId] = data['checkOutTime'];
        }
      }
      setState(() {
        _isEditing = snapshot.docs.isNotEmpty;
      });
    } catch (e) {
      debugPrint('No existing attendance found for $dateStr');
    }
  }

  Future<void> _saveAttendance() async {
    if (_students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No students found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final attendanceData = <String, Map<String, dynamic>>{};

      for (var student in _students) {
        final studentId = student.id;
        final status = _attendanceStatus[studentId] ?? 'Present';

        attendanceData[studentId] = {
          'studentId': studentId,
          'studentName': _studentNames[studentId] ?? '',
          'rollNo': _studentRollNos[studentId] ?? '',
          'status': status,
          'remark':
              status == 'Absent'
                  ? (_remarks[studentId] ?? '')
                  : (status == 'Late'
                      ? (_remarks[studentId] ?? 'Late arrival')
                      : ''),
          'checkInTime': _checkInTimes[studentId] ?? '',
          'checkOutTime': _checkOutTimes[studentId] ?? '',
          'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
        };
      }

      final success = await AttendanceService.saveAttendance(
        schoolId: widget.schoolId,
        className: widget.className,
        section: widget.section,
        date: _selectedDate,
        attendanceData: attendanceData,
      );

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save attendance'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _attendanceStatus.clear();
        _remarks.clear();
        _checkInTimes.clear();
        _checkOutTimes.clear();
        _isEditing = false;
      });
      await _loadExistingAttendance();
    }
  }

  void _markAll(String status) {
    setState(() {
      for (var student in _students) {
        _attendanceStatus[student.id] = status;
      }
    });
  }

  void _showRemarkDialog(String studentId, String studentName) {
    final remarkController = TextEditingController(text: _remarks[studentId]);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text('Remark for $studentName'),
            content: TextField(
              controller: remarkController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter remark (reason for absence/late)',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (remarkController.text.isNotEmpty) {
                      _remarks[studentId] = remarkController.text;
                    } else {
                      _remarks.remove(studentId);
                    }
                  });
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showTimePickerDialog(String studentId, bool isCheckIn) {
    showTimePicker(context: context, initialTime: TimeOfDay.now()).then((time) {
      if (time != null) {
        final timeStr =
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        setState(() {
          if (isCheckIn) {
            _checkInTimes[studentId] = timeStr;
          } else {
            _checkOutTimes[studentId] = timeStr;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text('Mark Attendance - ${widget.className} ${widget.section}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
          IconButton(
            icon:
                _isSaving
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveAttendance,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _students.isEmpty
              ? const Center(child: Text('No students found in this class'))
              : Column(
                children: [
                  _buildDateHeader(),
                  _buildQuickActions(),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        final studentId = student.id;
                        return _buildStudentCard(studentId);
                      },
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildDateHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selected Date',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEEE, dd MMM yyyy').format(_selectedDate),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (_isEditing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Editing',
                style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    int present = _attendanceStatus.values.where((s) => s == 'Present').length;
    int absent = _attendanceStatus.values.where((s) => s == 'Absent').length;
    int late = _attendanceStatus.values.where((s) => s == 'Late').length;

    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatChip(
                'Present',
                present,
                Colors.green,
                Icons.check_circle,
              ),
              _buildStatChip('Absent', absent, Colors.red, Icons.cancel),
              _buildStatChip('Late', late, Colors.orange, Icons.access_time),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _markAll('Present'),
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('All Present'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _markAll('Absent'),
                  icon: const Icon(Icons.cancel, size: 18),
                  label: const Text('All Absent'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _markAll('Late'),
                  icon: const Icon(Icons.access_time, size: 18),
                  label: const Text('All Late'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: $count',
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(String studentId) {
    final studentName = _studentNames[studentId] ?? 'Unknown';
    final rollNo = _studentRollNos[studentId] ?? '';
    final currentStatus = _attendanceStatus[studentId] ?? 'Present';
    final isLate = currentStatus == 'Late';
    final isAbsent = currentStatus == 'Absent';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: _statusColors[currentStatus]?.withOpacity(
                    0.2,
                  ),
                  child: Text(
                    rollNo.isNotEmpty ? rollNo : '?',
                    style: TextStyle(
                      color: _statusColors[currentStatus],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Roll No: ${rollNo.isNotEmpty ? rollNo : "N/A"}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: _statusColors[currentStatus]?.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: DropdownButton<String>(
                    value: currentStatus,
                    underline: const SizedBox(),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: _statusColors[currentStatus],
                    ),
                    items:
                        _statusOptions.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Row(
                              children: [
                                Icon(
                                  _statusIcons[status],
                                  size: 16,
                                  color: _statusColors[status],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  status,
                                  style: TextStyle(
                                    color: _statusColors[status],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _attendanceStatus[studentId] = value!;
                        if (value == 'Present') {
                          _remarks.remove(studentId);
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          if (isLate || isAbsent)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed:
                          () => _showRemarkDialog(studentId, studentName),
                      icon: Icon(
                        Icons.comment,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                      label: Text(
                        _remarks[studentId] != null
                            ? 'Edit Remark'
                            : 'Add Remark',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ),
                  if (isLate) ...[
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _showTimePickerDialog(studentId, true),
                        icon: Icon(
                          Icons.login,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                        label: Text(
                          _checkInTimes[studentId] != null
                              ? 'In: ${_checkInTimes[studentId]}'
                              : 'Check In',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed:
                            () => _showTimePickerDialog(studentId, false),
                        icon: Icon(
                          Icons.logout,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                        label: Text(
                          _checkOutTimes[studentId] != null
                              ? 'Out: ${_checkOutTimes[studentId]}'
                              : 'Check Out',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (_remarks[studentId] != null && _remarks[studentId]!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notes, size: 14, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _remarks[studentId]!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
