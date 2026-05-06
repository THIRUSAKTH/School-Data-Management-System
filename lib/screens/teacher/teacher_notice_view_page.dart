import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
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
  late Timer _cleanupTimer;

  final List<String> _filterOptions = ["All", "Normal", "Important", "Urgent"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNotices();

    _cleanupTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _cleanupExpiredNotices();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cleanupExpiredNotices();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cleanupTimer.cancel();
    super.dispose();
  }

  Future<void> _cleanupExpiredNotices() async {
    try {
      final now = DateTime.now();
      final noticesSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('notices')
              .where('isActive', isEqualTo: true)
              .get();

      final batch = FirebaseFirestore.instance.batch();
      int deleteCount = 0;

      for (var doc in noticesSnapshot.docs) {
        final data = doc.data();
        final expiryDate = data['expiryDate'] as Timestamp?;
        if (expiryDate != null && expiryDate.toDate().isBefore(now)) {
          batch.delete(doc.reference);
          deleteCount++;
        }
      }

      if (deleteCount > 0) {
        await batch.commit();
        if (mounted) {
          _loadNotices();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$deleteCount expired notice(s) automatically deleted',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up expired notices: $e');
    }
  }

  Future<void> _deleteNotice(String noticeId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              "Delete Notice",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(
              "Are you sure you want to delete '$title'?\nThis action cannot be undone.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Delete"),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('notices')
          .doc(noticeId)
          .delete();
      if (mounted) {
        _loadNotices();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Notice deleted successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error deleting notice: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
              .get();

      final now = DateTime.now();
      List<Map<String, dynamic>> validNotices = [];

      for (var doc in noticesSnapshot.docs) {
        final data = doc.data();
        final expiryDate = data['expiryDate'] as Timestamp?;
        final targetAudience = data['targetAudience'] ?? 'All';

        if (targetAudience != 'All' && targetAudience != 'Teachers') continue;
        if (expiryDate == null || expiryDate.toDate().isAfter(now)) {
          validNotices.add({
            'id': doc.id,
            'title': data['title'] ?? 'Notice',
            'description': data['description'] ?? 'No description',
            'priority': data['priority'] ?? 'Normal',
            'isPinned': data['isPinned'] ?? false,
            'createdAt': data['createdAt'],
            'expiryDate': data['expiryDate'],
            'viewCount': data['viewCount'] ?? 0,
            'createdBy': data['createdBy'] ?? 'Admin',
            'attachments': data['attachments'] ?? [],
            'targetAudience': targetAudience,
          });
        }
      }

      validNotices.sort((a, b) {
        final aPinned = a['isPinned'] ?? false;
        final bPinned = b['isPinned'] ?? false;
        if (aPinned != bPinned) return bPinned ? 1 : -1;
        final aDate = a['createdAt'] as Timestamp?;
        final bDate = b['createdAt'] as Timestamp?;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.toDate().compareTo(aDate.toDate());
      });

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading notices: $e"),
            backgroundColor: Colors.red,
          ),
        );
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

  // ================= FILE PREVIEW METHODS =================
  Future<void> _viewFile(String url, String fileName) async {
    try {
      if (kIsWeb) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.platformDefault);
      } else {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Opening file...'),
                  ],
                ),
              ),
        );

        final response = await http.get(Uri.parse(url));
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        if (context.mounted) Navigator.pop(context);
        await OpenFile.open(file.path);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadFile(String url, String fileName) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Downloading...'),
                ],
              ),
            ),
      );

      final response = await http.get(Uri.parse(url));
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);

      if (context.mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloaded: $fileName'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareFile(String url, String fileName) async {
    try {
      final response = await http.get(Uri.parse(url));
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Check out this file: $fileName');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileIconColor(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
    final isExpired =
        expiryDate != null && expiryDate.toDate().isBefore(DateTime.now());

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
      onLongPress: () => _deleteNotice(notice['id'], notice['title']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isExpired ? Colors.grey.shade100 : Colors.white,
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
              if (!isExpired) {
                _incrementViewCount(notice['id'], viewCount);
                _showNoticeDetail(notice);
              }
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
                      if (isExpired) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer_off,
                                size: 12,
                                color: Colors.red,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "EXPIRED",
                                style: TextStyle(
                                  color: Colors.red,
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
                    notice['title'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isExpired ? Colors.grey.shade600 : Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notice['description'],
                    style: TextStyle(
                      color:
                          isExpired
                              ? Colors.grey.shade400
                              : Colors.grey.shade700,
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
                          isExpired
                              ? "Expired"
                              : "Expires: ${DateFormat('dd MMM').format(expiryDate.toDate())}",
                          style: TextStyle(
                            fontSize: 10,
                            color:
                                isExpired
                                    ? Colors.red.shade400
                                    : Colors.grey.shade500,
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
    final description = notice['description'] ?? 'No description';
    final title = notice['title'] ?? 'Notice';

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
                          title,
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
                          description,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showAttachmentPreview(attachment),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: _getFileIconColor(fileName).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getFileIcon(fileName),
                  color: _getFileIconColor(fileName),
                  size: 25,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatFileSize(fileSize),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.visibility, color: Colors.blue, size: 20),
                    onPressed: () => _viewFile(url, fileName),
                    tooltip: 'View',
                  ),
                  IconButton(
                    icon: Icon(Icons.download, color: Colors.green, size: 20),
                    onPressed: () => _downloadFile(url, fileName),
                    tooltip: 'Download',
                  ),
                  IconButton(
                    icon: Icon(Icons.share, color: Colors.orange, size: 20),
                    onPressed: () => _shareFile(url, fileName),
                    tooltip: 'Share',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAttachmentPreview(Map<String, dynamic> attachment) {
    final isImage = attachment['type'] == 'image';
    final url = attachment['url'];
    final fileName = attachment['originalName'] ?? attachment['name'];
    final fileSize = attachment['size'] ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
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
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getFileIconColor(
                                fileName,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              _getFileIcon(fileName),
                              color: _getFileIconColor(fileName),
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fileName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatFileSize(fileSize),
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
                      const SizedBox(height: 20),
                      const Divider(),
                      Expanded(
                        child:
                            isImage
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    url,
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                    loadingBuilder: (
                                      context,
                                      child,
                                      loadingProgress,
                                    ) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            CircularProgressIndicator(
                                              value:
                                                  loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                      : null,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Loading image...',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    errorBuilder:
                                        (_, __, ___) => Container(
                                          height: 200,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.broken_image,
                                                size: 48,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Failed to load image',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                  ),
                                )
                                : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _getFileIcon(fileName),
                                        size: 80,
                                        color: _getFileIconColor(fileName),
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        'File Type: ${fileName.split('.').last.toUpperCase()}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Size: ${_formatFileSize(fileSize)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              _viewFile(url, fileName);
                                              Navigator.pop(context);
                                            },
                                            icon: const Icon(Icons.visibility),
                                            label: const Text('Open'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          OutlinedButton.icon(
                                            onPressed:
                                                () => _shareFile(url, fileName),
                                            icon: const Icon(Icons.share),
                                            label: const Text('Share'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                              label: const Text('Close'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _downloadFile(url, fileName),
                              icon: const Icon(Icons.download),
                              label: const Text('Download'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
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
          ),
    );
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