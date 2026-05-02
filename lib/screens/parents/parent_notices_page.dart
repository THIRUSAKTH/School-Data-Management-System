import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:schoolprojectjan/app_config.dart';

class ParentNoticesPage extends StatefulWidget {
  final String? className;
  final String? section;

  const ParentNoticesPage({super.key, this.className, this.section});

  @override
  State<ParentNoticesPage> createState() => _ParentNoticesPageState();
}

class _ParentNoticesPageState extends State<ParentNoticesPage> {
  String? _selectedStudentId;
  String? _selectedStudentName;
  String? _studentClass;
  String? _studentSection;
  String _selectedFilter = "All";
  List<Map<String, dynamic>> _children = [];
  bool _isLoading = true;

  final Map<String, Color> _priorityColors = {
    'Normal': Colors.blue,
    'Important': Colors.orange,
    'Urgent': Colors.red,
  };

  final Map<String, IconData> _priorityIcons = {
    'Normal': Icons.info,
    'Important': Icons.priority_high,
    'Urgent': Icons.warning,
  };

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final parentUid = FirebaseAuth.instance.currentUser!.uid;
      final snapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('students')
              .where('parentUid', isEqualTo: parentUid)
              .get();

      _children =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'name': data['name'] ?? 'Student',
              'class': data['class'] ?? '',
              'section': data['section'] ?? '',
            };
          }).toList();

      if (_children.isNotEmpty) {
        if (widget.className != null && widget.section != null) {
          _studentClass = widget.className;
          _studentSection = widget.section;
          final matchingChild = _children.firstWhere(
            (c) =>
                c['class'] == widget.className &&
                c['section'] == widget.section,
            orElse: () => _children.first,
          );
          _selectedStudentId = matchingChild['id'];
          _selectedStudentName = matchingChild['name'];
        } else {
          _selectedStudentId = _children.first['id'];
          _selectedStudentName = _children.first['name'];
          _studentClass = _children.first['class'];
          _studentSection = _children.first['section'];
        }
      }
    } catch (e) {
      debugPrint('Error loading students: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Notices & Announcements",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_selectedStudentName != null)
              Text(_selectedStudentName!, style: const TextStyle(fontSize: 12)),
          ],
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: "Refresh",
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
            tooltip: "Filter",
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _children.isEmpty
              ? _buildEmptyState(
                'No Children Linked',
                'Please contact the school admin to link your children.',
              )
              : _studentClass == null
              ? _buildEmptyState(
                'No Class Assigned',
                'Your child has not been assigned to any class yet.',
              )
              : Column(
                children: [
                  if (_children.length > 1) _buildChildSelector(),
                  _buildFilterChips(),
                  Expanded(child: _buildNoticesList()),
                ],
              ),
    );
  }

  Widget _buildEmptyState(String title, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.announcement, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadStudents,
            icon: const Icon(Icons.refresh),
            label: const Text("Refresh"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildSelector() {
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
            'Child:',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedStudentId,
                hint: const Text('Select Child'),
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.orange),
                items:
                    _children.map<DropdownMenuItem<String>>((child) {
                      return DropdownMenuItem<String>(
                        value: child['id'] as String,
                        child: Text(
                          '${child['name']} - Class ${child['class']}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                onChanged: (value) async {
                  setState(() {
                    _selectedStudentId = value;
                    final selected = _children.firstWhere(
                      (c) => c['id'] == value,
                    );
                    _selectedStudentName = selected['name'];
                    _studentClass = selected['class'];
                    _studentSection = selected['section'];
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'label': 'All', 'value': 'All', 'color': Colors.grey},
      {'label': 'Normal', 'value': 'Normal', 'color': Colors.blue},
      {'label': 'Important', 'value': 'Important', 'color': Colors.orange},
      {'label': 'Urgent', 'value': 'Urgent', 'color': Colors.red},
    ];

    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter['value'];
          final Color chipColor = filter['color'] as Color;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                filter['label'] as String,
                style: TextStyle(
                  color: isSelected ? Colors.white : chipColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              onSelected:
                  (selected) => setState(
                    () =>
                        _selectedFilter =
                            selected ? filter['value'] as String : "All",
                  ),
              backgroundColor: Colors.white,
              selectedColor: chipColor,
              checkmarkColor: Colors.white,
              side: BorderSide(color: chipColor.withOpacity(0.3)),
              shape: const StadiumBorder(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoticesList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('notices')
              .where('isActive', isEqualTo: true)
              .orderBy('isPinned', descending: true)
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
                Icon(Icons.announcement, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No Notices Found',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back later for announcements',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh),
                  label: const Text("Refresh"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        var notices = snapshot.data!.docs;

        // Apply filters based on parent's child class
        notices =
            notices.where((notice) {
              final data = notice.data() as Map<String, dynamic>;

              // Check if notice is active
              if (data['isActive'] != true) return false;

              // Check if notice is expired
              final expiryDate = data['expiryDate'] as Timestamp?;
              if (expiryDate != null &&
                  expiryDate.toDate().isBefore(DateTime.now()))
                return false;

              // Check target audience
              final targetAudience = data['targetAudience'] ?? 'All';

              // If target is Teachers, skip for parents
              if (targetAudience == 'Teachers') return false;

              // If target is Specific Class, check if student's class is selected
              if (targetAudience == 'Specific Class') {
                final selectedClasses =
                    data['selectedClasses'] as List<dynamic>? ?? [];
                if (_studentClass != null &&
                    !selectedClasses.contains(_studentClass)) {
                  return false;
                }
              }

              // If target is Parents or All, proceed
              // Also if target is Specific Class and class matches, proceed

              // Apply priority filter
              if (_selectedFilter != "All") {
                final priority = data['priority'] ?? 'Normal';
                if (priority != _selectedFilter) return false;
              }

              return true;
            }).toList();

        if (notices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.filter_alt_off,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No $_selectedFilter notices found',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notices.length,
            itemBuilder: (context, index) {
              final notice = notices[index];
              final data = notice.data() as Map<String, dynamic>;
              return _buildNoticeCard(notice.id, data);
            },
          ),
        );
      },
    );
  }

  Widget _buildNoticeCard(String noticeId, Map<String, dynamic> data) {
    final priority = data['priority'] ?? 'Normal';
    final isPinned = data['isPinned'] ?? false;
    final date = data['createdAt'] as Timestamp?;
    final createdBy = data['createdBy'] ?? 'School Admin';
    final viewCount = data['viewCount'] ?? 0;
    final expiryDate = data['expiryDate'] as Timestamp?;
    final attachments = data['attachments'] as List? ?? [];

    Color getPriorityColor() => _priorityColors[priority] ?? Colors.blue;
    IconData getPriorityIcon() => _priorityIcons[priority] ?? Icons.info;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showNoticeDetail(data),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: getPriorityColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                getPriorityIcon(),
                                size: 12,
                                color: getPriorityColor(),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                priority.toUpperCase(),
                                style: TextStyle(
                                  color: getPriorityColor(),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isPinned) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.push_pin,
                                  size: 10,
                                  color: Colors.deepPurple,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "PINNED",
                                  style: TextStyle(
                                    color: Colors.deepPurple,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Spacer(),
                        Icon(Icons.access_time, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          date != null
                              ? DateFormat('dd MMM yyyy').format(date.toDate())
                              : 'Unknown',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      data['title'] ?? 'Notice',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data['description'] ?? 'No description',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 10,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          createdBy,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.remove_red_eye,
                          size: 10,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "$viewCount views",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        if (expiryDate != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.timer_outlined,
                            size: 10,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Expires: ${DateFormat('dd MMM').format(expiryDate.toDate())}",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Attachment indicator
                    if (attachments.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.attach_file,
                              size: 10,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${attachments.length} attachment(s)",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Tap to read more',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade400,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 10,
                      color: Colors.orange.shade400,
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

  void _showNoticeDetail(Map<String, dynamic> data) {
    final date = data['createdAt'] as Timestamp?;
    final priority = data['priority'] ?? 'Normal';
    final createdBy = data['createdBy'] ?? 'School Admin';
    final isPinned = data['isPinned'] ?? false;
    final viewCount = data['viewCount'] ?? 0;
    final expiryDate = data['expiryDate'] as Timestamp?;
    final attachments = data['attachments'] as List? ?? [];

    Color getPriorityColor() => _priorityColors[priority] ?? Colors.blue;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder:
                (context, scrollController) => SingleChildScrollView(
                  controller: scrollController,
                  child: Container(
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
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: getPriorityColor().withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                priority.toUpperCase(),
                                style: TextStyle(
                                  color: getPriorityColor(),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (isPinned)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  "PINNED",
                                  style: TextStyle(
                                    color: Colors.deepPurple,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          data['title'] ?? 'Notice',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              createdBy,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              date != null
                                  ? DateFormat(
                                    'dd MMM yyyy, hh:mm a',
                                  ).format(date.toDate())
                                  : 'Unknown',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.visibility,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "$viewCount views",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            if (expiryDate != null) ...[
                              const SizedBox(width: 16),
                              Icon(
                                Icons.timer_outlined,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Expires: ${DateFormat('dd MMM yyyy').format(expiryDate.toDate())}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          data['description'] ?? 'No description',
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),

                        // Attachments section
                        if (attachments.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Text(
                            "Attachments:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...attachments.map(
                            (attachment) => _buildAttachmentTile(attachment),
                          ),
                        ],

                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text(
                              'Close',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  Widget _buildAttachmentTile(Map<String, dynamic> attachment) {
    final isImage = attachment['type'] == 'image';
    final url = attachment['url'];
    final fileName = attachment['originalName'] ?? attachment['name'];
    final fileSize = attachment['size'] ?? 0;

    return GestureDetector(
      onTap: () => _showAttachmentPreview(attachment),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isImage ? Colors.green.shade100 : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isImage ? Icons.image : Icons.insert_drive_file,
                size: 24,
                color: isImage ? Colors.green : Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (fileSize > 0)
                    Text(
                      _formatFileSize(fileSize),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isImage ? Colors.green.shade100 : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isImage ? "View Image" : "View File",
                style: TextStyle(
                  fontSize: 11,
                  color: isImage ? Colors.green : Colors.blue,
                ),
              ),
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
                          Text(fileName, textAlign: TextAlign.center),
                          if (attachment['size'] != null)
                            Text(
                              _formatFileSize(attachment['size']),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
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
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Download feature coming soon"),
                              ),
                            );
                          },
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              "Filter Notices",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _filterOption("All", Icons.all_inclusive),
                _filterOption("Normal", Icons.info, Colors.blue),
                _filterOption("Important", Icons.priority_high, Colors.orange),
                _filterOption("Urgent", Icons.warning, Colors.red),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _selectedFilter = "All");
                  Navigator.pop(context);
                },
                child: const Text(
                  "Reset",
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ),
    );
  }

  Widget _filterOption(String category, IconData icon, [Color? color]) {
    return RadioListTile<String>(
      title: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.orange),
          const SizedBox(width: 8),
          Text(category),
        ],
      ),
      value: category,
      groupValue: _selectedFilter,
      activeColor: Colors.orange,
      onChanged: (value) {
        setState(() => _selectedFilter = value!);
        Navigator.pop(context);
      },
    );
  }
}
