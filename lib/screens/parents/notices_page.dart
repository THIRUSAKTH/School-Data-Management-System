import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:schoolprojectjan/app_config.dart';

class ParentNoticesPage extends StatefulWidget {
  const ParentNoticesPage({super.key});

  @override
  State<ParentNoticesPage> createState() => _ParentNoticesPageState();
}

class _ParentNoticesPageState extends State<ParentNoticesPage> {
  String? _selectedStudentId;
  String _selectedFilter = "All";

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(AppConfig.schoolId)
        .collection('students')
        .where('parentUid', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() => _selectedStudentId = snapshot.docs.first.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        title: const Text("Notices & Announcements"),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_selectedStudentId != null) _buildFilterChips(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('schools')
                  .doc(AppConfig.schoolId)
                  .collection('notices')
                  .where('targetClass', arrayContains: _getStudentClass())
                  .orderBy('createdAt', descending: true)
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
                        Icon(Icons.announcement, size: 80, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No Notices Found',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                var notices = snapshot.data!.docs;
                if (_selectedFilter != "All") {
                  notices = notices.where((n) {
                    final data = n.data() as Map<String, dynamic>;
                    return data['category'] == _selectedFilter;
                  }).toList();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notices.length,
                  itemBuilder: (context, index) {
                    final notice = notices[index];
                    final data = notice.data() as Map<String, dynamic>;
                    return _buildNoticeCard(notice.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _filterChip("All", "All"),
          const SizedBox(width: 8),
          _filterChip("Exam", "Exam"),
          const SizedBox(width: 8),
          _filterChip("Holiday", "Holiday"),
          const SizedBox(width: 8),
          _filterChip("Meeting", "Meeting"),
          const SizedBox(width: 8),
          _filterChip("Event", "Event"),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = selected ? value : "All");
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: Colors.orange.shade100,
      checkmarkColor: Colors.orange,
    );
  }

  Widget _buildNoticeCard(String noticeId, Map<String, dynamic> data) {
    final isUrgent = data['isUrgent'] ?? false;
    final category = data['category'] ?? 'General';
    final date = data['createdAt'] as Timestamp?;

    Color categoryColor;
    switch (category) {
      case 'Exam':
        categoryColor = Colors.blue;
        break;
      case 'Holiday':
        categoryColor = Colors.green;
        break;
      case 'Meeting':
        categoryColor = Colors.purple;
        break;
      case 'Event':
        categoryColor = Colors.teal;
        break;
      default:
        categoryColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showNoticeDetail(data),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(color: categoryColor, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (isUrgent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "URGENT",
                          style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      date != null ? DateFormat('dd MMM').format(date.toDate()) : 'Unknown',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  data['title'] ?? 'Notice',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  data['description'] ?? 'No description',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (data['imageUrl'] != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      data['imageUrl'],
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 150,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, size: 40),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<String> _getStudentClass() async {
    final doc = await FirebaseFirestore.instance
        .collection('schools')
        .doc(AppConfig.schoolId)
        .collection('students')
        .doc(_selectedStudentId)
        .get();
    final data = doc.data() as Map<String, dynamic>;
    return data['class'] ?? '';
  }

  void _showNoticeDetail(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['title'] ?? 'Notice'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (data['imageUrl'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(data['imageUrl']),
                ),
              const SizedBox(height: 12),
              Text(
                data['description'] ?? 'No description',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Text(
                "Posted: ${DateFormat('dd MMM yyyy, hh:mm a').format((data['createdAt'] as Timestamp).toDate())}",
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Filter Notices"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _filterOption("All"),
            _filterOption("Exam"),
            _filterOption("Holiday"),
            _filterOption("Meeting"),
            _filterOption("Event"),
          ],
        ),
      ),
    );
  }

  Widget _filterOption(String category) {
    return RadioListTile<String>(
      title: Text(category),
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