import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:schoolprojectjan/app_config.dart';

class HomeworkViewPage extends StatefulWidget {
  final String? studentId;
  final String? className;
  final String? section;

  const HomeworkViewPage({
    super.key,
    this.studentId,
    this.className,
    this.section,
  });

  @override
  State<HomeworkViewPage> createState() => _HomeworkViewPageState();
}

class _HomeworkViewPageState extends State<HomeworkViewPage> {
  String? _selectedStudentId;
  String? _studentClass;
  String? _studentSection;
  String? _studentName;
  bool _isLoading = true;
  List<QueryDocumentSnapshot> _childrenList = [];

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
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
      setState(() => _isLoading = false);
      return;
    }

    // Find the target student
    QueryDocumentSnapshot targetStudent;

    if (widget.studentId != null && widget.studentId!.isNotEmpty) {
      try {
        targetStudent = _childrenList.firstWhere(
              (s) => s.id == widget.studentId!,
        );
      } catch (e) {
        // If specified student not found, use first child
        targetStudent = _childrenList.first;
      }
    } else {
      targetStudent = _childrenList.first;
    }

    final data = targetStudent.data() as Map<String, dynamic>;

    setState(() {
      _selectedStudentId = targetStudent.id;
      _studentClass = widget.className ?? data['class'];
      _studentSection = widget.section ?? data['section'];
      _studentName = data['name'];
      _isLoading = false;
    });
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
          .orderBy('dueDate', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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

        final homeworkList = snapshot.data!.docs;

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: homeworkList.length,
            itemBuilder: (context, index) {
              final doc = homeworkList[index];
              final data = doc.data() as Map<String, dynamic>;

              Timestamp? dueTimestamp;
              if (data['dueDate'] is Timestamp) {
                dueTimestamp = data['dueDate'] as Timestamp;
              }

              return _HomeworkCard(
                homeworkId: doc.id,
                subject: data['subject'] ?? 'General',
                description: data['description'] ?? 'No description',
                dueDate: dueTimestamp,
                dueTime: data['dueTime'],
                isUrgent: data['isUrgent'] ?? false,
                status: _getHomeworkStatus(data),
                studentId: _selectedStudentId!,
                attachments: data['attachments'] ?? [],
                teacherName: data['teacherName'] ?? 'Teacher',
              );
            },
          ),
        );
      },
    );
  }

  String _getHomeworkStatus(Map<String, dynamic> data) {
    final submittedBy = data['submittedBy'] as List<dynamic>? ?? [];
    if (_selectedStudentId != null &&
        submittedBy.contains(_selectedStudentId)) {
      return "Submitted";
    }

    final dueDate = data['dueDate'];
    if (dueDate != null) {
      DateTime dueDateTime;
      if (dueDate is Timestamp) {
        dueDateTime = dueDate.toDate();
      } else if (dueDate is String) {
        dueDateTime = DateTime.parse(dueDate);
      } else {
        dueDateTime = DateTime.now().subtract(const Duration(days: 1));
      }

      if (dueDateTime.isBefore(DateTime.now())) {
        return "Overdue";
      }
    }

    return "Pending";
  }
}

// ============================================================
// HOMEWORK CARD
// ============================================================

class _HomeworkCard extends StatefulWidget {
  final String homeworkId;
  final String subject;
  final String description;
  final Timestamp? dueDate;
  final String? dueTime;
  final bool isUrgent;
  final String status;
  final String studentId;
  final List<dynamic> attachments;
  final String teacherName;

  const _HomeworkCard({
    required this.homeworkId,
    required this.subject,
    required this.description,
    required this.dueDate,
    required this.dueTime,
    required this.isUrgent,
    required this.status,
    required this.studentId,
    required this.attachments,
    required this.teacherName,
  });

  @override
  State<_HomeworkCard> createState() => _HomeworkCardState();
}

class _HomeworkCardState extends State<_HomeworkCard> {
  bool _isSubmitting = false;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isSubmitted = widget.status == "Submitted";
    final isOverdue = widget.status == "Overdue";

    Color getStatusColor() {
      if (isSubmitted) return Colors.green;
      if (isOverdue) return Colors.red;
      return Colors.orange;
    }

    String getStatusText() {
      if (isSubmitted) return "Submitted";
      if (isOverdue) return "Overdue";
      return "Pending";
    }

    IconData getStatusIcon() {
      if (isSubmitted) return Icons.check_circle;
      if (isOverdue) return Icons.warning_amber;
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
              // Urgent Banner
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

              // Subject + Status
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
                          getStatusText(),
                          style: TextStyle(
                            fontSize: 10,
                            color: getStatusColor(),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Description
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

              // Read More/Less
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

              // Due Date & Time
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: isOverdue ? Colors.red : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Due: ${_formatDate(widget.dueDate)}",
                    style: TextStyle(
                      fontSize: 12,
                      color: isOverdue ? Colors.red : Colors.grey,
                      fontWeight:
                      isOverdue ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                  if (widget.dueTime != null) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.access_time, size: 12, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      widget.dueTime!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 8),

              // Teacher Name
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

              // Attachments
              if (widget.attachments.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
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

              // Submit Button
              if (!isSubmitted && !isOverdue)
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

              // Submitted Status
              if (isSubmitted)
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

              // Overdue Status
              if (isOverdue && !isSubmitted)
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
    final fileName = attachment['name'] ?? 'Attachment';
    final fileType = fileName.split('.').last.toLowerCase();

    IconData getFileIcon() {
      if (fileType == 'pdf') return Icons.picture_as_pdf;
      if (['jpg', 'jpeg', 'png', 'gif'].contains(fileType)) return Icons.image;
      if (['doc', 'docx'].contains(fileType)) return Icons.description;
      return Icons.attach_file;
    }

    Color getFileColor() {
      if (fileType == 'pdf') return Colors.red;
      if (['jpg', 'jpeg', 'png', 'gif'].contains(fileType)) return Colors.green;
      if (['doc', 'docx'].contains(fileType)) return Colors.blue;
      return Colors.grey;
    }

    return GestureDetector(
      onTap: () => _viewAttachment(attachment),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(getFileIcon(), size: 14, color: getFileColor()),
            const SizedBox(width: 6),
            Text(
              fileName.length > 20
                  ? '${fileName.substring(0, 17)}...'
                  : fileName,
              style: const TextStyle(fontSize: 12),
            ),
          ],
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

  void _viewAttachment(Map<String, dynamic> attachment) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.attach_file, size: 56, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              attachment['name'] ?? 'Attachment',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Tap to download or view",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text("Close"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement download
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.download),
                    label: const Text("Download"),
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'No due date';
    final date = timestamp.toDate();
    return DateFormat('dd MMM yyyy').format(date);
  }
}