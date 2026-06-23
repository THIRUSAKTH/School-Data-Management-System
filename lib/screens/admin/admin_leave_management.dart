// lib/screens/admin/admin_leave_management.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';  // ✅ ADDED: For HapticFeedback
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'admin_leave_details.dart';

class AdminLeaveManagement extends StatefulWidget {
  const AdminLeaveManagement({Key? key}) : super(key: key);

  @override
  _AdminLeaveManagementState createState() => _AdminLeaveManagementState();
}

class _AdminLeaveManagementState extends State<AdminLeaveManagement> {
  String _selectedFilter = 'pending';
  int _pendingCount = 0;
  int _totalCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 Leave Management'),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Statistics Row
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatChip('🔄 Pending', _pendingCount, Colors.orange),
                        _buildStatChip('✅ Approved', null, Colors.green),
                        _buildStatChip('❌ Rejected', null, Colors.red),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterTab('Pending', 'pending'),
                _buildFilterTab('All', 'all'),
                _buildFilterTab('Approved', 'approved'),
                _buildFilterTab('Rejected', 'rejected'),
              ],
            ),
          ),

          // Leave Requests List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getLeaveStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text(
                          'Error loading leave requests',
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(snapshot.error.toString()),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading leave requests...'),
                      ],
                    ),
                  );
                }

                final requests = snapshot.data!.docs;
                _pendingCount = requests.where((doc) => doc['status'] == 'pending').length;
                _totalCount = requests.length;

                if (requests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_note,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedFilter == 'pending'
                              ? '🎉 No pending leave requests'
                              : 'No leave requests found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_selectedFilter == 'pending')
                          Text(
                            'All teachers are present! 👍',
                            style: TextStyle(
                              color: Colors.grey[400],
                            ),
                          ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final doc = requests[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildLeaveCard(doc.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int? count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, String filter) {
    final isSelected = _selectedFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = filter;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[100] : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey[300]!,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.blue[700] : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _getLeaveStream() {
    Query query = FirebaseFirestore.instance
        .collection('leave_requests')
        .orderBy('appliedAt', descending: true);

    if (_selectedFilter != 'all') {
      query = query.where('status', isEqualTo: _selectedFilter);
    }

    return query.snapshots();
  }

  Widget _buildLeaveCard(String docId, Map<String, dynamic> data) {
    final status = data['status'] ?? 'pending';
    final statusColor = status == 'pending'
        ? Colors.orange
        : status == 'approved'
        ? Colors.green
        : status == 'rejected'
        ? Colors.red
        : Colors.grey;

    final statusIcon = status == 'pending'
        ? Icons.hourglass_top
        : status == 'approved'
        ? Icons.check_circle
        : status == 'rejected'
        ? Icons.cancel
        : Icons.block;

    final fromDate = DateTime.parse(data['fromDate']);
    final toDate = DateTime.parse(data['toDate']);
    final appliedAt = DateTime.parse(data['appliedAt']);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Show call-style popup for pending requests
          if (status == 'pending') {
            _showCallStyleApprovalPopup(docId, data);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminLeaveDetails(
                  requestId: docId,
                  data: data,
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Icon(
                      Icons.person,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['teacherName'] ?? 'Unknown Teacher',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${data['teacherClass'] ?? 'N/A'} • ${data['teacherSubject'] ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Leave Details
              Row(
                children: [
                  Icon(Icons.event_note, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${data['leaveType']} • ${data['days']} day${data['days'] > 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat('dd MMM yyyy').format(fromDate)} - ${DateFormat('dd MMM yyyy').format(toDate)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Applied: ${DateFormat('dd MMM yyyy, HH:mm').format(appliedAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              if (data['reason'] != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.description, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          data['reason'],
                          style: const TextStyle(fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (data['documentUrl'] != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.attach_file, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text(
                      '📎 Attachment available',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
              if (status == 'pending') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showCallStyleApprovalPopup(docId, data),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showRejectDialog(docId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Show Call-Style Approval Popup
  void _showCallStyleApprovalPopup(String docId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: CallStyleApprovalPopup(
          docId: docId,
          data: data,
          onApprove: () {
            _approveLeave(docId);
          },
          onReject: () {
            _showRejectDialog(docId);
          },
        ),
      ),
    );
  }

  // Approve leave
  Future<void> _approveLeave(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('leave_requests').doc(docId).update({
        'status': 'approved',
        'approvedBy': FirebaseAuth.instance.currentUser!.uid,
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Get teacher ID for notification
      final doc = await FirebaseFirestore.instance
          .collection('leave_requests')
          .doc(docId)
          .get();
      final teacherId = doc.data()?['teacherId'];

      // Send notification
      if (teacherId != null) {
        await _sendTeacherNotification(
          teacherId: teacherId,
          title: '✅ Leave Approved',
          body: 'Your leave request has been approved by Admin.',
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Leave approved successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pop(context); // Close dialog
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to approve: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show reject dialog
  void _showRejectDialog(String docId) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('❌ Reject Leave Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter rejection reason...',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              _rejectLeave(docId, reason);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  // Reject leave
  Future<void> _rejectLeave(String docId, String reason) async {
    try {
      await FirebaseFirestore.instance.collection('leave_requests').doc(docId).update({
        'status': 'rejected',
        'rejectionReason': reason,
        'rejectedBy': FirebaseAuth.instance.currentUser!.uid,
        'rejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Get teacher ID for notification
      final doc = await FirebaseFirestore.instance
          .collection('leave_requests')
          .doc(docId)
          .get();
      final teacherId = doc.data()?['teacherId'];

      // Send notification
      if (teacherId != null) {
        await _sendTeacherNotification(
          teacherId: teacherId,
          title: '❌ Leave Rejected',
          body: 'Your leave request was rejected. Reason: $reason',
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Leave rejected'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );

      // Close call popup if open
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Send notification to teacher
  Future<void> _sendTeacherNotification({
    required String teacherId,
    required String title,
    required String body,
  }) async {
    try {
      final teacherDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(teacherId)
          .get();

      final fcmToken = teacherDoc.data()?['fcmToken'];

      if (fcmToken != null && fcmToken.isNotEmpty) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': teacherId,
          'title': title,
          'body': body,
          'type': 'leave_response',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Failed to send notification: $e');
    }
  }
}

// ============================================================
// CALL STYLE APPROVAL POPUP WIDGET
// ============================================================
class CallStyleApprovalPopup extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const CallStyleApprovalPopup({
    Key? key,
    required this.docId,
    required this.data,
    required this.onApprove,
    required this.onReject,
  }) : super(key: key);

  @override
  _CallStyleApprovalPopupState createState() => _CallStyleApprovalPopupState();
}

class _CallStyleApprovalPopupState extends State<CallStyleApprovalPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Phone call pulse animation
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Vibrate for incoming call effect
    HapticFeedback.heavyImpact();  // ✅ Now works with the import
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fromDate = DateTime.parse(widget.data['fromDate']);
    final toDate = DateTime.parse(widget.data['toDate']);
    final appliedAt = DateTime.parse(widget.data['appliedAt']);

    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '📞 Incoming Request',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'PENDING',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Animated Phone Icon
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.withOpacity(0.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(_glowAnimation.value * 0.5),
                        blurRadius: 50,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(30.0),
                    child: Icon(
                      Icons.phone_in_talk,
                      color: Colors.white,
                      size: 70,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Teacher Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.data['teacherName'] ?? 'Unknown Teacher',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.data['teacherClass'] ?? 'N/A'} • ${widget.data['teacherSubject'] ?? 'N/A'}',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Available Balance: 10 days',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Leave Details
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDetailItem('📋', widget.data['leaveType'] ?? 'N/A'),
                        _buildDetailItem('⏱️', '${widget.data['days']} days'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDetailItem('📅', DateFormat('dd MMM').format(fromDate)),
                        _buildDetailItem('📅', DateFormat('dd MMM').format(toDate)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.description, size: 16, color: Colors.white70),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.data['reason'] ?? 'No reason provided',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.data['documentUrl'] != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.attach_file, size: 16, color: Colors.blue[300]),
                          const SizedBox(width: 8),
                          const Text(
                            '📎 Document attached',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Applied: ${DateFormat('dd MMM yyyy, HH:mm').format(appliedAt)}',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons - Call Style
              Row(
                children: [
                  // Reject Button (Red - End Call)
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        widget.onReject();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.call_end, color: Colors.white, size: 30),
                            SizedBox(height: 4),
                            Text(
                              'REJECT',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),

                  // Approve Button (Green - Accept Call)
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        widget.onApprove();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.call, color: Colors.white, size: 30),
                            SizedBox(height: 4),
                            Text(
                              'APPROVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Snooze Button
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⏰ Reminder set for 30 minutes'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                child: const Text(
                  '⏰ Snooze (Remind in 30 min)',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String icon, String text) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}