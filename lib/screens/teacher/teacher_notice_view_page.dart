import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:schoolprojectjan/app_config.dart';

class TeacherNoticeViewPage extends StatefulWidget {
  const TeacherNoticeViewPage({super.key});

  @override
  State<TeacherNoticeViewPage> createState() => _TeacherNoticeViewPageState();
}

class _TeacherNoticeViewPageState extends State<TeacherNoticeViewPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = "All";
  List<Map<String, dynamic>> _notices = [];
  bool _isLoading = true;

  final List<String> _filterOptions = ["All", "Normal", "Important", "Urgent"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNotices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotices() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final noticesSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('notices')
              .where('isActive', isEqualTo: true)
              .orderBy('isPinned', descending: true)
              .orderBy('createdAt', descending: true)
              .get();

      final now = DateTime.now();
      List<Map<String, dynamic>> validNotices = [];

      for (var doc in noticesSnapshot.docs) {
        final data = doc.data();
        final expiryDate = data['expiryDate'] as Timestamp?;

        // Check target audience - Teachers can see notices for 'All', 'Teachers'
        final targetAudience = data['targetAudience'] ?? 'All';
        if (targetAudience != 'All' && targetAudience != 'Teachers') {
          continue;
        }

        // Check if notice is not expired
        if (expiryDate == null || expiryDate.toDate().isAfter(now)) {
          validNotices.add({'id': doc.id, ...data});
        }
      }

      if (mounted) {
        setState(() {
          _notices = validNotices;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading notices: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _incrementViewCount(String noticeId, int currentCount) async {
    try {
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('notices')
          .doc(noticeId)
          .update({'viewCount': currentCount + 1});
    } catch (e) {
      debugPrint('Error updating view count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          "Notices",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.announcement), text: "All Notices"),
            Tab(icon: Icon(Icons.push_pin), text: "Pinned"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadNotices),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildNoticeList(allNotices: true),
                  _buildNoticeList(allNotices: false),
                ],
              ),
    );
  }

  Widget _buildNoticeList({required bool allNotices}) {
    var filteredNotices =
        _notices.where((notice) {
          if (!allNotices) return notice['isPinned'] == true;
          if (_selectedFilter != "All")
            return notice['priority'] == _selectedFilter;
          return true;
        }).toList();

    if (filteredNotices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              allNotices
                  ? Icons.announcement_outlined
                  : Icons.push_pin_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              allNotices ? "No notices available" : "No pinned notices",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              allNotices
                  ? "Check back later for updates"
                  : "Pinned notices will appear here",
              style: TextStyle(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadNotices,
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotices,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: filteredNotices.length,
        itemBuilder: (context, index) {
          final notice = filteredNotices[index];
          return _buildNoticeCard(notice);
        },
      ),
    );
  }

  Widget _buildNoticeCard(Map<String, dynamic> notice) {
    final priority = notice['priority'] ?? 'Normal';
    final isPinned = notice['isPinned'] ?? false;
    final createdAt = notice['createdAt'] as Timestamp?;
    final expiryDate = notice['expiryDate'] as Timestamp?;
    final viewCount = notice['viewCount'] ?? 0;
    final createdBy = notice['createdBy'] ?? 'Admin';
    final attachments = notice['attachments'] as List? ?? [];

    Color getPriorityColor() {
      switch (priority) {
        case 'Urgent':
          return Colors.red;
        case 'Important':
          return Colors.orange;
        default:
          return Colors.blue;
      }
    }

    return GestureDetector(
      onTap: () {
        _incrementViewCount(notice['id'], viewCount);
        _showNoticeDetail(notice);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              _incrementViewCount(notice['id'], viewCount);
              _showNoticeDetail(notice);
            },
            child: Padding(
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
                              priority == 'Urgent'
                                  ? Icons.warning
                                  : (priority == 'Important'
                                      ? Icons.priority_high
                                      : Icons.info),
                              size: 14,
                              color: getPriorityColor(),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              priority.toUpperCase(),
                              style: TextStyle(
                                color: getPriorityColor(),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
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
                                size: 12,
                                color: Colors.deepPurple,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "PINNED",
                                style: TextStyle(
                                  color: Colors.deepPurple,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.remove_red_eye,
                              size: 12,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              viewCount.toString(),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    notice['title'] ?? 'Notice',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notice['description'] ?? 'No description',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        createdBy,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        createdAt != null
                            ? DateFormat(
                              'dd MMM yyyy',
                            ).format(createdAt.toDate())
                            : 'Unknown date',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      if (expiryDate != null) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.timer_outlined,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Expires: ${DateFormat('dd MMM').format(expiryDate.toDate())}",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (attachments.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.attach_file,
                            size: 12,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${attachments.length} attachment(s)",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showNoticeDetail(Map<String, dynamic> notice) {
    final priority = notice['priority'] ?? 'Normal';
    final isPinned = notice['isPinned'] ?? false;
    final createdAt = notice['createdAt'] as Timestamp?;
    final expiryDate = notice['expiryDate'] as Timestamp?;
    final viewCount = notice['viewCount'] ?? 0;
    final createdBy = notice['createdBy'] ?? 'Admin';
    final attachments = notice['attachments'] as List? ?? [];

    Color getPriorityColor() {
      switch (priority) {
        case 'Urgent':
          return Colors.red;
        case 'Important':
          return Colors.orange;
        default:
          return Colors.blue;
      }
    }

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
                                  fontWeight: FontWeight.bold,
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
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          notice['title'] ?? 'Notice',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "By: $createdBy",
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
                              createdAt != null
                                  ? DateFormat(
                                    'dd MMM yyyy, hh:mm a',
                                  ).format(createdAt.toDate())
                                  : 'Unknown date',
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
                        const Divider(height: 32),
                        Text(
                          notice['description'] ?? 'No description',
                          style: const TextStyle(fontSize: 16, height: 1.5),
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

                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text("Close"),
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
                            color: Colors.deepPurple,
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
                            backgroundColor: Colors.deepPurple,
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
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text("Filter Notices"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  _filterOptions.map((option) {
                    return RadioListTile<String>(
                      title: Row(
                        children: [
                          if (option != "All")
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color:
                                    option == "Urgent"
                                        ? Colors.red
                                        : (option == "Important"
                                            ? Colors.orange
                                            : Colors.blue),
                                shape: BoxShape.circle,
                              ),
                            ),
                          const SizedBox(width: 8),
                          Text(option),
                        ],
                      ),
                      value: option,
                      groupValue: _selectedFilter,
                      activeColor: Colors.deepPurple,
                      onChanged: (value) {
                        setState(() => _selectedFilter = value!);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
            ),
          ),
    );
  }
}
