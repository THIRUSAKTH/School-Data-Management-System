import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ExamManagementPage extends StatefulWidget {
  final String schoolId;

  const ExamManagementPage({super.key, required this.schoolId});

  @override
  State<ExamManagementPage> createState() => _ExamManagementPageState();
}

class _ExamManagementPageState extends State<ExamManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text(
          "Exam Management",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.quiz), text: "Exams"),
            Tab(icon: Icon(Icons.edit_note), text: "Marks Entry"),
            Tab(icon: Icon(Icons.assessment), text: "Results"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportResults,
            tooltip: "Export Results",
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExamsList(),
          _buildMarksEntry(),
          _buildResultsView(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createExamDialog,
        child: const Icon(Icons.add),
        tooltip: "Create New Exam",
      ),
    );
  }

  // ================= EXAMS LIST TAB =================
  Widget _buildExamsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('exams')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.quiz_outlined, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  "No Exams Created",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Tap the + button to create your first exam",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final exam = snapshot.data!.docs[index];
            final data = exam.data() as Map<String, dynamic>;
            return _buildExamCard(exam.id, data);
          },
        );
      },
    );
  }

  Widget _buildExamCard(String examId, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: _cardDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _viewExamDetails(examId, data),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getExamTypeColor(data['examType']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        data['examType'] ?? 'Exam',
                        style: TextStyle(
                          color: _getExamTypeColor(data['examType']),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text("Edit"),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text("Delete", style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editExam(examId, data);
                        } else if (value == 'delete') {
                          _deleteExam(examId);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  data['examName'] ?? 'Unnamed Exam',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(data['startDate']),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 12, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(data['endDate']),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.class_, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      data['className'] ?? 'All Classes',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.subject, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      "${data['subjects']?.length ?? 0} Subjects",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: _calculateProgress(data),
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${(_calculateProgress(data) * 100).toInt()}% Complete",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      "${data['marksEntered'] ?? 0}/${data['totalMarks'] ?? 0} Marks",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= MARKS ENTRY TAB =================
  Widget _buildMarksEntry() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('exams')
          .where('status', isEqualTo: 'active')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final exams = snapshot.data?.docs ?? [];

        if (exams.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit_note, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  "No Active Exams",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Create an exam first to enter marks",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: exams.length,
          itemBuilder: (context, index) {
            final exam = exams[index];
            final data = exam.data() as Map<String, dynamic>;
            return _buildMarksEntryCard(exam.id, data);
          },
        );
      },
    );
  }

  Widget _buildMarksEntryCard(String examId, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: _cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['examName'] ?? 'Unnamed Exam',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "${data['className'] ?? 'Class'} - ${data['examType'] ?? 'Exam'}",
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              "Subjects",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...List.generate(data['subjects']?.length ?? 0, (index) {
              final subject = data['subjects'][index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: Text(
                    "${index + 1}",
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ),
                title: Text(subject),
                subtitle: Text("Max Marks: ${data['maxMarks']?[index] ?? 100}"),
                trailing: ElevatedButton(
                  onPressed: () => _enterMarks(examId, data, subject, index),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Enter Marks"),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ================= RESULTS VIEW TAB =================
  Widget _buildResultsView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('exams')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final exams = snapshot.data?.docs ?? [];

        if (exams.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assessment, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  "No Results Available",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Complete marks entry to generate results",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: exams.length,
          itemBuilder: (context, index) {
            final exam = exams[index];
            final data = exam.data() as Map<String, dynamic>;
            return _buildResultCard(exam.id, data);
          },
        );
      },
    );
  }

  Widget _buildResultCard(String examId, Map<String, dynamic> data) {
    final progress = _calculateProgress(data);
    final isComplete = progress >= 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: _cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['examName'] ?? 'Unnamed Exam',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${data['className'] ?? 'Class'} • ${data['examType'] ?? 'Exam'}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isComplete ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isComplete ? "Published" : "In Progress",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? Colors.green : Colors.blue,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${(progress * 100).toInt()}% Complete",
                  style: const TextStyle(fontSize: 12),
                ),
                if (isComplete)
                  ElevatedButton.icon(
                    onPressed: () => _viewResultDetails(examId, data),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text("View Results"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= DIALOGS =================
  void _createExamDialog() {
    final formKey = GlobalKey<FormState>();
    String examName = '';
    String examType = 'Mid-term';
    String className = '';
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 7));
    List<String> subjects = [];
    List<int> maxMarks = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Create New Exam"),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: "Exam Name",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.quiz),
                      ),
                      onSaved: (value) => examName = value!,
                      validator: (value) =>
                      value?.isEmpty == true ? "Required" : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: examType,
                      decoration: const InputDecoration(
                        labelText: "Exam Type",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: const [
                        DropdownMenuItem(value: "Mid-term", child: Text("Mid-term")),
                        DropdownMenuItem(value: "Final", child: Text("Final")),
                        DropdownMenuItem(value: "Unit Test", child: Text("Unit Test")),
                        DropdownMenuItem(value: "Weekly Test", child: Text("Weekly Test")),
                      ],
                      onChanged: (value) => setState(() => examType = value!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Class",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.class_),
                      ),
                      items: const [
                        DropdownMenuItem(value: "Class 1", child: Text("Class 1")),
                        DropdownMenuItem(value: "Class 2", child: Text("Class 2")),
                        DropdownMenuItem(value: "Class 3", child: Text("Class 3")),
                        DropdownMenuItem(value: "Class 4", child: Text("Class 4")),
                        DropdownMenuItem(value: "Class 5", child: Text("Class 5")),
                      ],
                      onChanged: (value) => setState(() => className = value!),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: const Text("Start Date"),
                      subtitle: Text(DateFormat('MMM dd, yyyy').format(startDate)),
                      leading: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => startDate = picked);
                        }
                      },
                    ),
                    ListTile(
                      title: const Text("End Date"),
                      subtitle: Text(DateFormat('MMM dd, yyyy').format(endDate)),
                      leading: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: endDate,
                          firstDate: startDate,
                          lastDate: startDate.add(const Duration(days: 90)),
                        );
                        if (picked != null) {
                          setState(() => endDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _addSubjectsDialog(setState, subjects, maxMarks),
                      icon: const Icon(Icons.add),
                      label: const Text("Add Subjects"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    if (subjects.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: List.generate(subjects.length, (index) {
                            return ListTile(
                              title: Text(subjects[index]),
                              subtitle: Text("Max Marks: ${maxMarks[index]}"),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    subjects.removeAt(index);
                                    maxMarks.removeAt(index);
                                  });
                                },
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();
                    if (subjects.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please add at least one subject")),
                      );
                      return;
                    }
                    await _saveExam(
                      examName,
                      examType,
                      className,
                      startDate,
                      endDate,
                      subjects,
                      maxMarks,
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text("Create"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _addSubjectsDialog(StateSetter setState, List<String> subjects, List<int> maxMarks) {
    final subjectController = TextEditingController();
    final marksController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Subject"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(
                labelText: "Subject Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: marksController,
              decoration: const InputDecoration(
                labelText: "Max Marks",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (subjectController.text.isNotEmpty && marksController.text.isNotEmpty) {
                setState(() {
                  subjects.add(subjectController.text);
                  maxMarks.add(int.parse(marksController.text));
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  // ================= DATABASE OPERATIONS =================
  Future<void> _saveExam(
      String name,
      String type,
      String className,
      DateTime startDate,
      DateTime endDate,
      List<String> subjects,
      List<int> maxMarks,
      ) async {
    setState(() => _isLoading = true);

    final examData = {
      'examName': name,
      'examType': type,
      'className': className,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'subjects': subjects,
      'maxMarks': maxMarks,
      'status': 'active',
      'marksEntered': 0,
      'totalMarks': subjects.length,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('exams')
        .add(examData);

    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Exam created successfully")),
    );
  }

  Future<void> _deleteExam(String examId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Exam"),
        content: const Text("Are you sure you want to delete this exam?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('schools')
                  .doc(widget.schoolId)
                  .collection('exams')
                  .doc(examId)
                  .delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Exam deleted")),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _enterMarks(String examId, Map<String, dynamic> examData, String subject, int subjectIndex) {
    showDialog(
      context: context,
      builder: (context) => _MarksEntryDialog(
        schoolId: widget.schoolId,
        examId: examId,
        examData: examData,
        subject: subject,
        maxMarks: examData['maxMarks'][subjectIndex],
      ),
    );
  }

  // ================= HELPER METHODS =================
  double _calculateProgress(Map<String, dynamic> data) {
    final entered = (data['marksEntered'] ?? 0).toDouble();
    final total = (data['totalMarks'] ?? 1).toDouble();
    return entered / total;
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    if (date is Timestamp) {
      return DateFormat('MMM dd, yyyy').format(date.toDate());
    }
    return date.toString();
  }

  Color _getExamTypeColor(String? type) {
    switch (type) {
      case 'Mid-term':
        return Colors.blue;
      case 'Final':
        return Colors.red;
      case 'Unit Test':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  void _viewExamDetails(String examId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['examName'] ?? 'Exam Details'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow("Exam Type", data['examType'] ?? 'N/A'),
              _infoRow("Class", data['className'] ?? 'N/A'),
              _infoRow("Start Date", _formatDate(data['startDate'])),
              _infoRow("End Date", _formatDate(data['endDate'])),
              const Divider(),
              const Text("Subjects:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...List.generate(data['subjects']?.length ?? 0, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text("• ${data['subjects'][index]}"),
                      const Spacer(),
                      Text("Max: ${data['maxMarks'][index]}"),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _viewResultDetails(String examId, Map<String, dynamic> data) {
    // Navigate to result details page
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Results"),
        content: const Text("Result details view - Coming Soon"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _editExam(String examId, Map<String, dynamic> data) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Edit feature coming soon")),
    );
  }

  void _exportResults() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Export feature coming soon")),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(": $value"),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
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

// ================= MARKS ENTRY DIALOG =================
class _MarksEntryDialog extends StatefulWidget {
  final String schoolId;
  final String examId;
  final Map<String, dynamic> examData;
  final String subject;
  final int maxMarks;

  const _MarksEntryDialog({
    required this.schoolId,
    required this.examId,
    required this.examData,
    required this.subject,
    required this.maxMarks,
  });

  @override
  State<_MarksEntryDialog> createState() => _MarksEntryDialogState();
}

class _MarksEntryDialogState extends State<_MarksEntryDialog> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final students = await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('students')
        .where('className', isEqualTo: widget.examData['className'])
        .get();

    for (var student in students.docs) {
      _controllers[student.id] = TextEditingController();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Enter Marks - ${widget.subject}"),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('students')
              .where('className', isEqualTo: widget.examData['className'])
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final students = snapshot.data!.docs;

            return ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                final data = student.data() as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text("${index + 1}"),
                    ),
                    title: Text(data['studentName'] ?? 'Unknown'),
                    subtitle: Text("Roll No: ${data['rollNo'] ?? 'N/A'}"),
                    trailing: SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _controllers[student.id],
                        decoration: InputDecoration(
                          labelText: "Marks",
                          suffixText: "/${widget.maxMarks}",
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _saveMarks,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text("Save All Marks"),
        ),
      ],
    );
  }

  Future<void> _saveMarks() async {
    setState(() => _isLoading = true);

    final batch = FirebaseFirestore.instance.batch();

    for (var entry in _controllers.entries) {
      final studentId = entry.key;
      final marks = int.tryParse(entry.value.text) ?? 0;

      final marksRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('exams')
          .doc(widget.examId)
          .collection('marks')
          .doc(studentId);

      batch.set(marksRef, {
        'subject': widget.subject,
        'marks': marks,
        'maxMarks': widget.maxMarks,
        'percentage': (marks / widget.maxMarks) * 100,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    // Update marks entered count
    final examRef = FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('exams')
        .doc(widget.examId);

    final examDoc = await examRef.get();
    final currentEntered = examDoc.data()?['marksEntered'] ?? 0;

    await examRef.update({
      'marksEntered': currentEntered + 1,
    });

    setState(() => _isLoading = false);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Marks saved successfully")),
    );
  }
}