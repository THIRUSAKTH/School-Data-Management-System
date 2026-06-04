import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:schoolprojectjan/app_config.dart';

import 'teacher_homework_post_page.dart';
import 'teacher_homework_submissions_page.dart';

class TeacherHomeworkDashboard extends StatefulWidget {
  const TeacherHomeworkDashboard({super.key});

  @override
  State<TeacherHomeworkDashboard> createState() =>
      _TeacherHomeworkDashboardState();
}

class _TeacherHomeworkDashboardState extends State<TeacherHomeworkDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = "All";
  String _selectedClass = "All Classes";
  List<String> _classes = [];
  Map<String, int> _classStudentCount = {};

  final List<String> _filterOptions = ["All", "Urgent", "Normal"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadClasses();
    _loadClassStudentCounts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    try {
      final studentsSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('students')
              .get();

      final classesSet = <String>{};
      for (var doc in studentsSnapshot.docs) {
        final className = doc['class'] as String?;
        if (className != null && className.isNotEmpty) {
          classesSet.add(className);
        }
      }

      if (mounted) {
        setState(() {
          _classes = ["All Classes", ...classesSet.toList()..sort()];
        });
      }
    } catch (e) {
      debugPrint('Error loading classes: $e');
    }
  }

  Future<void> _loadClassStudentCounts() async {
    try {
      final studentsSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('students')
              .get();

      final counts = <String, int>{};
      for (var doc in studentsSnapshot.docs) {
        final className = doc['class'] as String?;
        if (className != null && className.isNotEmpty) {
          counts[className] = (counts[className] ?? 0) + 1;
        }
      }

      if (mounted) {
        setState(() {
          _classStudentCount = counts;
        });
      }
    } catch (e) {
      debugPrint('Error loading student counts: $e');
    }
  }

  int _getTotalStudentsForClass(String className) {
    return _classStudentCount[className] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          "Homework Management",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.assignment), text: "All Homework"),
            Tab(icon: Icon(Icons.assignment_turned_in), text: "Submissions"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToPostPage(),
            tooltip: "Post Homework",
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadClasses();
              _loadClassStudentCounts();
              setState(() {});
            },
            tooltip: "Refresh",
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildHomeworkList(), _buildSubmissionsOverview()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.class_, size: 18, color: Colors.deepPurple),
              const SizedBox(width: 8),
              const Text(
                "Class:",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedClass,
                  items:
                      _classes.map((className) {
                        return DropdownMenuItem(
                          value: className,
                          child: Text(className),
                        );
                      }).toList(),
                  onChanged: (value) => setState(() => _selectedClass = value!),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  _filterOptions.map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(
                            () => _selectedFilter = selected ? filter : "All",
                          );
                        },
                        backgroundColor: Colors.grey.shade100,
                        selectedColor:
                            filter == "Urgent" ? Colors.red : Colors.deepPurple,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeworkList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('homework')
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
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text("Error: ${snapshot.error}"),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _loadClasses();
                    _loadClassStudentCounts();
                    setState(() {});
                  },
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
                Icon(Icons.assignment, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text(
                  "No Homework Posted",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Tap + button to post new homework",
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        var homeworkList = snapshot.data!.docs.toList();

        homeworkList =
            homeworkList.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['isActive'] == true;
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
                const Text(
                  "No Active Homework",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "All homework has been completed",
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        homeworkList.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aCreatedAt = aData['createdAt'] as Timestamp?;
          final bCreatedAt = bData['createdAt'] as Timestamp?;
          if (aCreatedAt == null && bCreatedAt == null) return 0;
          if (aCreatedAt == null) return 1;
          if (bCreatedAt == null) return -1;
          return bCreatedAt.toDate().compareTo(aCreatedAt.toDate());
        });

        if (_selectedClass != "All Classes") {
          homeworkList =
              homeworkList.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['className'] == _selectedClass;
              }).toList();
        }

        if (_selectedFilter == "Urgent") {
          homeworkList =
              homeworkList.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['isUrgent'] == true;
              }).toList();
        } else if (_selectedFilter == "Normal") {
          homeworkList =
              homeworkList.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['isUrgent'] != true;
              }).toList();
        }

        if (homeworkList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.filter_list, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  "No matching homework",
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await _loadClasses();
            await _loadClassStudentCounts();
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: homeworkList.length,
            itemBuilder: (context, index) {
              final doc = homeworkList[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildHomeworkCard(doc.id, data);
            },
          ),
        );
      },
    );
  }

  Widget _buildHomeworkCard(String homeworkId, Map<String, dynamic> data) {
    final title = data['title'] ?? 'Untitled';
    final description = data['description'] ?? '';
    final subject = data['subject'] ?? 'General';
    final className = data['className'] ?? '';
    final section = data['section'] ?? '';
    final dueDate = data['dueDate'] as Timestamp?;
    final isUrgent = data['isUrgent'] ?? false;
    final submittedBy = List<String>.from(data['submittedBy'] ?? []);
    final attachments = data['attachments'] as List? ?? [];
    final submittedCount = submittedBy.length;
    final totalStudents = _getTotalStudentsForClass(className);
    final pendingCount = totalStudents - submittedCount;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isUrgent
                                ? Colors.red.shade50
                                : Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isUrgent ? Icons.priority_high : Icons.assignment,
                            size: 14,
                            color: isUrgent ? Colors.red : Colors.deepPurple,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isUrgent ? "URGENT" : subject,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isUrgent ? Colors.red : Colors.deepPurple,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "$className - $section",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                    Text(
                      dueDate != null
                          ? DateFormat('dd MMM yyyy').format(dueDate.toDate())
                          : "No due date",
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            dueDate != null &&
                                    dueDate.toDate().isBefore(DateTime.now())
                                ? Colors.red
                                : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildStatChip(
                      Icons.assignment_turned_in,
                      "$submittedCount/$totalStudents Submitted",
                      Colors.green,
                    ),
                    if (attachments.isNotEmpty)
                      _buildStatChip(
                        Icons.attach_file,
                        "${attachments.length} Attachments",
                        Colors.blue,
                      ),
                    if (pendingCount > 0)
                      _buildStatChip(
                        Icons.pending,
                        "$pendingCount Pending",
                        Colors.orange,
                      ),
                  ],
                ),
                if (totalStudents > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: LinearProgressIndicator(
                      value: submittedCount / totalStudents,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        (submittedCount / totalStudents) >= 0.7
                            ? Colors.green
                            : Colors.orange,
                      ),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed:
                        () => _navigateToSubmissions(
                          homeworkId,
                          title,
                          className,
                          section,
                        ),
                    icon: const Icon(Icons.assignment_turned_in, size: 18),
                    label: const Text("View Submissions"),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _navigateToEditPage(homeworkId, data),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text("Edit"),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }

  Widget _buildSubmissionsOverview() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('homework')
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
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text("Error: ${snapshot.error}"),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _loadClasses();
                    _loadClassStudentCounts();
                    setState(() {});
                  },
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
                const Text("No submissions yet"),
                const SizedBox(height: 8),
                Text(
                  "Students will appear here once they submit homework",
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        List<Map<String, dynamic>> homeworkWithSubmissions = [];

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['isActive'] != true) continue;

          final submittedBy = List<String>.from(data['submittedBy'] ?? []);
          final className = data['className'] ?? '';
          final totalStudents = _getTotalStudentsForClass(className);

          homeworkWithSubmissions.add({
            'id': doc.id,
            'title': data['title'] ?? 'Untitled',
            'className': className,
            'section': data['section'] ?? '',
            'subject': data['subject'] ?? '',
            'submittedCount': submittedBy.length,
            'totalStudents': totalStudents,
            'dueDate': data['dueDate'] as Timestamp?,
            'isUrgent': data['isUrgent'] ?? false,
          });
        }

        if (homeworkWithSubmissions.isEmpty) {
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
                const Text("All caught up!"),
                const SizedBox(height: 8),
                Text(
                  "All homework has been submitted",
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await _loadClasses();
            await _loadClassStudentCounts();
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: homeworkWithSubmissions.length,
            itemBuilder: (context, index) {
              final homework = homeworkWithSubmissions[index];
              final pendingCount =
                  homework['totalStudents'] - homework['submittedCount'];
              final submissionPercentage =
                  homework['totalStudents'] > 0
                      ? homework['submittedCount'] / homework['totalStudents']
                      : 0.0;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap:
                      () => _navigateToSubmissions(
                        homework['id'],
                        homework['title'],
                        homework['className'],
                        homework['section'],
                      ),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    homework['isUrgent']
                                        ? Colors.red.shade50
                                        : Colors.deepPurple.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                homework['subject'],
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      homework['isUrgent']
                                          ? Colors.red
                                          : Colors.deepPurple,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "${homework['className']} - ${homework['section']}",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                            Text(
                              homework['dueDate'] != null
                                  ? DateFormat(
                                    'dd MMM yyyy',
                                  ).format(homework['dueDate']!.toDate())
                                  : "No due date",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          homework['title'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSubmissionStat(
                                homework['submittedCount'],
                                "Submitted",
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSubmissionStat(
                                pendingCount,
                                "Pending",
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: submissionPercentage,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            submissionPercentage >= 0.7
                                ? Colors.green
                                : Colors.orange,
                          ),
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${(submissionPercentage * 100).toStringAsFixed(1)}% completed",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSubmissionStat(int count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }

  void _navigateToPostPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TeacherHomeworkPostPage()),
    ).then((_) => setState(() {}));
  }

  void _navigateToEditPage(String homeworkId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => TeacherHomeworkPostPage(
              editHomeworkId: homeworkId,
              editData: data,
            ),
      ),
    ).then((_) => setState(() {}));
  }

  void _navigateToSubmissions(
    String homeworkId,
    String title,
    String className,
    String section,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => TeacherHomeworkSubmissionsPage(
              homeworkId: homeworkId,
              homeworkTitle: title,
              className: className,
              section: section,
            ),
      ),
    ).then((_) => setState(() {}));
  }
}
