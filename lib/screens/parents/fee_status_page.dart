import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../app_config.dart';

class FeeStatusPage extends StatefulWidget {
  final String? studentId;

  const FeeStatusPage({super.key, this.studentId});

  @override
  State<FeeStatusPage> createState() => _FeeStatusPageState();
}

class _FeeStatusPageState extends State<FeeStatusPage> {
  String? _selectedStudentId;
  String? _selectedStudentName;
  List<Map<String, dynamic>> _students = [];
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
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('students')
          .where('parentUid', isEqualTo: parentUid)
          .get();

      _students = studentsSnapshot.docs.map((doc) {
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
          // Manual search to avoid firstWhere issues
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading students: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
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
              "Fee Status",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_selectedStudentName != null && _selectedStudentName!.isNotEmpty)
              Text(
                _selectedStudentName!,
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadStudents(),
            tooltip: "Refresh",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
          ? _buildEmptyState()
          : Column(
        children: [
          if (_students.length > 1) _buildChildSelector(),
          Expanded(
            child: _buildFeeContent(),
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
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
          const Icon(Icons.switch_account, color: Colors.deepPurple, size: 20),
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
                hint: const Text("Select Child"),
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.deepPurple),
                items: _students.map<DropdownMenuItem<String>>((student) {
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

  Widget _buildFeeContent() {
    if (_selectedStudentId == null) {
      return const Center(child: Text("Select a student to view fee status"));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('student_fees')
          .where('studentId', isEqualTo: _selectedStudentId)
          .orderBy('dueDate', descending: false)
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
                Text(
                  "Error loading fee data",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
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
                Text(
                  "No fee records found",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  "Fee details will appear here once added",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        final fees = snapshot.data!.docs;

        double totalAmount = 0;
        double totalPaid = 0;

        for (var doc in fees) {
          final data = doc.data() as Map<String, dynamic>;
          final amount = (data['amount'] ?? 0).toDouble();
          final paidAmount = (data['paidAmount'] ?? 0).toDouble();
          totalAmount += amount;
          totalPaid += paidAmount;
        }
        final totalPending = totalAmount - totalPaid;

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSummaryCard(totalAmount, totalPending),
                const SizedBox(height: 24),
                _buildStudentInfoCard(),
                const SizedBox(height: 16),
                const Text(
                  "Fee Details",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...fees.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildFeeTile(data, doc.id);
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(double total, double pending) {
    final isAllPaid = pending == 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAllPaid
              ? [Colors.green, Colors.greenAccent]
              : [Colors.deepPurple, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.currency_rupee,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Total Fees",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      "₹${total.toStringAsFixed(0)}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isAllPaid ? Icons.check_circle : Icons.pending,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isAllPaid
                        ? "All fees cleared! 🎉"
                        : "Pending Amount: ₹${pending.toStringAsFixed(0)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
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

  Widget _buildStudentInfoCard() {
    // Manual search for student
    Map<String, dynamic>? student;
    for (var s in _students) {
      if (s['id'] == _selectedStudentId) {
        student = s;
        break;
      }
    }
    student ??= {'name': 'Student', 'class': '', 'section': '', 'rollNo': ''};

    return Container(
      padding: const EdgeInsets.all(16),
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
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.deepPurple.shade100,
            child: Text(
              (student!['name'] as String).isNotEmpty
                  ? (student['name'] as String)[0].toUpperCase()
                  : 'S',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Class ${student['class']} - ${student['section']} | Roll No: ${student['rollNo']}",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeTile(Map<String, dynamic> data, String docId) {
    final amount = (data['amount'] ?? 0).toDouble();
    final paidAmount = (data['paidAmount'] ?? 0).toDouble();
    final remainingAmount = amount - paidAmount;
    final status = data['status'] ?? 'pending';
    final feeType = data['feeType'] ?? 'Fee';
    final dueDate = data['dueDate'] != null
        ? (data['dueDate'] as Timestamp).toDate()
        : null;
    final description = data['description'] ?? '';

    final isOverdue = dueDate != null && dueDate.isBefore(DateTime.now()) && status != 'paid';

    Color getStatusColor() {
      if (status == 'paid') return Colors.green;
      if (status == 'partial') return Colors.orange;
      if (isOverdue) return Colors.red;
      return Colors.orange;
    }

    String getStatusText() {
      if (status == 'paid') return 'PAID';
      if (status == 'partial') return 'PARTIAL';
      if (isOverdue) return 'OVERDUE';
      return 'PENDING';
    }

    IconData getStatusIcon() {
      if (status == 'paid') return Icons.check_circle;
      if (status == 'partial') return Icons.pending;
      if (isOverdue) return Icons.warning;
      return Icons.access_time;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isOverdue
            ? BorderSide(color: Colors.red.shade300, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    feeType,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: getStatusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(getStatusIcon(), color: getStatusColor(), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        getStatusText(),
                        style: TextStyle(
                          color: getStatusColor(),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Amount",
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      Text(
                        "₹${amount.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (paidAmount > 0)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Paid",
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        Text(
                          "₹${paidAmount.toStringAsFixed(0)}",
                          style: TextStyle(
                            fontSize: 18,
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
                        Text(
                          "Remaining",
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        Text(
                          "₹${remainingAmount.toStringAsFixed(0)}",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: status == 'partial' ? Colors.orange : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (dueDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    "Due Date: ${DateFormat('dd MMM yyyy').format(dueDate)}",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  if (isOverdue)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "Overdue",
                          style: TextStyle(fontSize: 9, color: Colors.red.shade700),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
            if (status != 'paid') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showPaymentDialog(data, docId);
                  },
                  icon: const Icon(Icons.payment, size: 18),
                  label: const Text("Pay Now"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: getStatusColor(),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog(Map<String, dynamic> feeData, String feeId) {
    final amount = (feeData['amount'] ?? 0).toDouble();
    final paidAmount = (feeData['paidAmount'] ?? 0).toDouble();
    final remainingAmount = amount - paidAmount;
    final feeType = feeData['feeType'] ?? 'Fee';

    final TextEditingController amountController = TextEditingController(
      text: remainingAmount.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(Icons.payment, color: Colors.deepPurple),
            const SizedBox(width: 8),
            const Text("Make Payment"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    feeType,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Total: ₹${amount.toStringAsFixed(0)}",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  if (paidAmount > 0)
                    Text(
                      "Already Paid: ₹${paidAmount.toStringAsFixed(0)}",
                      style: TextStyle(fontSize: 12, color: Colors.green),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Amount to Pay",
                prefixText: "₹ ",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Payment gateway integration coming soon. This is a demo version.",
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Payment gateway integration coming soon"),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Proceed"),
          ),
        ],
      ),
    );
  }
}