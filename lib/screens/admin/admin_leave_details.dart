// lib/screens/admin/admin_leave_approval_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../app_config.dart'; // ✅ Import AppConfig

class AdminLeaveApprovalScreen extends StatefulWidget {
  const AdminLeaveApprovalScreen({Key? key}) : super(key: key);

  @override
  State<AdminLeaveApprovalScreen> createState() => _AdminLeaveApprovalScreenState();
}

class _AdminLeaveApprovalScreenState extends State<AdminLeaveApprovalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Pending', 'Approved', 'Rejected', 'All'];
  String? _schoolId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadSchoolId();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ✅ Load school ID from AppConfig
  Future<void> _loadSchoolId() async {
    if (AppConfig.schoolId.isNotEmpty) {
      setState(() {
        _schoolId = AppConfig.schoolId;
      });
      return;
    }

    // Fallback: Get from user document
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = userDoc.data();
      final schoolId = data?['schoolId'] ?? data?['school'] ?? data?['school_id'];
      if (schoolId != null) {
        setState(() {
          _schoolId = schoolId.toString();
        });
      }
    } catch (e) {
      print('Error loading school ID: $e');
    }
  }

  // ✅ Build query using collection group
  Query _buildQuery(String tab) {
    if (_schoolId == null) {
      return FirebaseFirestore.instance
          .collectionGroup('leave_requests')
          .where('schoolId', isEqualTo: 'nonexistent');
    }

    Query query = FirebaseFirestore.instance
        .collectionGroup('leave_requests')
        .where('schoolId', isEqualTo: _schoolId)
        .orderBy('appliedAt', descending: true);

    if (tab != 'All') {
      final statusMap = {
        'Pending': 'pending',
        'Approved': 'approved',
        'Rejected': 'rejected',
      };
      query = query.where('status', isEqualTo: statusMap[tab] ?? tab.toLowerCase());
    }

    return query;
  }

  // ✅ Update status with correct path using AppConfig
  Future<void> _updateStatus(String docId, String status, String teacherName, String teacherId) async {
    try {
      if (_schoolId == null) throw Exception('School ID not found');

      final docRef = FirebaseFirestore.instance
          .collection(AppConfig.schoolsCollection)
          .doc(_schoolId)
          .collection(AppConfig.teachersCollection)
          .doc(teacherId)
          .collection('leave_requests')
          .doc(docId);

      final Map<String, Object> updateData = {
        'status': status.toLowerCase(),
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (status == 'Approved') {
        updateData['approvedAt'] = FieldValue.serverTimestamp();
        updateData['approvedBy'] = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      } else if (status == 'Rejected') {
        updateData['rejectedAt'] = FieldValue.serverTimestamp();
        updateData['rejectedBy'] = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      }

      await docRef.update(updateData);

      // Send notification
      await _sendNotification(
        teacherId: teacherId,
        title: status == 'Approved' ? '✅ Leave Approved' : '❌ Leave Rejected',
        body: status == 'Approved'
            ? 'Your leave request has been approved.'
            : 'Your leave request was rejected. Please contact admin for details.',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$teacherName\'s leave $status'),
          backgroundColor: status == 'Approved' ? const Color(0xFF3DB88B) : const Color(0xFFE05C5C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _sendNotification({
    required String teacherId,
    required String title,
    required String body,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': teacherId,
        'title': title,
        'body': body,
        'type': 'leave_response',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Notification error: $e');
    }
  }

  Future<void> _showConfirmDialog(
      String docId,
      String status,
      String teacherName,
      String teacherId,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          status == 'Approved' ? '✅ Approve Leave?' : '❌ Reject Leave?',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Text(
          status == 'Approved'
              ? 'Approve leave request from $teacherName?'
              : 'Reject leave request from $teacherName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'Approved' ? const Color(0xFF3DB88B) : const Color(0xFFE05C5C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(status),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _updateStatus(docId, status, teacherName, teacherId);
    }
  }

  Color _leaveTypeColor(String type) {
    switch (type) {
      case 'Casual Leave': return const Color(0xFF4F8EF7);
      case 'Sick Leave': return const Color(0xFFE05C5C);
      case 'Earned Leave': return const Color(0xFF3DB88B);
      case 'Maternity Leave': return const Color(0xFFB47FEB);
      default: return const Color(0xFFFF9F43);
    }
  }

  String _leaveShort(String type) {
    switch (type) {
      case 'Casual Leave': return 'CL';
      case 'Sick Leave': return 'SL';
      case 'Earned Leave': return 'EL';
      case 'Maternity Leave': return 'ML';
      default: return 'LOP';
    }
  }

  DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3C6E),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Leave Requests',
            style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: _schoolId == null
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF1A3C6E)),
            SizedBox(height: 16),
            Text('Loading school data...',
                style: TextStyle(color: Color(0xFF718096))),
          ],
        ),
      )
          : _buildLeaveList(),
    );
  }

  Widget _buildLeaveList() {
    return TabBarView(
      controller: _tabController,
      children: _tabs.map((tab) {
        return StreamBuilder<QuerySnapshot>(
          stream: _buildQuery(tab).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF1A3C6E)),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 56, color: Color(0xFFE05C5C)),
                    const SizedBox(height: 12),
                    const Text('Something went wrong',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
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
                    Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('No ${tab == 'All' ? '' : tab.toLowerCase()} requests',
                        style: const TextStyle(color: Color(0xFF718096), fontSize: 15)),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final doc = docs[i];
                final data = doc.data() as Map<String, dynamic>;

                final teacherName = data['teacherName'] ?? 'Teacher';
                final teacherId = data['teacherId'] ?? '';
                final type = data['leaveType'] ?? '';
                final from = _parseDate(data['fromDate']);
                final to = _parseDate(data['toDate']);
                final days = data['days'] ?? data['totalDays'] ?? 1;
                final reason = data['reason'] ?? '';
                final status = data['status'] ?? 'Pending';
                final appliedAt = _parseDate(data['appliedAt']);

                final displayStatus = status.toString().substring(0, 1).toUpperCase() +
                    status.toString().substring(1);

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFEDF2F7)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: _leaveTypeColor(type).withOpacity(0.12),
                              child: Text(
                                teacherName.isNotEmpty ? teacherName[0].toUpperCase() : 'T',
                                style: TextStyle(
                                  color: _leaveTypeColor(type),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(teacherName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: Color(0xFF2D3748))),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _leaveTypeColor(type).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          _leaveShort(type),
                                          style: TextStyle(
                                              color: _leaveTypeColor(type),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(type,
                                          style: const TextStyle(
                                              fontSize: 12, color: Color(0xFF718096))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '$days day${days > 1 ? 's' : ''}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: Color(0xFF2D3748)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF7FAFC),
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(14),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (from != null && to != null)
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded,
                                      size: 13, color: Color(0xFF718096)),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${DateFormat('dd MMM yyyy').format(from)} → ${DateFormat('dd MMM yyyy').format(to)}',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF4A5568),
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            if (reason.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(reason,
                                  style: const TextStyle(
                                      fontSize: 13, color: Color(0xFF718096))),
                            ],
                            if (appliedAt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Applied: ${DateFormat('dd MMM yyyy, hh:mm a').format(appliedAt)}',
                                style: const TextStyle(
                                    fontSize: 11, color: Color(0xFFA0AEC0)),
                              ),
                            ],
                            if (displayStatus != 'Pending') ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(
                                    displayStatus == 'Approved'
                                        ? Icons.check_circle_rounded
                                        : Icons.cancel_rounded,
                                    size: 15,
                                    color: displayStatus == 'Approved'
                                        ? const Color(0xFF3DB88B)
                                        : const Color(0xFFE05C5C),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    displayStatus,
                                    style: TextStyle(
                                      color: displayStatus == 'Approved'
                                          ? const Color(0xFF3DB88B)
                                          : const Color(0xFFE05C5C),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (displayStatus == 'Pending') ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _showConfirmDialog(
                                          doc.id, 'Rejected', teacherName, teacherId),
                                      icon: const Icon(Icons.close_rounded, size: 16),
                                      label: const Text('Reject'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFFE05C5C),
                                        side: const BorderSide(color: Color(0xFFE05C5C)),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _showConfirmDialog(
                                          doc.id, 'Approved', teacherName, teacherId),
                                      icon: const Icon(Icons.check_rounded, size: 16),
                                      label: const Text('Approve'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF3DB88B),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(vertical: 10),
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
              },
            );
          },
        );
      }).toList(),
    );
  }
}