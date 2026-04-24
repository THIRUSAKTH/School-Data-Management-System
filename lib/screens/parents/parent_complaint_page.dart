import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:schoolprojectjan/app_config.dart';

class ParentComplaintPage extends StatefulWidget {
  final String? studentId; // Optional: pre-select a student

  const ParentComplaintPage({super.key, this.studentId});

  @override
  State<ParentComplaintPage> createState() => _ParentComplaintPageState();
}

class _ParentComplaintPageState extends State<ParentComplaintPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedStudentId;
  String? _studentName;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = "Academic";
  bool _isLoading = false;

  final List<String> _categories = [
    "Academic",
    "Fee Related",
    "Teacher Issue",
    "Infrastructure",
    "Transport",
    "Exam Related",
    "Other",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStudentData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentData() async {
    setState(() => _isLoading = true);

    try {
      final parentUid = FirebaseAuth.instance.currentUser!.uid;
      final studentsSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('students')
              .where('parentUid', isEqualTo: parentUid)
              .get();

      if (studentsSnapshot.docs.isNotEmpty) {
        // If a specific studentId is provided, use it
        if (widget.studentId != null) {
          final studentDoc = studentsSnapshot.docs.firstWhere(
            (doc) => doc.id == widget.studentId,
            orElse: () => studentsSnapshot.docs.first,
          );
          _selectedStudentId = studentDoc.id;
          _studentName = studentDoc.data()['name'] ?? 'Student';
        } else {
          final firstStudent = studentsSnapshot.docs.first;
          _selectedStudentId = firstStudent.id;
          _studentName = firstStudent.data()['name'] ?? 'Student';
        }
      }
    } catch (e) {
      debugPrint('Error loading student data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          "Complaints",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.add), text: "New Complaint"),
            Tab(icon: Icon(Icons.history), text: "My Complaints"),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [_buildNewComplaintTab(), _buildMyComplaintsTab()],
              ),
    );
  }

  Widget _buildNewComplaintTab() {
    if (_selectedStudentId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildStudentSelector(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: "Category",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items:
                        _categories.map<DropdownMenuItem<String>>((category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCategory = value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: "Subject / Title",
                      hintText: "Brief summary of your complaint",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator:
                        (v) =>
                            v?.isEmpty == true ? "Please enter a title" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: "Description",
                      hintText:
                          "Please provide detailed information about your complaint...",
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    validator:
                        (v) =>
                            v?.isEmpty == true
                                ? "Please enter description"
                                : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitComplaint,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Submit Complaint",
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
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: _cardDecoration(),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Your complaint will be reviewed by the school administration. You will receive a response within 2-3 business days.",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentSelector() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('students')
              .where(
                'parentUid',
                isEqualTo: FirebaseAuth.instance.currentUser!.uid,
              )
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }

        final students = snapshot.data!.docs;

        // If only one student, don't show dropdown
        if (students.length == 1) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: _cardDecoration(),
            child: Row(
              children: [
                const Icon(Icons.person, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _studentName ?? 'Student',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const Text(
                        "Selected Child",
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: _cardDecoration(),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedStudentId,
              hint: const Text("Select Child"),
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.orange),
              items:
                  students.map<DropdownMenuItem<String>>((student) {
                    final data = student.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: student.id,
                      child: Row(
                        children: [
                          const Icon(Icons.person, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['name'] ?? 'Student',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  "Class ${data['class'] ?? 'N/A'} - ${data['section'] ?? ''}",
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                final selected = students.firstWhere((s) => s.id == value);
                final data = selected.data() as Map<String, dynamic>;
                setState(() {
                  _selectedStudentId = value;
                  _studentName = data['name'] ?? 'Student';
                });
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildMyComplaintsTab() {
    if (_selectedStudentId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('complaints')
              .where('studentId', isEqualTo: _selectedStudentId)
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
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text(
                  "Error loading complaints",
                  style: TextStyle(color: Colors.grey.shade600),
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
                  Icons.feedback_outlined,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Complaints Filed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap New Complaint to raise your concern',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final complaint = snapshot.data!.docs[index];
            final data = complaint.data() as Map<String, dynamic>;
            return _buildComplaintCard(complaint.id, data);
          },
        );
      },
    );
  }

  Widget _buildComplaintCard(String complaintId, Map<String, dynamic> data) {
    final status = data['status'] ?? 'pending';
    final createdAt = data['createdAt'] as Timestamp?;
    final respondedAt = data['respondedAt'] as Timestamp?;

    final statusConfig = _getStatusConfig(status);

    return Dismissible(
      key: Key(complaintId),
      direction: DismissDirection.none, // Disable swipe to delete
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: _cardDecoration(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and date
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusConfig['color'].withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusConfig['icon'],
                          size: 14,
                          color: statusConfig['color'],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusConfig['label'],
                          style: TextStyle(
                            color: statusConfig['color'],
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    createdAt != null
                        ? DateFormat(
                          'dd MMM yyyy, hh:mm a',
                        ).format(createdAt.toDate())
                        : 'Unknown date',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Category
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  data['category'] ?? 'General',
                  style: TextStyle(fontSize: 10, color: Colors.orange.shade700),
                ),
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                data['title'] ?? 'Complaint',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                data['description'] ?? 'No description',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),

              // Response from school
              if (data['response'] != null &&
                  data['response'].toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.school,
                            size: 16,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "School Response",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data['response'],
                        style: const TextStyle(fontSize: 13),
                      ),
                      if (respondedAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            "Responded on: ${DateFormat('dd MMM yyyy, hh:mm a').format(respondedAt.toDate())}",
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status) {
      case 'resolved':
        return {
          'label': 'RESOLVED',
          'color': Colors.green,
          'icon': Icons.check_circle,
        };
      case 'in_progress':
        return {
          'label': 'IN PROGRESS',
          'color': Colors.blue,
          'icon': Icons.hourglass_empty,
        };
      case 'rejected':
        return {'label': 'REJECTED', 'color': Colors.red, 'icon': Icons.cancel};
      default:
        return {
          'label': 'PENDING',
          'color': Colors.orange,
          'icon': Icons.pending,
        };
    }
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a child"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('complaints')
          .add({
            'studentId': _selectedStudentId,
            'studentName': _studentName,
            'title': _titleController.text.trim(),
            'description': _descriptionController.text.trim(),
            'category': _selectedCategory,
            'status': 'pending',
            'response': null,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Clear form
      _titleController.clear();
      _descriptionController.clear();
      setState(() => _selectedCategory = "Academic");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Complaint submitted successfully!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Switch to My Complaints tab
        _tabController.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
