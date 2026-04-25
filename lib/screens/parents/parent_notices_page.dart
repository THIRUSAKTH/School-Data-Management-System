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

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);

    try {
      final parentUid = FirebaseAuth.instance.currentUser!.uid;
      final snapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('students')
          .where('parentUid', isEqualTo: parentUid)
          .get();

      _children = snapshot.docs.map((doc) {
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
                (c) => c['class'] == widget.className && c['section'] == widget.section,
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

    setState(() => _isLoading = false);
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
              Text(
                _selectedStudentName!,
                style: const TextStyle(fontSize: 12),
              ),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _children.isEmpty
          ? _buildEmptyState('No Children Linked', 'Please contact the school admin to link your children.')
          : _studentClass == null
          ? _buildEmptyState('No Class Assigned', 'Your child has not been assigned to any class yet.')
          : Column(
        children: [
          if (_children.length > 1) _buildChildSelector(),
          _buildFilterChips(),
          Expanded(
            child: _buildNoticesList(),
          ),
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
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
            color: Colors.black.withValues(alpha: 0.05),
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
                items: _children.map<DropdownMenuItem<String>>((child) {
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
                    final selected = _children.firstWhere((c) => c['id'] == value);
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
    final categories = [
      {'label': 'All', 'value': 'All', 'color': Colors.grey},
      {'label': 'Exam', 'value': 'Exam', 'color': Colors.blue},
      {'label': 'Holiday', 'value': 'Holiday', 'color': Colors.green},
      {'label': 'Meeting', 'value': 'Meeting', 'color': Colors.purple},
      {'label': 'Event', 'value': 'Event', 'color': Colors.teal},
      {'label': 'Urgent', 'value': 'Urgent', 'color': Colors.red},
    ];

    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedFilter == category['value'];
          // FIXED: Explicitly cast the color
          final Color chipColor = category['color'] as Color;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                category['label'] as String,
                style: TextStyle(
                  color: isSelected ? Colors.white : chipColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = selected ? category['value'] as String : "All";
                });
              },
              backgroundColor: Colors.white,
              selectedColor: chipColor,
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: chipColor.withValues(alpha: 0.3),
              ),
              shape: const StadiumBorder(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoticesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('notices')
          .where('targetClass', arrayContains: _studentClass)
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
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back later for announcements',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        var notices = snapshot.data!.docs;

        if (_selectedFilter != "All") {
          notices = notices.where((n) {
            final data = n.data() as Map<String, dynamic>;
            if (_selectedFilter == "Urgent") {
              return data['isUrgent'] == true;
            }
            return data['category'] == _selectedFilter;
          }).toList();
        }

        if (notices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.filter_alt_off, size: 64, color: Colors.grey.shade400),
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
    final isUrgent = data['isUrgent'] ?? false;
    final category = data['category'] ?? 'General';
    final date = data['createdAt'] as Timestamp?;
    final hasImage = data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty;

    Color getCategoryColor() {
      switch (category) {
        case 'Exam': return Colors.blue;
        case 'Holiday': return Colors.green;
        case 'Meeting': return Colors.purple;
        case 'Event': return Colors.teal;
        default: return Colors.orange;
      }
    }

    IconData getCategoryIcon() {
      switch (category) {
        case 'Exam': return Icons.assignment;
        case 'Holiday': return Icons.beach_access;
        case 'Meeting': return Icons.people;
        case 'Event': return Icons.celebration;
        default: return Icons.announcement;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: getCategoryColor().withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(getCategoryIcon(), size: 12, color: getCategoryColor()),
                              const SizedBox(width: 4),
                              Text(
                                category,
                                style: TextStyle(
                                  color: getCategoryColor(),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.priority_high, size: 12, color: Colors.red),
                                SizedBox(width: 4),
                                Text(
                                  "URGENT",
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
                        Icon(Icons.access_time, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          date != null
                              ? DateFormat('dd MMM yyyy').format(date.toDate())
                              : 'Unknown',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
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
                  ],
                ),
              ),

              if (hasImage)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                  child: Image.network(
                    data['imageUrl'],
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 180,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                      ),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 180,
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Tap to read more',
                      style: TextStyle(fontSize: 11, color: Colors.orange.shade400),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, size: 10, color: Colors.orange.shade400),
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
    final hasImage = data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty;
    final isUrgent = data['isUrgent'] ?? false;
    final category = data['category'] ?? 'General';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isUrgent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
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
                      date != null
                          ? DateFormat('dd MMM yyyy').format(date.toDate())
                          : 'Unknown',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                const SizedBox(height: 16),

                if (hasImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      data['imageUrl'],
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),

                if (hasImage) const SizedBox(height: 16),

                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Text(
                      data['description'] ?? 'No description',
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 8),
                    Text(
                      date != null
                          ? DateFormat('dd MMM yyyy, hh:mm a').format(date.toDate())
                          : 'Unknown',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
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
            _filterOption("Exam", Icons.assignment),
            _filterOption("Holiday", Icons.beach_access),
            _filterOption("Meeting", Icons.people),
            _filterOption("Event", Icons.celebration),
            _filterOption("Urgent", Icons.priority_high),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              setState(() => _selectedFilter = "All");
              Navigator.pop(context);
            },
            child: const Text("Reset", style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  Widget _filterOption(String category, IconData icon) {
    return RadioListTile<String>(
      title: Row(
        children: [
          Icon(icon, size: 20, color: Colors.orange),
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