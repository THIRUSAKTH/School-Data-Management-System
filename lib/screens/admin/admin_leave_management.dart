// lib/screens/admin/admin_leave_management.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:schoolprojectjan/app_config.dart';

class AdminLeaveManagement extends StatefulWidget {
  const AdminLeaveManagement({Key? key}) : super(key: key);

  @override
  State<AdminLeaveManagement> createState() => _AdminLeaveManagementState();
}

class _AdminLeaveManagementState extends State<AdminLeaveManagement>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<_TabInfo> _tabs = [
    _TabInfo('Pending',  'pending',  Color(0xFFFF9F43), Icons.hourglass_top_rounded),
    _TabInfo('Approved', 'approved', Color(0xFF3DB88B), Icons.check_circle_rounded),
    _TabInfo('Rejected', 'rejected', Color(0xFFE05C5C), Icons.cancel_rounded),
    _TabInfo('All',      'all',      Color(0xFF4F8EF7), Icons.list_alt_rounded),
  ];

  // ── Firestore paths (all school-scoped)
  static CollectionReference get _leaveCol => FirebaseFirestore.instance
      .collection(AppConfig.schoolsCollection)
      .doc(AppConfig.schoolId)
      .collection('leave_requests');

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        title: const Text('Leave Requests',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppConfig.primaryColor,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle:           const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
              tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _SummaryStrip(leaveCol: _leaveCol),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) => _LeaveList(
                tab: tab,
                leaveCol: _leaveCol,
                notificationsCol: _notificationsCol,
                fcmQueueCol: _fcmQueueCol,
                usersCol: _usersCol,
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Live summary strip
class _SummaryStrip extends StatelessWidget {
  final CollectionReference leaveCol;
  const _SummaryStrip({required this.leaveCol});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: leaveCol.snapshots(),
      builder: (context, snapshot) {
        final docs     = snapshot.data?.docs ?? [];
        final pending  = docs.where((d) => d['status'] == 'pending').length;
        final approved = docs.where((d) => d['status'] == 'approved').length;
        final rejected = docs.where((d) => d['status'] == 'rejected').length;
        final total    = docs.length;

        return Container(
          color: AppConfig.primaryColor,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Row(
            children: [
              _StatChip(count: total,    label: 'Total',    color: Colors.white),
              const SizedBox(width: 8),
              _StatChip(count: pending,  label: 'Pending',  color: const Color(0xFFFFE4A0)),
              const SizedBox(width: 8),
              _StatChip(count: approved, label: 'Approved', color: const Color(0xFFB9F5E0)),
              const SizedBox(width: 8),
              _StatChip(count: rejected, label: 'Rejected', color: const Color(0xFFFFD0D0)),
            ],
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _StatChip({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16)),
          Text(label,    style: TextStyle(color: color.withOpacity(0.9), fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    ),
  );
}

// ── Leave list per tab
class _LeaveList extends StatelessWidget {
  final _TabInfo            tab;
  final CollectionReference leaveCol;
  final CollectionReference notificationsCol;
  final CollectionReference fcmQueueCol;
  final CollectionReference usersCol;

  const _LeaveList({
    required this.tab,
    required this.leaveCol,
    required this.notificationsCol,
    required this.fcmQueueCol,
    required this.usersCol,
  });

  Stream<QuerySnapshot> _stream() {
    Query q = leaveCol.orderBy('createdAt', descending: true);
    if (tab.filter != 'all') q = q.where('status', isEqualTo: tab.filter);
    return q.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _stream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppConfig.primaryColor));
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 56, color: Color(0xFFE05C5C)),
                const SizedBox(height: 12),
                const Text('Something went wrong', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('${snapshot.error}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF718096)),
                    textAlign: TextAlign.center),
              ],
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(tab.icon, size: 64, color: tab.color.withOpacity(0.3)),
                const SizedBox(height: 12),
                Text(
                  tab.filter == 'pending'
                      ? 'No pending requests'
                      : 'No ${tab.label.toLowerCase()} requests',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF4A5568)),
                ),
                if (tab.filter == 'pending')
                  const Text('All teachers are accounted for 👍',
                      style: TextStyle(color: Color(0xFF718096), fontSize: 13)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final doc  = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            return _LeaveCard(
              docId:            doc.id,
              data:             data,
              leaveCol:         leaveCol,
              notificationsCol: notificationsCol,
              fcmQueueCol:      fcmQueueCol,
              usersCol:         usersCol,
            );
          },
        );
      },
    );
  }
}

// ── Leave card with approve/reject + push notifications
class _LeaveCard extends StatelessWidget {
  final String              docId;
  final Map<String, dynamic> data;
  final CollectionReference leaveCol;
  final CollectionReference notificationsCol;
  final CollectionReference fcmQueueCol;
  final CollectionReference usersCol;

  const _LeaveCard({
    required this.docId,
    required this.data,
    required this.leaveCol,
    required this.notificationsCol,
    required this.fcmQueueCol,
    required this.usersCol,
  });

  Color get _statusColor {
    switch (data['status']) {
      case 'approved': return const Color(0xFF3DB88B);
      case 'rejected': return const Color(0xFFE05C5C);
      default:         return const Color(0xFFFF9F43);
    }
  }

  IconData get _statusIcon {
    switch (data['status']) {
      case 'approved': return Icons.check_circle_rounded;
      case 'rejected': return Icons.cancel_rounded;
      default:         return Icons.hourglass_top_rounded;
    }
  }

  String get _statusLabel {
    switch (data['status']) {
      case 'approved': return 'Approved';
      case 'rejected': return 'Rejected';
      default:         return 'Pending';
    }
  }

  Color get _typeColor {
    switch (data['leaveType']) {
      case 'Casual Leave':    return const Color(0xFF4F8EF7);
      case 'Sick Leave':      return const Color(0xFFE05C5C);
      case 'Earned Leave':    return const Color(0xFF3DB88B);
      case 'Maternity Leave': return const Color(0xFFB47FEB);
      default:                return const Color(0xFFFF9F43);
    }
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is String)    return DateTime.tryParse(v);
    return null;
  }

  // ── Notify teacher (in-app + FCM push)
  Future<void> _notifyTeacher({
    required String teacherId,
    required String title,
    required String body,
  }) async {
    try {
      // In-app notification
      await notificationsCol.add({
        'userId':    teacherId,
        'title':     title,
        'body':      body,
        'type':      'leave_response',
        'read':      false,
        'schoolId':  AppConfig.schoolId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // FCM push — look up teacher's FCM token from school users collection
      final teacherDoc = await usersCol.doc(teacherId).get();
      if (teacherDoc.exists) {
        final fcmToken = (teacherDoc.data() as Map<String, dynamic>?);['fcmToken'];
        if (fcmToken != null && fcmToken.toString().isNotEmpty) {
          await fcmQueueCol.add({
            'token':     fcmToken,
            'title':     title,
            'body':      body,
            'data':      {
              'type':     'leave_response',
              'screen':   'teacher_leave_history',
              'schoolId': AppConfig.schoolId,
            },
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      debugPrint('Teacher notify error: $e');
    }
  }

  // ── Approve confirm dialog
  void _showApproveDialog(BuildContext context) {
    final teacherName = data['teacherName'] ?? 'Teacher';
    final teacherId   = data['teacherId']   ?? '';
    final leaveType   = data['leaveType']   ?? 'Leave';
    final days        = data['days']        ?? 1;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: const [
          Icon(Icons.check_circle_rounded, color: Color(0xFF3DB88B)),
          SizedBox(width: 8),
          Expanded(child: Text('Approve Leave?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
        ]),
        content: Text(
          'Approve $leaveType ($days day${days > 1 ? 's' : ''}) for $teacherName?\n\n'
              'A push notification will be sent to the teacher.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF718096))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _approveLeave(context, teacherId, teacherName, leaveType, days);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3DB88B),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Approve & Notify'),
          ),
        ],
      ),
    );
  }

  // ── Reject dialog with reason
  void _showRejectDialog(BuildContext context) {
    final teacherName = data['teacherName'] ?? 'Teacher';
    final teacherId   = data['teacherId']   ?? '';
    final reasonCtrl  = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: const [
          Icon(Icons.cancel_rounded, color: Color(0xFFE05C5C)),
          SizedBox(width: 8),
          Expanded(child: Text('Reject Leave?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rejecting leave for $teacherName.'),
            const SizedBox(height: 12),
            const Text('Reason for rejection',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF4A5568))),
            const SizedBox(height: 6),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter reason...',
                hintStyle: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF7FAFC),
                contentPadding: const EdgeInsets.all(10),
                border:        OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE05C5C), width: 1.5)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF718096))),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonCtrl.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                  content: Text('Please enter a reason'),
                  backgroundColor: Color(0xFFFF9F43),
                ));
                return;
              }
              Navigator.pop(ctx);
              _rejectLeave(context, teacherId, teacherName, reason);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE05C5C),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Reject & Notify'),
          ),
        ],
      ),
    );
  }

  // ── Approve Firestore action + notify teacher
  Future<void> _approveLeave(
      BuildContext context,
      String teacherId,
      String teacherName,
      String leaveType,
      int days,
      ) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      await leaveCol.doc(docId).update({
        'status':     'approved',
        'approvedBy': uid,
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt':  FieldValue.serverTimestamp(),
      });

      await _notifyTeacher(
        teacherId: teacherId,
        title: 'Leave Approved ✅',
        body:  'Your $leaveType ($days day${days > 1 ? 's' : ''}) has been approved by Admin.',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$teacherName\'s leave approved & teacher notified'),
          backgroundColor: const Color(0xFF3DB88B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: const Color(0xFFE05C5C),
        ));
      }
    }
  }

  // ── Reject Firestore action + notify teacher
  Future<void> _rejectLeave(
      BuildContext context,
      String teacherId,
      String teacherName,
      String reason,
      ) async {
    try {
      final uid       = FirebaseAuth.instance.currentUser?.uid;
      final leaveType = data['leaveType'] ?? 'Leave';
      await leaveCol.doc(docId).update({
        'status':          'rejected',
        'rejectionReason': reason,
        'rejectedBy':      uid,
        'rejectedAt':      FieldValue.serverTimestamp(),
        'updatedAt':       FieldValue.serverTimestamp(),
      });

      await _notifyTeacher(
        teacherId: teacherId,
        title: 'Leave Rejected ❌',
        body:  'Your $leaveType request was rejected. Reason: $reason',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$teacherName\'s leave rejected & teacher notified'),
          backgroundColor: const Color(0xFFE05C5C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: const Color(0xFFE05C5C),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final from         = _parseDate(data['fromDate']);
    final to           = _parseDate(data['toDate']);
    final appliedAt    = _parseDate(data['appliedAt']);
    final status       = data['status']       ?? 'pending';
    final days         = data['days']         ?? 1;
    final teacherName  = data['teacherName']  ?? 'Unknown Teacher';
    final leaveType    = data['leaveType']    ?? 'Leave';
    final reason       = data['reason']       ?? '';
    final teacherClass = data['teacherClass'] ?? '';
    final teacherSubj  = data['teacherSubject'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDF2F7)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _typeColor.withOpacity(0.12),
                  child: Text(
                    teacherName.isNotEmpty ? teacherName[0].toUpperCase() : 'T',
                    style: TextStyle(color: _typeColor, fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(teacherName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1A202C))),
                      if (teacherClass.isNotEmpty || teacherSubj.isNotEmpty)
                        Text(
                          [teacherClass, teacherSubj].where((s) => s.isNotEmpty).join(' • '),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF718096)),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _statusColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon, size: 12, color: _statusColor),
                      const SizedBox(width: 4),
                      Text(_statusLabel,
                          style: TextStyle(color: _statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF0F4F8)),

          // ── Details
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Leave type + days badges
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(leaveType,
                          style: TextStyle(color: _typeColor, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAFC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text('$days day${days > 1 ? 's' : ''}',
                          style: const TextStyle(color: Color(0xFF4A5568), fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Date range
                if (from != null && to != null)
                  _InfoRow(
                    icon: Icons.calendar_today_rounded,
                    text: '${DateFormat('dd MMM yyyy').format(from)}  →  ${DateFormat('dd MMM yyyy').format(to)}',
                  ),
                const SizedBox(height: 4),

                // Applied at
                if (appliedAt != null)
                  _InfoRow(
                    icon: Icons.access_time_rounded,
                    text: 'Applied on ${DateFormat('dd MMM yyyy, hh:mm a').format(appliedAt)}',
                    muted: true,
                  ),

                // Reason box
                if (reason.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.notes_rounded, size: 15, color: Color(0xFF718096)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(reason,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF4A5568)),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                ],

                // Rejection reason
                if (status == 'rejected' && data['rejectionReason'] != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5F5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFEB2B2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFFE05C5C)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Rejection Reason',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFE05C5C))),
                              const SizedBox(height: 2),
                              Text(data['rejectionReason'],
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF742A2A))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Approve / Reject buttons (pending only)
                if (status == 'pending') ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showRejectDialog(context),
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFE05C5C),
                            side: const BorderSide(color: Color(0xFFE05C5C)),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showApproveDialog(context),
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3DB88B),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   text;
  final bool     muted;
  const _InfoRow({required this.icon, required this.text, this.muted = false});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 14, color: muted ? const Color(0xFFA0AEC0) : const Color(0xFF718096)),
      const SizedBox(width: 7),
      Expanded(
        child: Text(text,
            style: TextStyle(
                fontSize: 13,
                color: muted ? const Color(0xFFA0AEC0) : const Color(0xFF4A5568))),
      ),
    ],
  );
}

class _TabInfo {
  final String  label;
  final String  filter;
  final Color   color;
  final IconData icon;
  const _TabInfo(this.label, this.filter, this.color, this.icon);
}