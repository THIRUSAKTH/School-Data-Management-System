import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:schoolprojectjan/app_config.dart';

class ParentHomeworkViewPage extends StatefulWidget {
  final String? studentId;
  final String? className;
  final String? section;

  const ParentHomeworkViewPage({
    super.key,
    this.studentId,
    this.className,
    this.section,
  });

  @override
  State<ParentHomeworkViewPage> createState() => _ParentHomeworkViewPageState();
}

class _ParentHomeworkViewPageState extends State<ParentHomeworkViewPage> {
  String? _selectedStudentId;
  String? _studentClass;
  String? _studentSection;
  String? _studentName;
  bool _isLoading = true;
  List<QueryDocumentSnapshot> _childrenList = [];
  Timer? _autoDeleteTimer;

  // Auto-delete settings
  static const int _autoDeleteAfterDays =
      7; // Delete homework 7 days after due date

  @override
  void initState() {
    super.initState();
    _loadStudentData();
    _startAutoDeleteChecker();
  }

  @override
  void dispose() {
    _autoDeleteTimer?.cancel();
    super.dispose();
  }

  void _startAutoDeleteChecker() {
    // Check every 6 hours for expired homework to delete
    _autoDeleteTimer = Timer.periodic(const Duration(hours: 6), (timer) {
      _autoDeleteExpiredHomework();
    });
    // Also run once immediately
    _autoDeleteExpiredHomework();
  }

  Future<void> _autoDeleteExpiredHomework() async {
    if (_studentClass == null || _studentSection == null) return;

    try {
      final now = DateTime.now();
      final cutoffDate = now.subtract(
        const Duration(days: _autoDeleteAfterDays),
      );

      // Get all homework for this class/section
      final homeworkSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('homework')
              .where('className', isEqualTo: _studentClass)
              .where('section', isEqualTo: _studentSection)
              .where('isActive', isEqualTo: true)
              .get();

      final batch = FirebaseFirestore.instance.batch();
      int deletedCount = 0;

      for (var doc in homeworkSnapshot.docs) {
        final data = doc.data();
        final dueDate = data['dueDate'] as Timestamp?;

        if (dueDate != null) {
          final dueDateTime = dueDate.toDate();
          // Delete if due date is older than cutoff (completed or not)
          if (dueDateTime.isBefore(cutoffDate)) {
            // Soft delete - mark as inactive
            batch.update(doc.reference, {
              'isActive': false,
              'deletedAt': FieldValue.serverTimestamp(),
              'deletedReason':
                  'Auto-deleted after $_autoDeleteAfterDays days of due date',
            });
            deletedCount++;
          }
        }
      }

      if (deletedCount > 0) {
        await batch.commit();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$deletedCount old homework(s) auto-deleted'),
              backgroundColor: Colors.grey,
              duration: const Duration(seconds: 2),
            ),
          );
          setState(() {}); // Refresh the list
        }
      }
    } catch (e) {
      debugPrint('Error in auto-delete: $e');
    }
  }

  Future<void> _deleteHomeworkPermanently(
    String homeworkId,
    String title,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text("Delete Homework"),
            content: Text(
              "Are you sure you want to hide this homework?\n\n\"$title\"\n\nThis will hide it from your view only. The school can still access it.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text("Hide from My View"),
              ),
            ],
          ),
    );

    if (shouldDelete == true) {
      try {
        // Soft delete - hide from parent view only
        await FirebaseFirestore.instance
            .collection('schools')
            .doc(AppConfig.schoolId)
            .collection('homework')
            .doc(homeworkId)
            .update({
              'hiddenForParent_${_selectedStudentId}': true,
              'hiddenByParentAt': FieldValue.serverTimestamp(),
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Homework hidden from your view"),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
          setState(() {}); // Refresh the list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _loadStudentData() async {
    if (!mounted) return;

    try {
      final parentUid = FirebaseAuth.instance.currentUser!.uid;

      final studentsSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('students')
              .where('parentUid', isEqualTo: parentUid)
              .get();

      _childrenList = studentsSnapshot.docs;

      if (_childrenList.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      QueryDocumentSnapshot targetStudent;

      if (widget.studentId != null && widget.studentId!.isNotEmpty) {
        try {
          targetStudent = _childrenList.firstWhere(
            (s) => s.id == widget.studentId!,
          );
        } catch (e) {
          targetStudent = _childrenList.first;
        }
      } else {
        targetStudent = _childrenList.first;
      }

      final data = targetStudent.data() as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          _selectedStudentId = targetStudent.id;
          _studentClass = widget.className ?? data['class'];
          _studentSection = widget.section ?? data['section'];
          _studentName = data['name'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading student data: $e');
      if (mounted) setState(() => _isLoading = false);
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
              "Homework",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_studentName != null)
              Text(_studentName!, style: const TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: "Refresh",
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _selectedStudentId == null
              ? _buildNoChildrenWidget()
              : Column(
                children: [
                  if (_childrenList.length > 1) _buildChildSelector(),
                  Expanded(child: _buildHomeworkList()),
                ],
              ),
    );
  }

  Widget _buildNoChildrenWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Children Linked',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please contact the school admin to link your children.',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildChildSelector() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          const SizedBox(width: 12),
          const Text(
            "Child:",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedStudentId,
                hint: const Text("Select Child"),
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.orange),
                items:
                    _childrenList.map((student) {
                      final data = student.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: student.id,
                        child: Text(
                          data['name'] ?? 'Student',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }).toList(),
                onChanged: (value) async {
                  if (value == null) return;
                  setState(() => _isLoading = true);
                  final student = _childrenList.firstWhere(
                    (s) => s.id == value,
                  );
                  final data = student.data() as Map<String, dynamic>;
                  setState(() {
                    _selectedStudentId = value;
                    _studentClass = data['class'];
                    _studentSection = data['section'];
                    _studentName = data['name'];
                    _isLoading = false;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeworkList() {
    if (_studentClass == null || _studentSection == null) {
      return const Center(child: Text("Unable to load homework"));
    }

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('homework')
              .where('className', isEqualTo: _studentClass)
              .where('section', isEqualTo: _studentSection)
              .where('isActive', isEqualTo: true)
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
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  "Error: ${snapshot.error}",
                  style: const TextStyle(color: Colors.grey),
                ),
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_turned_in,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Homework Assigned',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back later for updates',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        // Filter out homework hidden by this parent
        var homeworkList =
            snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final hiddenKey = 'hiddenForParent_${_selectedStudentId}';
              return data[hiddenKey] != true;
            }).toList();

        if (homeworkList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 80,
                  color: Colors.green.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'All Done!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No pending homework',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        // Client-side sorting: Urgent first, then by due date
        homeworkList.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aUrgent = aData['isUrgent'] ?? false;
          final bUrgent = bData['isUrgent'] ?? false;
          if (aUrgent != bUrgent) return aUrgent ? -1 : 1;

          final aDate = aData['dueDate'] as Timestamp?;
          final bDate = bData['dueDate'] as Timestamp?;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return aDate.toDate().compareTo(bDate.toDate());
        });

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: homeworkList.length,
            itemBuilder: (context, index) {
              final doc = homeworkList[index];
              final data = doc.data() as Map<String, dynamic>;
              final attachments = data['attachments'] as List? ?? [];
              final dueDate = data['dueDate'] as Timestamp?;
              final isOverdue =
                  dueDate != null && dueDate.toDate().isBefore(DateTime.now());
              final daysOverdue =
                  isOverdue && dueDate != null
                      ? DateTime.now().difference(dueDate.toDate()).inDays
                      : 0;

              return GestureDetector(
                onLongPress:
                    () => _deleteHomeworkPermanently(
                      doc.id,
                      data['title'] ?? 'Homework',
                    ),
                child: _HomeworkCard(
                  homeworkId: doc.id,
                  subject: data['subject'] ?? 'General',
                  description: data['description'] ?? 'No description',
                  dueDate: dueDate,
                  dueTime: data['dueTime'],
                  isUrgent: data['isUrgent'] ?? false,
                  studentId: _selectedStudentId!,
                  teacherName: data['teacherName'] ?? 'Teacher',
                  attachments: attachments,
                  isOverdue: isOverdue,
                  daysOverdue: daysOverdue,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// Homework Card Widget
class _HomeworkCard extends StatefulWidget {
  final String homeworkId;
  final String subject;
  final String description;
  final Timestamp? dueDate;
  final String? dueTime;
  final bool isUrgent;
  final String studentId;
  final String teacherName;
  final List<dynamic> attachments;
  final bool isOverdue;
  final int daysOverdue;

  const _HomeworkCard({
    required this.homeworkId,
    required this.subject,
    required this.description,
    required this.dueDate,
    required this.dueTime,
    required this.isUrgent,
    required this.studentId,
    required this.teacherName,
    required this.attachments,
    this.isOverdue = false,
    this.daysOverdue = 0,
  });

  @override
  State<_HomeworkCard> createState() => _HomeworkCardState();
}

class _HomeworkCardState extends State<_HomeworkCard> {
  bool _isSubmitting = false;
  bool _isExpanded = false;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkSubmissionStatus();
  }

  Future<void> _checkSubmissionStatus() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('homework')
              .doc(widget.homeworkId)
              .get();

      if (doc.exists) {
        final submittedBy = doc.data()?['submittedBy'] as List<dynamic>? ?? [];
        if (mounted) {
          setState(() {
            _isCompleted = submittedBy.contains(widget.studentId);
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking submission: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final status =
        _isCompleted ? "Completed" : (widget.isOverdue ? "Overdue" : "Pending");

    Color getStatusColor() {
      if (_isCompleted) return Colors.green;
      if (widget.isOverdue) return Colors.red;
      return Colors.orange;
    }

    IconData getStatusIcon() {
      if (_isCompleted) return Icons.check_circle;
      if (widget.isOverdue) return Icons.warning_amber;
      return Icons.schedule;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Auto-delete warning banner for overdue
              if (widget.isOverdue && !_isCompleted && widget.daysOverdue >= 5)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, size: 16, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "This homework will be auto-deleted in ${7 - widget.daysOverdue} days",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (widget.isUrgent)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.priority_high,
                        size: 14,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "URGENT",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.subject,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        "Due: ${_formatDate(widget.dueDate)}",
                        style: TextStyle(
                          fontSize: 11,
                          color: widget.isOverdue ? Colors.red : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          getStatusIcon(),
                          size: 12,
                          color: getStatusColor(),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          status,
                          style: TextStyle(
                            fontSize: 10,
                            color: getStatusColor(),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    "Long press to hide",
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
                maxLines: _isExpanded ? null : 3,
                overflow:
                    _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
              if (widget.description.length > 120)
                TextButton(
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 30),
                  ),
                  child: Text(
                    _isExpanded ? "Read less" : "Read more",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 12, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    "Posted by: ${widget.teacherName}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              if (widget.attachments.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  "Attachments:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      widget.attachments
                          .map((attachment) => _buildAttachmentChip(attachment))
                          .toList(),
                ),
              ],
              const SizedBox(height: 16),
              if (!_isCompleted && !widget.isOverdue)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitHomework,
                    icon:
                        _isSubmitting
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(Icons.check, size: 18),
                    label: Text(
                      _isSubmitting ? "Submitting..." : "Mark as Completed",
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              if (_isCompleted)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Great job! You've completed this homework.",
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (widget.isOverdue && !_isCompleted)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "This homework is overdue. Please contact your teacher.",
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentChip(Map<String, dynamic> attachment) {
    final isImage = attachment['type'] == 'image';
    final fileName = attachment['originalName'] ?? attachment['name'];

    return GestureDetector(
      onTap: () => _showAttachmentPreview(attachment),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isImage ? Colors.green.shade50 : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isImage ? Colors.green.shade200 : Colors.blue.shade200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isImage ? Icons.image : Icons.insert_drive_file,
              size: 14,
              color: isImage ? Colors.green : Colors.blue,
            ),
            const SizedBox(width: 6),
            Text(
              fileName.length > 20
                  ? '${fileName.substring(0, 17)}...'
                  : fileName,
              style: TextStyle(
                fontSize: 12,
                color: isImage ? Colors.green.shade700 : Colors.blue.shade700,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.visibility,
              size: 12,
              color: isImage ? Colors.green : Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentPreview(Map<String, dynamic> attachment) {
    final isImage = attachment['type'] == 'image';
    final url = attachment['url'];
    final fileName = attachment['originalName'] ?? attachment['name'];

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isImage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        url,
                        fit: BoxFit.contain,
                        height: 300,
                        errorBuilder:
                            (_, __, ___) => Container(
                              height: 200,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.insert_drive_file,
                            size: 48,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            fileName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Close"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Download feature coming soon"),
                                ),
                              ),
                          icon: const Icon(Icons.download),
                          label: const Text("Download"),
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
            ),
          ),
    );
  }

  Future<void> _submitHomework() async {
    setState(() => _isSubmitting = true);

    try {
      final homeworkRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('homework')
          .doc(widget.homeworkId);

      await homeworkRef.update({
        'submittedBy': FieldValue.arrayUnion([widget.studentId]),
      });

      if (mounted) {
        setState(() => _isCompleted = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Homework marked as completed! 🎉"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'No due date';
    return DateFormat('dd MMM yyyy').format(timestamp.toDate());
  }
}
