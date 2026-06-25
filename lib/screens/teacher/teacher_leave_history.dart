// lib/screens/teacher/teacher_leave_history.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:schoolprojectjan/app_config.dart';
import 'teacher_leave_application.dart';

class TeacherLeaveHistory extends StatelessWidget {
  const TeacherLeaveHistory({Key? key}) : super(key: key);

  // schools/school_1/leave_requests
  static CollectionReference get _leaveCol => FirebaseFirestore.instance
      .collection(AppConfig.schoolsCollection)
      .doc(AppConfig.schoolId)
      .collection('leave_requests');

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Leaves', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Apply Leave',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TeacherLeaveApplication()),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _leaveCol
            .where('teacherId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppConfig.primaryColor));
          }

          final docs     = snapshot.data?.docs ?? [];
          final pending  = docs.where((d) => d['status'] == 'pending').length;
          final approved = docs.where((d) => d['status'] == 'approved').length;
          final rejected = docs.where((d) => d['status'] == 'rejected').length;

          return Column(
            children: [
              // ── Summary header
              Container(
                color: AppConfig.primaryColor,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    _SummaryTile(count: docs.length, label: 'Total',    color: Colors.white),
                    const SizedBox(width: 8),
                    _SummaryTile(count: pending,     label: 'Pending',  color: const Color(0xFFFFE4A0)),
                    const SizedBox(width: 8),
                    _SummaryTile(count: approved,    label: 'Approved', color: const Color(0xFFB9F5E0)),
                    const SizedBox(width: 8),
                    _SummaryTile(count: rejected,    label: 'Rejected', color: const Color(0xFFFFD0D0)),
                  ],
                ),
              ),

              // ── Leave balance strip
              _LeaveBalanceStrip(
                approvedDocs: docs.where((d) => d['status'] == 'approved').toList(),
              ),

              // ── History list
              Expanded(
                child: docs.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      const Text('No leave requests yet',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF4A5568))),
                      const SizedBox(height: 4),
                      const Text('Tap + to apply for leave',
                          style: TextStyle(fontSize: 13, color: Color(0xFF718096))),
                    ],
                  ),
                )
                    : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return _LeaveCard(data: data);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TeacherLeaveApplication()),
        ),
        backgroundColor: AppConfig.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Apply Leave', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── Summary tile
class _SummaryTile extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _SummaryTile({required this.count, required this.label, required this.color});

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

// ── Leave balance progress bars
class _LeaveBalanceStrip extends StatelessWidget {
  final List<QueryDocumentSnapshot> approvedDocs;
  const _LeaveBalanceStrip({required this.approvedDocs});

  int _used(String type) => approvedDocs
      .where((d) => d['leaveType'] == type)
      .fold(0, (sum, d) => sum + ((d['days'] as int?) ?? 1));

  @override
  Widget build(BuildContext context) {
    const types = [
      {'name': 'Casual Leave',  'quota': 12, 'color': Color(0xFF4F8EF7)},
      {'name': 'Sick Leave',    'quota': 10, 'color': Color(0xFFE05C5C)},
      {'name': 'Earned Leave',  'quota': 15, 'color': Color(0xFF3DB88B)},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Leave Balance (This Year)',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF718096))),
          const SizedBox(height: 10),
          Row(
            children: types.map((t) {
              final used      = _used(t['name'] as String);
              final quota     = t['quota'] as int;
              final remaining = (quota - used).clamp(0, quota);
              final color     = t['color'] as Color;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(t['name'].toString().split(' ').first,
                              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                          Text('$remaining/$quota',
                              style: TextStyle(fontSize: 10, color: color)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (used / quota).clamp(0.0, 1.0),
                          backgroundColor: color.withOpacity(0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Individual leave history card
class _LeaveCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _LeaveCard({required this.data});

  Color get _statusColor {
    switch (data['status']) {
      case 'approved': return const Color(0xFF3DB88B);
      case 'rejected': return const Color(0xFFE05C5C);
      default:         return const Color(0xFFFF9F43);
    }
  }

  String get _statusLabel {
    switch (data['status']) {
      case 'approved': return 'Approved';
      case 'rejected': return 'Rejected';
      default:         return 'Pending';
    }
  }

  IconData get _statusIcon {
    switch (data['status']) {
      case 'approved': return Icons.check_circle_rounded;
      case 'rejected': return Icons.cancel_rounded;
      default:         return Icons.hourglass_top_rounded;
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

  String get _typeShort {
    switch (data['leaveType']) {
      case 'Casual Leave':    return 'CL';
      case 'Sick Leave':      return 'SL';
      case 'Earned Leave':    return 'EL';
      case 'Maternity Leave': return 'ML';
      default:                return 'LOP';
    }
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is String)    return DateTime.tryParse(v);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final from      = _parseDate(data['fromDate']);
    final to        = _parseDate(data['toDate']);
    final applied   = _parseDate(data['appliedAt']);
    final days      = data['days'] ?? 1;
    final leaveType = data['leaveType'] ?? '';
    final reason    = data['reason'] ?? '';
    final status    = data['status'] ?? 'pending';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDF2F7)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // ── Top row
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: _typeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Text(_typeShort,
                      style: TextStyle(color: _typeColor, fontWeight: FontWeight.w700, fontSize: 13))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(leaveType,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1A202C))),
                      if (from != null && to != null)
                        Text(
                          '${DateFormat('dd MMM').format(from)} – ${DateFormat('dd MMM yyyy').format(to)}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF718096)),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _statusColor.withOpacity(0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statusIcon, size: 11, color: _statusColor),
                          const SizedBox(width: 4),
                          Text(_statusLabel,
                              style: TextStyle(color: _statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('$days day${days > 1 ? 's' : ''}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF718096))),
                  ],
                ),
              ],
            ),
          ),

          // ── Bottom details
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFF7FAFC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
              border: Border(top: BorderSide(color: Color(0xFFEDF2F7))),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (reason.isNotEmpty) ...[
                  Text(reason, style: const TextStyle(fontSize: 13, color: Color(0xFF4A5568))),
                  const SizedBox(height: 4),
                ],
                if (applied != null)
                  Text(
                    'Applied: ${DateFormat('dd MMM yyyy, hh:mm a').format(applied)}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFFA0AEC0)),
                  ),

                // Approved note
                if (status == 'approved') ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FFF4),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: const Color(0xFF9AE6B4)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.check_circle_outline_rounded, size: 13, color: Color(0xFF3DB88B)),
                        SizedBox(width: 6),
                        Text('Your leave has been approved by Admin',
                            style: TextStyle(fontSize: 12, color: Color(0xFF276749))),
                      ],
                    ),
                  ),
                ],

                // Rejection reason
                if (status == 'rejected' && data['rejectionReason'] != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5F5),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: const Color(0xFFFEB2B2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFFE05C5C)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Rejected: ${data['rejectionReason']}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF742A2A)),
                          ),
                        ),
                      ],
                    ),
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