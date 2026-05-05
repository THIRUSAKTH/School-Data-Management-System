import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:schoolprojectjan/app_config.dart';

class ParentNotificationsPage extends StatefulWidget {
  final String? studentId;

  const ParentNotificationsPage({super.key, this.studentId});

  @override
  State<ParentNotificationsPage> createState() =>
      _ParentNotificationsPageState();
}

class _ParentNotificationsPageState extends State<ParentNotificationsPage> {
  String? _selectedStudentId;
  String? _selectedStudentName;
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  bool _isMarkingAll = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final parentUid = FirebaseAuth.instance.currentUser!.uid;
      final snapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('students')
              .where('parentUid', isEqualTo: parentUid)
              .get();

      _students =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'name': data['name'] ?? 'Student',
              'class': data['class'] ?? '',
              'section': data['section'] ?? '',
            };
          }).toList();

      if (_students.isNotEmpty) {
        if (widget.studentId != null) {
          final matchingStudent = _students.firstWhere(
            (s) => s['id'] == widget.studentId,
            orElse: () => _students.first,
          );
          _selectedStudentId = matchingStudent['id'];
          _selectedStudentName = matchingStudent['name'];
        } else {
          _selectedStudentId = _students.first['id'];
          _selectedStudentName = _students.first['name'];
        }
      } else {
        _errorMessage =
            "No students linked to your account. Please contact school admin.";
      }
    } catch (e) {
      debugPrint('Error loading students: $e');
      _errorMessage = "Error loading students. Please try again.";
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Notifications",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_selectedStudentName != null)
              Text(_selectedStudentName!, style: const TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_selectedStudentId != null)
            IconButton(
              icon:
                  _isMarkingAll
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Icon(Icons.mark_email_read),
              onPressed: _isMarkingAll ? null : _markAllAsRead,
              tooltip: "Mark all as read",
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudents,
            tooltip: "Refresh",
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? _buildErrorWidget()
              : _students.isEmpty
              ? _buildNoStudentsWidget()
              : Column(
                children: [
                  if (_students.length > 1) _buildStudentSelector(),
                  Expanded(child: _buildNotificationsList()),
                ],
              ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadStudents,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoStudentsWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No Children Linked',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please contact the school admin to link your children.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentSelector() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.switch_account, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          const Text(
            "Child:",
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedStudentId,
                hint: const Text("Select Child"),
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.orange),
                items:
                    _students.map<DropdownMenuItem<String>>((student) {
                      return DropdownMenuItem<String>(
                        value: student['id'] as String,
                        child: Text(
                          "${student['name']} (${student['class']} - ${student['section']})",
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedStudentId = value;
                    final selected = _students.firstWhere(
                      (s) => s['id'] == value,
                    );
                    _selectedStudentName = selected['name'];
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('notifications')
              .where('studentId', isEqualTo: _selectedStudentId)
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                const SizedBox(height: 16),
                const Text("Error loading notifications"),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text("Retry"),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No notifications'),
              ],
            ),
          );
        }

        final parentUid = FirebaseAuth.instance.currentUser!.uid;
        final notifications =
            snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final List<dynamic> deletedFor =
                  data['deletedFor'] as List? ?? [];
              return !deletedFor.contains(parentUid);
            }).toList();

        if (notifications.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No notifications'),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final data = notification.data() as Map<String, dynamic>;
              return _buildNotificationCard(notification.id, data);
            },
          ),
        );
      },
    );
  }

  Widget _buildNotificationCard(
    String notificationId,
    Map<String, dynamic> data,
  ) {
    final bool isRead = (data['isRead'] ?? false) as bool;
    final String type = (data['type'] ?? 'general').toString();
    final String title = (data['title'] ?? 'Notification').toString();
    final String message = (data['message'] ?? '').toString();
    final typeConfig = _getTypeConfig(type);

    return Dismissible(
      key: Key(notificationId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Text("Remove Notification"),
                content: const Text(
                  "This notification will be removed only for you.",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text("Remove"),
                  ),
                ],
              ),
        );
      },
      onDismissed: (direction) async {
        await _softDeleteNotification(notificationId);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color:
              isRead
                  ? Colors.white
                  : (typeConfig['color'] as Color).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              if (!isRead) {
                await _markAsRead(notificationId);
              }
              _showNotificationDetail(data);
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: (typeConfig['color'] as Color).withOpacity(
                      0.1,
                    ),
                    child: Icon(
                      typeConfig['icon'] as IconData,
                      color: typeConfig['color'] as Color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(data['createdAt']),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      _showNotificationDetail(data);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _markAllAsRead() async {
    if (_selectedStudentId == null) return;

    setState(() => _isMarkingAll = true);

    try {
      final parentUid = FirebaseAuth.instance.currentUser!.uid;

      final notifications =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('notifications')
              .where('studentId', isEqualTo: _selectedStudentId)
              .get();

      final batch = FirebaseFirestore.instance.batch();
      int updatedCount = 0;

      for (var doc in notifications.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final isRead = data['isRead'] == true;
        final List<dynamic> deletedFor = data['deletedFor'] as List? ?? [];
        final isDeletedForParent = deletedFor.contains(parentUid);

        if (!isRead && !isDeletedForParent) {
          batch.update(doc.reference, {
            'isRead': true,
            'readAt': FieldValue.serverTimestamp(),
          });
          updatedCount++;
        }
      }

      if (updatedCount > 0) {
        await batch.commit();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "$updatedCount notification${updatedCount != 1 ? 's' : ''} marked as read",
              ),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {});
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No unread notifications"),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error marking notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isMarkingAll = false);
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true, 'readAt': FieldValue.serverTimestamp()});
      setState(() {});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _softDeleteNotification(String notificationId) async {
    try {
      final parentUid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('notifications')
          .doc(notificationId)
          .update({
            'deletedFor': FieldValue.arrayUnion([parentUid]),
            'deletedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Notification removed"),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Map<String, dynamic> _getTypeConfig(String type) {
    switch (type) {
      case 'homework':
        return {
          'icon': Icons.assignment,
          'color': Colors.blue,
          'label': 'Homework',
        };
      case 'notice':
        return {
          'icon': Icons.announcement,
          'color': Colors.orange,
          'label': 'Notice',
        };
      case 'fee':
        return {
          'icon': Icons.currency_rupee,
          'color': Colors.green,
          'label': 'Fee',
        };
      case 'attendance':
        return {
          'icon': Icons.check_circle,
          'color': Colors.green,
          'label': 'Attendance',
        };
      case 'complaint':
        return {
          'icon': Icons.feedback,
          'color': Colors.purple,
          'label': 'Complaint',
        };
      default:
        return {
          'icon': Icons.notifications,
          'color': Colors.grey,
          'label': 'General',
        };
    }
  }

  void _showNotificationDetail(Map<String, dynamic> data) {
    final String title = (data['title'] ?? 'Notification').toString();
    final String message = (data['message'] ?? '').toString();
    final String type = (data['type'] ?? 'general').toString();
    final typeConfig = _getTypeConfig(type);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder:
                (context, scrollController) => Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: (typeConfig['color'] as Color)
                                .withOpacity(0.1),
                            child: Icon(
                              typeConfig['icon'] as IconData,
                              color: typeConfig['color'] as Color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  typeConfig['label'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: typeConfig['color'] as Color,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatFullTime(data['createdAt']),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Close"),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'Recently';
    if (timestamp is Timestamp) {
      final DateTime date = timestamp.toDate();
      final DateTime now = DateTime.now();
      final Duration diff = now.difference(date);

      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    }
    return 'Recently';
  }

  String _formatFullTime(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    if (timestamp is Timestamp) {
      return DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate());
    }
    return 'Unknown';
  }
}
