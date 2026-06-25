// lib/screens/teacher/teacher_leave_application.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:schoolprojectjan/app_config.dart';

class TeacherLeaveApplication extends StatefulWidget {
  const TeacherLeaveApplication({Key? key}) : super(key: key);

  @override
  State<TeacherLeaveApplication> createState() => _TeacherLeaveApplicationState();
}

class _TeacherLeaveApplicationState extends State<TeacherLeaveApplication> {
  final _formKey   = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();

  String    _leaveType = 'Casual Leave';
  DateTime? _from;
  DateTime? _to;
  bool      _loading = false;

  // ── Firestore helpers using AppConfig paths
  static CollectionReference get _leaveCol => FirebaseFirestore.instance
      .collection(AppConfig.schoolsCollection)
      .doc(AppConfig.schoolId)
      .collection('leave_requests');

  static CollectionReference get _teachersCol => FirebaseFirestore.instance
      .collection(AppConfig.schoolsCollection)
      .doc(AppConfig.schoolId)
      .collection(AppConfig.teachersCollection);

  static CollectionReference get _notificationsCol => FirebaseFirestore.instance
      .collection(AppConfig.schoolsCollection)
      .doc(AppConfig.schoolId)
      .collection('notifications');

  static CollectionReference get _fcmQueueCol => FirebaseFirestore.instance
      .collection(AppConfig.schoolsCollection)
      .doc(AppConfig.schoolId)
      .collection('fcm_queue');

  static CollectionReference get _usersCol => FirebaseFirestore.instance
      .collection(AppConfig.schoolsCollection)
      .doc(AppConfig.schoolId)
      .collection('users');

  // ── Leave type config
  static const List<Map<String, dynamic>> _leaveTypes = [
    {'name': 'Casual Leave',    'short': 'CL',  'color': Color(0xFF4F8EF7)},
    {'name': 'Sick Leave',      'short': 'SL',  'color': Color(0xFFE05C5C)},
    {'name': 'Earned Leave',    'short': 'EL',  'color': Color(0xFF3DB88B)},
    {'name': 'Maternity Leave', 'short': 'ML',  'color': Color(0xFFB47FEB)},
    {'name': 'Loss of Pay',     'short': 'LOP', 'color': Color(0xFFFF9F43)},
  ];

  int get _totalDays {
    if (_from == null || _to == null) return 0;
    return _to!.difference(_from!).inDays + 1;
  }

  Color get _selectedColor => (_leaveTypes.firstWhere(
        (t) => t['name'] == _leaveType,
    orElse: () => _leaveTypes.first,
  )['color'] as Color);

  // ── Date picker
  Future<void> _pickDate(bool isFrom) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? now : (_from ?? now),
      firstDate: DateTime(now.year, now.month, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: AppConfig.primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
        if (_to != null && _to!.isBefore(picked)) _to = null;
      } else {
        _to = picked;
      }
    });
  }

  // ── Notify all admins (in-app + FCM push)
  Future<void> _notifyAdmins(String teacherName) async {
    try {
      // Find admins in this school's users collection
      final adminsSnap = await _usersCol
          .where('role', isEqualTo: 'admin')
          .get();

      for (final admin in adminsSnap.docs) {
        final adminId  = admin.id;
        final fcmToken = (admin.data() as Map<String, dynamic>)['fcmToken'];

        // In-app notification
        await _notificationsCol.add({
          'userId':    adminId,
          'title':     'New Leave Request',
          'body':      '$teacherName applied for $_leaveType ($_totalDays day${_totalDays > 1 ? 's' : ''}). Tap to review.',
          'type':      'leave_request',
          'read':      false,
          'schoolId':  AppConfig.schoolId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // FCM push (Cloud Function picks this up)
        if (fcmToken != null && fcmToken.toString().isNotEmpty) {
          await _fcmQueueCol.add({
            'token':     fcmToken,
            'title':     'New Leave Request',
            'body':      '$teacherName applied for $_leaveType ($_totalDays day${_totalDays > 1 ? 's' : ''})',
            'data':      {
              'type':     'leave_request',
              'screen':   'admin_leave',
              'schoolId': AppConfig.schoolId,
            },
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      debugPrint('Admin notify error: $e');
    }
  }

  // ── Submit leave request
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_from == null || _to == null) {
      _snack('Please select from and to dates', const Color(0xFFFF9F43));
      return;
    }
    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;

      // Load teacher data from school-scoped path
      final snap  = await _teachersCol
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .get();

      final tData       = snap.docs.isNotEmpty
          ? snap.docs.first.data() as Map<String, dynamic>
          : <String, dynamic>{};
      final teacherName = tData['name'] ?? 'Teacher';

      // Save under schools/school_1/leave_requests
      await _leaveCol.add({
        'teacherId':      user.uid,
        'teacherName':    teacherName,
        'teacherClass':   tData['className'] ?? tData['class'] ?? '',
        'teacherSubject': tData['subject'] ?? '',
        'leaveType':      _leaveType,
        'fromDate':       _from!.toIso8601String(),
        'toDate':         _to!.toIso8601String(),
        'days':           _totalDays,
        'reason':         _reasonCtrl.text.trim(),
        'status':         'pending',
        'schoolId':       AppConfig.schoolId,
        'appliedAt':      DateTime.now().toIso8601String(),
        'createdAt':      FieldValue.serverTimestamp(),
      });

      // Notify all admins
      await _notifyAdmins(teacherName);

      if (!mounted) return;
      _snack('Leave request submitted! Admin has been notified.', AppConfig.primaryColor);
      Navigator.pop(context);
    } catch (e) {
      _snack('Error: $e', const Color(0xFFE05C5C));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Apply for Leave', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Leave type chips
              _SectionLabel('Leave Type'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _leaveTypes.map((t) {
                  final isSelected = _leaveType == t['name'];
                  final color = t['color'] as Color;
                  return GestureDetector(
                    onTap: () => setState(() => _leaveType = t['name'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: isSelected ? color : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                            color: isSelected ? color : const Color(0xFFE2E8F0)),
                        boxShadow: isSelected
                            ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                            : [],
                      ),
                      child: Text(
                        '${t['short']}  •  ${t['name']}',
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF718096),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 22),

              // ── Date range
              _SectionLabel('Duration'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _DateTile(label: 'From Date', date: _from, onTap: () => _pickDate(true))),
                  const SizedBox(width: 12),
                  Expanded(child: _DateTile(label: 'To Date',   date: _to,   onTap: () => _pickDate(false))),
                ],
              ),

              if (_totalDays > 0) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: _selectedColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _selectedColor.withOpacity(0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.date_range_rounded, size: 16, color: _selectedColor),
                      const SizedBox(width: 8),
                      Text(
                        'Total $_totalDays day${_totalDays > 1 ? 's' : ''} of leave',
                        style: TextStyle(color: _selectedColor, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 22),

              // ── Reason
              _SectionLabel('Reason for Leave'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonCtrl,
                maxLines: 4,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a reason' : null,
                decoration: InputDecoration(
                  hintText: 'Describe the reason for leave...',
                  hintStyle: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 13),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(14),
                  border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppConfig.primaryColor, width: 1.5)),
                  errorBorder:   OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE05C5C))),
                ),
              ),

              const SizedBox(height: 12),

              // ── Info note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConfig.primaryColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppConfig.primaryColor.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notifications_active_rounded, size: 16, color: AppConfig.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Admin will be notified immediately. You will receive a push notification once your leave is approved or rejected.',
                        style: TextStyle(fontSize: 12, color: AppConfig.primaryColor),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConfig.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Submit Leave Request',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable widgets
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF4A5568)));
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  const _DateTile({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = AppConfig.primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: date != null ? accent.withOpacity(0.4) : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF718096), fontWeight: FontWeight.w500)),
            const SizedBox(height: 5),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 14,
                    color: date != null ? accent : const Color(0xFFA0AEC0)),
                const SizedBox(width: 6),
                Text(
                  date != null ? DateFormat('dd MMM yyyy').format(date!) : 'Select date',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: date != null ? const Color(0xFF2D3748) : const Color(0xFFA0AEC0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}