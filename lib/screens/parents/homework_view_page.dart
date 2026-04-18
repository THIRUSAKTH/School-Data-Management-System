import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:schoolprojectjan/app_config.dart';

class HomeworkViewPage extends StatefulWidget {
  final String? studentClass;
  final String? studentSection;

  const HomeworkViewPage({
    super.key,
    this.studentClass,
    this.studentSection,
  });

  @override
  State<HomeworkViewPage> createState() => _HomeworkViewPageState();
}

class _HomeworkViewPageState extends State<HomeworkViewPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = "All";
  String _selectedClass = "All Classes";
  String _selectedSection = "All Sections";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.studentClass != null) {
      _selectedClass = widget.studentClass!;
    }
    if (widget.studentSection != null) {
      _selectedSection = widget.studentSection!;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text("Homework"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.assignment), text: "Current"),
            Tab(icon: Icon(Icons.history), text: "Past"),
          ],
        ),
        actions: [
          if (widget.studentClass == null)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHomeworkList(isCurrent: true),
          _buildHomeworkList(isCurrent: false),
        ],
      ),
    );
  }

  Widget _buildHomeworkList({required bool isCurrent}) {
    DateTime now = DateTime.now();
    String today = DateFormat('yyyy-MM-dd').format(now);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('homework')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        var homeworkList = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final dueDate = data['dueDate'] as String? ?? '';
          final homeworkClass = data['class'] ?? 'All Classes';
          final section = data['section'] ?? 'All Sections';

          // Filter by current/past
          bool isPast = dueDate.compareTo(today) < 0;
          if (isCurrent ? isPast : !isPast) return false;

          // Filter by class
          if (_selectedClass != "All Classes" && homeworkClass != _selectedClass) {
            return false;
          }

          // Filter by section
          if (_selectedSection != "All Sections" && section != _selectedSection) {
            return false;
          }

          return true;
        }).toList();

        if (homeworkList.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: homeworkList.length,
          itemBuilder: (context, index) {
            final doc = homeworkList[index];
            final data = doc.data() as Map<String, dynamic>;
            return _HomeworkCard(
              id: doc.id,
              title: data['title'] ?? 'No Title',
              description: data['description'] ?? '',
              subject: data['subject'] ?? '',
              className: data['class'] ?? '',
              section: data['section'] ?? '',
              dueDate: data['dueDate'] ?? '',
              dueTime: data['dueTime'],
              isUrgent: data['isUrgent'] ?? false,
              teacherName: data['teacherName'] ?? 'Teacher',
              createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_late, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No homework assigned",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            "Check back later for new assignments",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Filter Homework"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedClass,
              decoration: const InputDecoration(labelText: "Class"),
              items: const [
                DropdownMenuItem(value: "All Classes", child: Text("All Classes")),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedClass = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedSection,
              decoration: const InputDecoration(labelText: "Section"),
              items: const [
                DropdownMenuItem(value: "All Sections", child: Text("All Sections")),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedSection = value!;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedClass = "All Classes";
                _selectedSection = "All Sections";
              });
              Navigator.pop(context);
            },
            child: const Text("Reset"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Apply"),
          ),
        ],
      ),
    );
  }
}

// ================= HOMEWORK CARD WIDGET =================

class _HomeworkCard extends StatelessWidget {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String className;
  final String section;
  final String dueDate;
  final String? dueTime;
  final bool isUrgent;
  final String teacherName;
  final DateTime? createdAt;

  const _HomeworkCard({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.className,
    required this.section,
    required this.dueDate,
    this.dueTime,
    required this.isUrgent,
    required this.teacherName,
    this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    final dueDateTime = DateTime.parse(dueDate);
    final isOverdue = dueDateTime.isBefore(DateTime.now());
    final daysLeft = dueDateTime.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isUrgent
            ? BorderSide(color: Colors.red.shade300, width: 1)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showHomeworkDetails(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      subject,
                      style: TextStyle(
                        color: Colors.deepPurple.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isUrgent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "URGENT",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    "$className ${section != 'All Sections' ? '- $section' : ''}",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    "Due: ${DateFormat('dd MMM yyyy').format(dueDateTime)}",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  if (dueTime != null) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(dueTime!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                  const Spacer(),
                  if (!isOverdue && daysLeft >= 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "$daysLeft days left",
                        style: TextStyle(color: Colors.green.shade700, fontSize: 11),
                      ),
                    ),
                  if (isOverdue)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "Overdue",
                        style: TextStyle(color: Colors.red, fontSize: 11),
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

  void _showHomeworkDetails(BuildContext context) {
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
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        subject,
                        style: TextStyle(color: Colors.deepPurple.shade700),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "$className ${section != 'All Sections' ? '- $section' : ''}",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.person, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(teacherName, style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(width: 16),
                    if (createdAt != null) ...[
                      Icon(Icons.schedule, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        "Posted: ${DateFormat('dd MMM yyyy').format(createdAt!)}",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  "Description",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Text(
                      description,
                      style: const TextStyle(height: 1.5),
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
}