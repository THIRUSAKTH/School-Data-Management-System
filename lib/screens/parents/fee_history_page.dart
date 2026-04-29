import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../app_config.dart';

class FeeHistoryPage extends StatefulWidget {
  final String? studentId;

  const FeeHistoryPage({super.key, this.studentId});

  @override
  State<FeeHistoryPage> createState() => _FeeHistoryPageState();
}

class _FeeHistoryPageState extends State<FeeHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedStudentId;
  String? _selectedStudentName;
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStudents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final parentUid = FirebaseAuth.instance.currentUser!.uid;
      final studentsSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('students')
              .where('parentUid', isEqualTo: parentUid)
              .get();

      _students =
          studentsSnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'name': data['name'] ?? 'Student',
              'class': data['class'] ?? '',
              'section': data['section'] ?? '',
              'rollNo': data['rollNo'] ?? '',
            };
          }).toList();

      if (_students.isNotEmpty) {
        if (widget.studentId != null) {
          Map<String, dynamic>? matchingStudent;
          for (var student in _students) {
            if (student['id'] == widget.studentId) {
              matchingStudent = student;
              break;
            }
          }
          matchingStudent ??= _students.first;

          _selectedStudentId = matchingStudent['id'];
          _selectedStudentName = matchingStudent['name'];
        } else {
          _selectedStudentId = _students.first['id'];
          _selectedStudentName = _students.first['name'];
        }
      }
    } catch (e) {
      debugPrint('Error loading students: $e');
      setState(() {
        _errorMessage = 'Error loading students: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Fee History",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_selectedStudentName != null &&
                _selectedStudentName!.isNotEmpty)
              Text(_selectedStudentName!, style: const TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.receipt), text: "All Fees"),
            Tab(icon: Icon(Icons.summarize), text: "Summary"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadStudents(),
            tooltip: "Refresh",
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _students.isEmpty
              ? _buildEmptyState()
              : Column(
                children: [
                  if (_students.length > 1) _buildStudentSelector(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [_buildAllFeesTab(), _buildSummaryTab()],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No Students Linked",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Please contact the school admin to link your children.",
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentSelector() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      child: Row(
        children: [
          const Icon(Icons.switch_account, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          const Text(
            "Child:",
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedStudentId,
                hint: const Text("Choose Student"),
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
                items:
                    _students.map<DropdownMenuItem<String>>((student) {
                      return DropdownMenuItem<String>(
                        value: student['id'] as String,
                        child: Text(
                          "${student['name']} (${student['class']} - ${student['section']})",
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedStudentId = value;
                    for (var student in _students) {
                      if (student['id'] == value) {
                        _selectedStudentName = student['name'];
                        break;
                      }
                    }
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // FIXED: Removed orderBy to avoid index requirement
  Widget _buildAllFeesTab() {
    if (_selectedStudentId == null) {
      return const Center(child: Text("Select a student to view fees"));
    }

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('student_fees')
              .where('studentId', isEqualTo: _selectedStudentId)
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
                const Text(
                  "Error loading fee data",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Please create Firebase index or contact admin",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _loadStudents(),
                  icon: const Icon(Icons.refresh),
                  label: const Text("Retry"),
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
                Icon(Icons.receipt, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text(
                  "No fee records found",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Fee details will appear here once added",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final fees = snapshot.data!.docs;
        // Sort client-side
        fees.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aDate = aData['dueDate'] as Timestamp?;
          final bDate = bData['dueDate'] as Timestamp?;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.toDate().compareTo(aDate.toDate());
        });

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: fees.length,
            itemBuilder: (context, index) {
              final doc = fees[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildFeeCard(data, doc.id);
            },
          ),
        );
      },
    );
  }

  Widget _buildFeeCard(Map<String, dynamic> data, String docId) {
    final amount = (data['amount'] ?? 0).toDouble();
    final paidAmount = (data['paidAmount'] ?? 0).toDouble();
    final remainingAmount = amount - paidAmount;
    final status = data['status'] ?? 'pending';
    final feeType = data['feeType'] ?? 'Fee';
    final dueDate =
        data['dueDate'] != null
            ? (data['dueDate'] as Timestamp).toDate()
            : null;
    final paymentDate =
        data['paymentDate'] != null
            ? (data['paymentDate'] as Timestamp).toDate()
            : null;

    final isOverdue =
        dueDate != null && dueDate.isBefore(DateTime.now()) && status != 'paid';

    Color getStatusColor() {
      if (status == 'paid') return Colors.green;
      if (status == 'partial') return Colors.orange;
      return isOverdue ? Colors.red : Colors.orange;
    }

    IconData getStatusIcon() {
      if (status == 'paid') return Icons.check_circle;
      if (status == 'partial') return Icons.pending;
      return isOverdue ? Icons.warning : Icons.access_time;
    }

    String getStatusText() {
      if (status == 'paid') return 'Paid';
      if (status == 'partial') return 'Partial';
      return isOverdue ? 'Overdue' : 'Pending';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:
            isOverdue
                ? BorderSide(color: Colors.red.shade300, width: 1.5)
                : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showFeeDetails(data, docId),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      getStatusIcon(),
                      color: getStatusColor(),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feeType,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          dueDate != null
                              ? "Due: ${DateFormat('dd MMM yyyy').format(dueDate)}"
                              : "No due date",
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                isOverdue ? Colors.red : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      getStatusText(),
                      style: TextStyle(
                        color: getStatusColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Total",
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        Text(
                          "₹${amount.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (paidAmount > 0)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            "Paid",
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          Text(
                            "₹${paidAmount.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (remainingAmount > 0)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "Remaining",
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          Text(
                            "₹${remainingAmount.toStringAsFixed(0)}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color:
                                  status == 'partial'
                                      ? Colors.orange
                                      : Colors.red,
                            ),
                          ),
                        ],
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

  // FIXED: Removed orderBy to avoid index requirement
  Widget _buildSummaryTab() {
    if (_selectedStudentId == null) {
      return const Center(child: Text("Select a student to view summary"));
    }

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('schools')
              .doc(AppConfig.schoolId)
              .collection('student_fees')
              .where('studentId', isEqualTo: _selectedStudentId)
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
                const Text("Error loading summary"),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No fee records found"));
        }

        final fees = snapshot.data!.docs;

        double totalAmount = 0;
        double totalPaid = 0;
        int paidCount = 0;
        int pendingCount = 0;
        int partialCount = 0;
        int overdueCount = 0;

        for (var doc in fees) {
          final data = doc.data() as Map<String, dynamic>;
          final amount = (data['amount'] ?? 0).toDouble();
          final paidAmount = (data['paidAmount'] ?? 0).toDouble();
          final status = data['status'] ?? 'pending';
          final dueDate =
              data['dueDate'] != null
                  ? (data['dueDate'] as Timestamp).toDate()
                  : null;

          totalAmount += amount;
          totalPaid += paidAmount;

          if (status == 'paid') {
            paidCount++;
          } else if (status == 'partial') {
            partialCount++;
          } else {
            pendingCount++;
            if (dueDate != null && dueDate.isBefore(DateTime.now())) {
              overdueCount++;
            }
          }
        }

        final totalPending = totalAmount - totalPaid;
        final collectionRate =
            totalAmount > 0 ? (totalPaid / totalAmount) * 100 : 0.0;

        Map<String, dynamic>? student;
        for (var s in _students) {
          if (s['id'] == _selectedStudentId) {
            student = s;
            break;
          }
        }
        student ??= {
          'name': 'Student',
          'class': '',
          'section': '',
          'rollNo': '',
        };

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildStudentInfoCard(
                  student!['name'],
                  student['class'],
                  student['section'],
                  student['rollNo'],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        "Total",
                        "₹${totalAmount.toStringAsFixed(0)}",
                        Colors.blue,
                        Icons.account_balance_wallet,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryCard(
                        "Paid",
                        "₹${totalPaid.toStringAsFixed(0)}",
                        Colors.green,
                        Icons.check_circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryCard(
                        "Pending",
                        "₹${totalPending.toStringAsFixed(0)}",
                        Colors.red,
                        Icons.pending,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildCollectionRateCard(collectionRate),
                const SizedBox(height: 12),
                _buildFeeBreakdownCard(
                  paidCount,
                  pendingCount,
                  partialCount,
                  overdueCount,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStudentInfoCard(
    String name,
    String className,
    String section,
    String rollNo,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blue, Colors.lightBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white,
            child: Icon(Icons.school, color: Colors.blue, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Fee Summary for",
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Class $className-$section | Roll No: $rollNo",
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionRateCard(double collectionRate) {
    Color getRateColor() {
      if (collectionRate >= 90) return Colors.green;
      if (collectionRate >= 70) return Colors.orange;
      return Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Collection Rate",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: (collectionRate / 100).toDouble(),
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(getRateColor()),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "${collectionRate.toStringAsFixed(1)}%",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: getRateColor(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeeBreakdownCard(
    int paidCount,
    int pendingCount,
    int partialCount,
    int overdueCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Fee Breakdown",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _breakdownRow("Paid Fees", paidCount, Colors.green),
          _breakdownRow("Pending Fees", pendingCount, Colors.red),
          if (overdueCount > 0)
            _breakdownRow(
              "Overdue Fees",
              overdueCount,
              Colors.red,
              isOverdue: true,
            ),
          if (partialCount > 0)
            _breakdownRow("Partial Payments", partialCount, Colors.orange),
        ],
      ),
    );
  }

  Widget _breakdownRow(
    String label,
    int count,
    Color color, {
    bool isOverdue = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isOverdue ? Colors.red : Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            count.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showFeeDetails(Map<String, dynamic> data, String docId) {
    final amount = (data['amount'] ?? 0).toDouble();
    final paidAmount = (data['paidAmount'] ?? 0).toDouble();
    final remainingAmount = amount - paidAmount;
    final status = data['status'] ?? 'pending';
    final feeType = data['feeType'] ?? 'Fee';
    final dueDate =
        data['dueDate'] != null
            ? (data['dueDate'] as Timestamp).toDate()
            : null;
    final paymentDate =
        data['paymentDate'] != null
            ? (data['paymentDate'] as Timestamp).toDate()
            : null;
    final description = data['description'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
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
                              color:
                                  status == 'paid'
                                      ? Colors.green.shade100
                                      : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              status == 'paid' ? Icons.check : Icons.pending,
                              color:
                                  status == 'paid' ? Colors.green : Colors.red,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  feeType,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "Status: ${status.toUpperCase()}",
                                  style: TextStyle(
                                    color:
                                        status == 'paid'
                                            ? Colors.green
                                            : Colors.red,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      _detailRow(
                        "Total Amount",
                        "₹${amount.toStringAsFixed(0)}",
                      ),
                      if (paidAmount > 0)
                        _detailRow(
                          "Paid Amount",
                          "₹${paidAmount.toStringAsFixed(0)}",
                        ),
                      if (remainingAmount > 0)
                        _detailRow(
                          "Remaining Amount",
                          "₹${remainingAmount.toStringAsFixed(0)}",
                        ),
                      if (dueDate != null)
                        _detailRow(
                          "Due Date",
                          DateFormat('dd MMM yyyy').format(dueDate),
                        ),
                      if (paymentDate != null)
                        _detailRow(
                          "Payment Date",
                          DateFormat('dd MMM yyyy').format(paymentDate),
                        ),
                      if (description.isNotEmpty)
                        _detailRow("Description", description),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text("Close"),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
