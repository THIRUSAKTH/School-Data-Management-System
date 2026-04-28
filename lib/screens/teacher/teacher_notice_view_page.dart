import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
    setState(() => _isLoading = true);

    try {
      final noticesSnapshot = await FirebaseFirestore.instance
          .collectionGroup('notices')
          .where('isActive', isEqualTo: true)
          .orderBy('isPinned', descending: true)
          .orderBy('createdAt', descending: true)
          .get();

      final now = DateTime.now();
      List<Map<String, dynamic>> validNotices = [];

      for (var doc in noticesSnapshot.docs) {
        final data = doc.data();
        final expiryDate = data['expiryDate'] as Timestamp?;

        // Check if notice is not expired
        if (expiryDate == null || expiryDate.toDate().isAfter(now)) {
          validNotices.add({
            'id': doc.id,
            ...data,
          });
        }
      }

      setState(() {
        _notices = validNotices;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading notices: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _incrementViewCount(String noticeId, int currentCount) async {
    try {
      await FirebaseFirestore.instance
          .collectionGroup('notices')
          .where(FieldPath.documentId, isEqualTo: noticeId)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.update({'viewCount': currentCount + 1});
        }
      });
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
            tooltip: "Filter",
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotices,
            tooltip: "Refresh",
          ),
        ],
      ),
      body: _isLoading
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
    var filteredNotices = _notices.where((notice) {
      if (!allNotices) return notice['isPinned'] == true;
      if (_selectedFilter != "All") return notice['priority'] == _selectedFilter;
      return true;
    }).toList();

    if (filteredNotices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              allNotices ? Icons.announcement_outlined : Icons.push_pin_outlined,
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
    final targetAudience = notice['targetAudience'] ?? 'All';

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
                  // Priority and Pinned Badges
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
                                  : priority == 'Important'
                                  ? Icons.priority_high
                                  : Icons.info,
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.push_pin,
                                size: 12,
                                color: Colors.deepPurple,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "PINNED",
                                style: TextStyle(
                                  color: Colors.deepPurple.shade700,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Spacer(),
                      // View Count
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
                  // Title
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
                  // Description
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
                  // Footer
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
                            ? DateFormat('dd MMM yyyy').format(
                          createdAt.toDate(),
                        )
                            : 'Unknown date',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (expiryDate != null)
                        Row(
                          children: [
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
                        ),
                    ],
                  ),
                  // Target Audience Badge
                  if (targetAudience != 'All') ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "Target: $targetAudience",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.deepPurple.shade700,
                        ),
                      ),
                    ),
                  ],
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
    final targetAudience = notice['targetAudience'] ?? 'All';

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
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
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
                  // Priority and Pinned Badges
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              priority == 'Urgent'
                                  ? Icons.warning
                                  : priority == 'Important'
                                  ? Icons.priority_high
                                  : Icons.info,
                              size: 16,
                              color: getPriorityColor(),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              priority.toUpperCase(),
                              style: TextStyle(
                                color: getPriorityColor(),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.push_pin,
                                size: 14,
                                color: Colors.deepPurple,
                              ),
                              SizedBox(width: 4),
                              Text("PINNED"),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Title
                  Text(
                    notice['title'] ?? 'Notice',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Meta Info
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
                            ? DateFormat('dd MMM yyyy, hh:mm a').format(
                          createdAt.toDate(),
                        )
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
                  if (targetAudience != 'All') ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Target Audience: $targetAudience",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.deepPurple.shade700,
                        ),
                      ),
                    ),
                  ],
                  const Divider(height: 32),
                  // Description
                  Text(
                    notice['description'] ?? 'No description',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Close"),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text("Filter Notices"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _filterOptions.map((option) {
            return RadioListTile<String>(
              title: Row(
                children: [
                  if (option != "All")
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: option == "Urgent"
                            ? Colors.red
                            : option == "Important"
                            ? Colors.orange
                            : Colors.blue,
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
                setState(() {
                  _selectedFilter = value!;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}