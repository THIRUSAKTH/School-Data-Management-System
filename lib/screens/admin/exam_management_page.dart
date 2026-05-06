import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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

  final List<String> _months = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  ];

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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Export feature coming soon")),
              );
            },
            tooltip: "Export Results",
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildExamsList(), _buildMarksEntry(), _buildResultsView()],
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
      stream:
          FirebaseFirestore.instance
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

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final exam = snapshot.data!.docs[index];
              final data = exam.data() as Map<String, dynamic>;
              return _buildExamCard(exam.id, data);
            },
          ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _formatDate(data['startDate']),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 12, color: Colors.grey),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _formatDate(data['endDate']),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.class_, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        data['className'] ?? 'All Classes',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.subject, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        "${data['subjects']?.length ?? 0} Subjects",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
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
                      "${data['marksEntered'] ?? 0}/${data['totalMarks'] ?? 0} Subjects",
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
      stream:
          FirebaseFirestore.instance
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
                Icon(Icons.edit_note, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  "No Exams Created",
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

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: exams.length,
            itemBuilder: (context, index) {
              final exam = exams[index];
              final data = exam.data() as Map<String, dynamic>;
              return _buildMarksEntryCard(exam.id, data);
            },
          ),
        );
      },
    );
  }

  Widget _buildMarksEntryCard(String examId, Map<String, dynamic> data) {
    final subjects = List<String>.from(data['subjects'] ?? []);
    final maxMarksRaw = data['maxMarks'] ?? [];
    final List<int> maxMarks =
        maxMarksRaw.map<int>((e) => (e as num).toInt()).toList();

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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "${data['className'] ?? 'Class'} - ${data['examType'] ?? 'Exam'}",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              "Subjects",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...List.generate(subjects.length, (index) {
              final isCompleted =
                  data['completedSubjects']?.contains(subjects[index]) ?? false;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      isCompleted ? Colors.green.shade100 : Colors.blue.shade50,
                  child: Icon(
                    isCompleted ? Icons.check : Icons.edit,
                    size: 18,
                    color: isCompleted ? Colors.green : Colors.blue,
                  ),
                ),
                title: Text(subjects[index]),
                subtitle: Text("Max Marks: ${maxMarks[index]}"),
                trailing: ElevatedButton(
                  onPressed:
                      () => _enterMarks(
                        examId,
                        data,
                        subjects[index],
                        maxMarks[index],
                        index,
                      ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCompleted ? Colors.green : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isCompleted ? "Edit" : "Enter Marks"),
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
      stream:
          FirebaseFirestore.instance
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

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: exams.length,
            itemBuilder: (context, index) {
              final exam = exams[index];
              final data = exam.data() as Map<String, dynamic>;
              return _buildResultCard(exam.id, data);
            },
          ),
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
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${data['className'] ?? 'Class'} • ${data['examType'] ?? 'Exam'}",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // FIXED: Wrapped the status container in a Flexible widget
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      overflow: TextOverflow.ellipsis,
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
                    onPressed: () => _viewFullResults(examId, data),
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
  // ================= RESULT DETAILS PAGE =================
  void _viewFullResults(String examId, Map<String, dynamic> examData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ExamResultDetailsPage(
              schoolId: widget.schoolId,
              examId: examId,
              examData: examData,
            ),
      ),
    );
  }

  // ================= FIXED DIALOGS WITH WORKING CLASS SELECTION =================
  void _createExamDialog() {
    final formKey = GlobalKey<FormState>();
    String examName = '';
    String examType = 'Mid-term';
    String className = '';
    List<String> subjects = [];
    List<int> maxMarks = [];
    int selectedMonth = DateTime.now().month;
    int selectedYear = DateTime.now().year;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text("Create New Exam"),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
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
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        onSaved: (value) => examName = value!,
                        validator: (value) => value?.isEmpty == true ? "Required" : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: examType,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: "Exam Type",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                      // FIXED: Class Dropdown with proper width constraints
                      Container(
                        constraints: const BoxConstraints(minHeight: 70),
                        child: FutureBuilder<QuerySnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('schools')
                              .doc(widget.schoolId)
                              .collection('classes')
                              .get(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return DropdownButtonFormField<String>(
                                items: [],
                                onChanged: null,
                                decoration: InputDecoration(
                                  labelText: "Class",
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.class_),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                hint: Text("Loading classes..."),
                              );
                            }

                            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return Column(
                                children: [
                                  DropdownButtonFormField<String>(
                                    items: [],
                                    onChanged: null,
                                    decoration: InputDecoration(
                                      labelText: "Class",
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.class_),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    ),
                                    hint: Text("No classes available"),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Please create classes in Class Management section first"),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text("Create Class First", style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              );
                            }

                            final classes = snapshot.data!.docs;
                            final classNames = classes.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return data['class'] ?? data['className'] ?? '';
                            }).where((name) => name.isNotEmpty).toList();

                            return DropdownButtonFormField<String>(
                              value: className.isEmpty ? null : className,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: "Select Class",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.class_),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              items: [
                                const DropdownMenuItem<String>(value: null, child: Text("Select Class")),
                                ...classNames.map((name) {
                                  return DropdownMenuItem<String>(
                                    value: name,
                                    child: Text(name),
                                  );
                                }).toList(),
                              ],
                              onChanged: (value) => setState(() => className = value!),
                              validator: (value) => value == null ? "Please select a class" : null,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      // FIXED: Month and Year Row with proper container constraints
                      Container(
                        constraints: const BoxConstraints(minHeight: 70),
                        child: Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: selectedMonth,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: "Month",
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_month),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                items: List.generate(12, (i) {
                                  return DropdownMenuItem<int>(
                                    value: i + 1,
                                    child: Container(
                                      constraints: const BoxConstraints(maxWidth: 100),
                                      child: Text(
                                        _months[i],
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  );
                                }),
                                onChanged: (v) => setState(() => selectedMonth = v!),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: selectedYear,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: "Year",
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_today),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                items: [
                                  for (int i = -2; i <= 3; i++)
                                    DropdownMenuItem<int>(
                                      value: DateTime.now().year + i,
                                      child: Text((DateTime.now().year + i).toString()),
                                    ),
                                ],
                                onChanged: (v) => setState(() => selectedYear = v!),
                              ),
                            ),
                          ],
                        ),
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
                            borderRadius: BorderRadius.circular(12),
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
                    final startDate = DateTime(selectedYear, selectedMonth, 1);
                    final lastDay = DateTime(selectedYear, selectedMonth + 1, 0);
                    final endDate = DateTime(selectedYear, selectedMonth, lastDay.day);

                    await _saveExam(
                      examName, examType, className, startDate, endDate, subjects, maxMarks,
                    );
                    if (mounted) {
                      Navigator.pop(context);
                    }
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
  void _addSubjectsDialog(
    StateSetter setState,
    List<String> subjects,
    List<int> maxMarks,
  ) {
    final subjectController = TextEditingController();
    final marksController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text("Add Subject"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(
                    labelText: "Subject Name",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: marksController,
                  decoration: const InputDecoration(
                    labelText: "Max Marks",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
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
                  if (subjectController.text.isNotEmpty &&
                      marksController.text.isNotEmpty) {
                    setState(() {
                      subjects.add(subjectController.text);
                      maxMarks.add(int.parse(marksController.text));
                    });
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Please enter both subject name and max marks",
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
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
      'completedSubjects': [],
      'totalMarks': subjects.length,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('exams')
        .add(examData);

    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Exam created successfully"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteExam(String examId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text("Delete Exam"),
            content: const Text(
              "Are you sure you want to delete this exam? This action cannot be undone.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text("Delete"),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolId)
            .collection('exams')
            .doc(examId)
            .delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Exam deleted successfully"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error deleting exam: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _enterMarks(
    String examId,
    Map<String, dynamic> examData,
    String subject,
    int maxMarks,
    int subjectIndex,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MarksEntryPage(
              schoolId: widget.schoolId,
              examId: examId,
              examData: examData,
              subject: subject,
              maxMarks: maxMarks,
              subjectIndex: subjectIndex,
            ),
      ),
    ).then((_) => setState(() {}));
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
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
                  const Text(
                    "Subjects:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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

  void _editExam(String examId, Map<String, dynamic> data) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Edit feature coming soon")));
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
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}

// ================= MARKS ENTRY PAGE =================
class MarksEntryPage extends StatefulWidget {
  final String schoolId;
  final String examId;
  final Map<String, dynamic> examData;
  final String subject;
  final int maxMarks;
  final int subjectIndex;

  const MarksEntryPage({
    super.key,
    required this.schoolId,
    required this.examId,
    required this.examData,
    required this.subject,
    required this.maxMarks,
    required this.subjectIndex,
  });

  @override
  State<MarksEntryPage> createState() => _MarksEntryPageState();
}

class _MarksEntryPageState extends State<MarksEntryPage> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _remarks = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final studentsSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('students')
              .where('class', isEqualTo: widget.examData['className'])
              .get();

      if (studentsSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No students found in this class"),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final marksSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('exams')
              .doc(widget.examId)
              .collection('marks')
              .where('subject', isEqualTo: widget.subject)
              .get();

      for (var student in studentsSnapshot.docs) {
        final studentId = student.id;
        _controllers[studentId] = TextEditingController();

        final existingMark = marksSnapshot.docs.firstWhere(
          (doc) => doc.id == studentId,
          orElse: () => null as dynamic,
        );

        if (existingMark != null) {
          final markData = existingMark.data() as Map<String, dynamic>;
          _controllers[studentId]?.text = markData['marks']?.toString() ?? '';
          _remarks[studentId] = markData['remark'] ?? '';
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading data: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text("Enter Marks - ${widget.subject}"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveMarks,
            tooltip: "Save All",
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('schools')
                        .doc(widget.schoolId)
                        .collection('students')
                        .where('class', isEqualTo: widget.examData['className'])
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text("No students found in this class"),
                        ],
                      ),
                    );
                  }

                  final students = snapshot.data!.docs;

                  return RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        final data = student.data() as Map<String, dynamic>;
                        final studentId = student.id;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.blue.shade100,
                                      child: Text(
                                        data['rollNo']?.toString() ?? '?',
                                        style: TextStyle(
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data['name'] ?? 'Unknown',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            "Roll No: ${data['rollNo'] ?? 'N/A'}",
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _controllers[studentId],
                                        decoration: InputDecoration(
                                          labelText: "Marks Obtained",
                                          suffixText: "/${widget.maxMarks}",
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextField(
                                        onChanged:
                                            (value) =>
                                                _remarks[studentId] = value,
                                        decoration: InputDecoration(
                                          labelText: "Remarks (Optional)",
                                          hintText:
                                              "e.g., Excellent, Needs Improvement",
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveMarks,
            icon:
                _isSaving
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : const Icon(Icons.save),
            label: Text(_isSaving ? "Saving..." : "Save All Marks"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveMarks() async {
    setState(() => _isSaving = true);

    try {
      final batch = FirebaseFirestore.instance.batch();

      for (var entry in _controllers.entries) {
        final studentId = entry.key;
        final marksText = entry.value.text.trim();

        if (marksText.isEmpty) continue;

        final marks = int.tryParse(marksText);
        if (marks == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Invalid marks for student"),
              backgroundColor: Colors.orange,
            ),
          );
          continue;
        }

        final percentage = (marks / widget.maxMarks) * 100;
        final grade = _calculateGrade(percentage);

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
          'percentage': percentage,
          'grade': grade,
          'remark': _remarks[studentId] ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      final examRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('exams')
          .doc(widget.examId);

      final examDoc = await examRef.get();
      List<String> completedSubjects = List.from(
        examDoc.data()?['completedSubjects'] ?? [],
      );

      if (!completedSubjects.contains(widget.subject)) {
        completedSubjects.add(widget.subject);
        await examRef.update({
          'completedSubjects': completedSubjects,
          'marksEntered': completedSubjects.length,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Marks saved successfully"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  String _calculateGrade(double percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B';
    if (percentage >= 60) return 'C';
    if (percentage >= 50) return 'D';
    return 'F';
  }
}

// ================= EXAM RESULT DETAILS PAGE =================
class ExamResultDetailsPage extends StatefulWidget {
  final String schoolId;
  final String examId;
  final Map<String, dynamic> examData;

  const ExamResultDetailsPage({
    super.key,
    required this.schoolId,
    required this.examId,
    required this.examData,
  });

  @override
  State<ExamResultDetailsPage> createState() => _ExamResultDetailsPageState();
}

class _ExamResultDetailsPageState extends State<ExamResultDetailsPage> {
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    try {
      final studentsSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('students')
              .where('class', isEqualTo: widget.examData['className'])
              .get();

      final marksSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('exams')
              .doc(widget.examId)
              .collection('marks')
              .get();

      final subjects = List<String>.from(widget.examData['subjects'] ?? []);
      final maxMarksRaw = widget.examData['maxMarks'] ?? [];
      final List<int> maxMarks =
          maxMarksRaw.map<int>((e) => (e as num).toInt()).toList();

      List<Map<String, dynamic>> results = [];

      for (var student in studentsSnapshot.docs) {
        final studentData = student.data();
        final studentId = student.id;

        Map<String, dynamic> subjectMarks = {};
        int totalObtained = 0;
        int totalMax = 0;

        for (int i = 0; i < subjects.length; i++) {
          final subject = subjects[i];
          final maxMark = maxMarks[i];

          Map<String, dynamic>? markData;
          for (var doc in marksSnapshot.docs) {
            final docData = doc.data() as Map<String, dynamic>;
            if (doc.id == studentId && docData['subject'] == subject) {
              markData = docData;
              break;
            }
          }

          int obtained = 0;
          String grade = 'N/A';

          if (markData != null) {
            obtained = (markData['marks'] ?? 0) as int;
            grade = markData['grade'] ?? 'N/A';
            totalObtained += obtained;
            totalMax += maxMark;
          }

          final double percentage =
              maxMark > 0 ? (obtained / maxMark) * 100 : 0.0;

          subjectMarks[subject] = {
            'obtained': obtained,
            'max': maxMark,
            'percentage': percentage,
            'grade': grade,
          };
        }

        final double overallPercentage =
            totalMax > 0 ? (totalObtained / totalMax) * 100 : 0.0;
        final String overallGrade = _calculateGrade(overallPercentage);

        results.add({
          'studentId': studentId,
          'name': studentData['name'] ?? 'Unknown',
          'rollNo': studentData['rollNo'] ?? '',
          'subjectMarks': subjectMarks,
          'totalObtained': totalObtained,
          'totalMax': totalMax,
          'overallPercentage': overallPercentage,
          'overallGrade': overallGrade,
        });
      }

      results.sort(
        (a, b) => (b['overallPercentage'] as double).compareTo(
          a['overallPercentage'] as double,
        ),
      );

      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading results: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading results: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _calculateGrade(double percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B';
    if (percentage >= 60) return 'C';
    if (percentage >= 50) return 'D';
    return 'F';
  }

  Future<void> _exportPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header:
            (context) => pw.Column(
              children: [
                pw.Text(
                  'Exam Results - ${widget.examData['examName']}',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  '${widget.examData['className']} • ${widget.examData['examType']}',
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.Divider(),
              ],
            ),
        build:
            (context) => [
              pw.SizedBox(height: 20),
              pw.Text(
                'Result Summary',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      _pdfHeaderCell('Rank'),
                      _pdfHeaderCell('Roll No'),
                      _pdfHeaderCell('Student Name'),
                      _pdfHeaderCell('Total'),
                      _pdfHeaderCell('Percentage'),
                      _pdfHeaderCell('Grade'),
                    ],
                  ),
                  ..._results.asMap().entries.map((entry) {
                    final index = entry.key;
                    final result = entry.value;
                    return pw.TableRow(
                      children: [
                        _pdfCell('${index + 1}'),
                        _pdfCell(result['rollNo'].toString()),
                        _pdfCell(result['name']),
                        _pdfCell(
                          '${result['totalObtained']}/${result['totalMax']}',
                        ),
                        _pdfCell(
                          '${(result['overallPercentage'] as double).toStringAsFixed(1)}%',
                        ),
                        _pdfCell(result['overallGrade']),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ],
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  pw.Widget _pdfHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
    );
  }

  pw.Widget _pdfCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text("Results - ${widget.examData['examName']}"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportPDF,
            tooltip: "Export PDF",
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _results.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assessment, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      "No results available",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadResults,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final result = _results[index];
                    final rank = index + 1;
                    final percentage = result['overallPercentage'] as double;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ExpansionTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color:
                                rank <= 3
                                    ? Colors.amber.shade100
                                    : Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              rank.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color:
                                    rank <= 3
                                        ? Colors.amber.shade800
                                        : Colors.blue,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          result['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("Roll No: ${result['rollNo']}"),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: percentage >= 60 ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            result['overallGrade'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _statItem(
                                        "Total",
                                        "${result['totalObtained']}/${result['totalMax']}",
                                      ),
                                      _statItem(
                                        "Percentage",
                                        "${percentage.toStringAsFixed(1)}%",
                                      ),
                                      _statItem(
                                        "Grade",
                                        result['overallGrade'],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "Subject-wise Marks",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                ...List.generate(
                                  (result['subjectMarks'] as Map).keys.length,
                                  (subIndex) {
                                    final subject = (result['subjectMarks']
                                            as Map)
                                        .keys
                                        .elementAt(subIndex);
                                    final marks =
                                        result['subjectMarks'][subject];
                                    final percentage =
                                        marks['percentage'] as double;
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color:
                                            percentage >= 60
                                                ? Colors.green.shade50
                                                : Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              subject,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            "${marks['obtained']}/${marks['max']}",
                                          ),
                                          const SizedBox(width: 16),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  percentage >= 60
                                                      ? Colors.green
                                                      : Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              marks['grade'],
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
