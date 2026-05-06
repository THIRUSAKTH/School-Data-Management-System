import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:schoolprojectjan/app_config.dart';

class AdminFeeUploadPage extends StatefulWidget {
  final String schoolId;

  const AdminFeeUploadPage({super.key, required this.schoolId});

  @override
  State<AdminFeeUploadPage> createState() => _AdminFeeUploadPageState();
}

class _AdminFeeUploadPageState extends State<AdminFeeUploadPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _individualAmountController =
      TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  String _selectedClass = "Class 6";
  String _selectedSection = "A";
  String _selectedFeeType = "Tuition Fee";
  DateTime? _dueDate;
  bool _isRecurring = false;
  String _recurringPeriod = "Monthly";
  double _lateFee = 0;
  double _bulkDiscount = 0;

  int _studentCount = 0;
  double _totalAmount = 0;
  bool _isLoading = false;

  // Individual fee adjustment
  String? _selectedStudentId;
  String? _selectedStudentName;
  List<Map<String, dynamic>> _studentsInClass = [];

  final List<String> _classes = [
    "LKG",
    "UKG",
    "Class 1",
    "Class 2",
    "Class 3",
    "Class 4",
    "Class 5",
    "Class 6",
    "Class 7",
    "Class 8",
    "Class 9",
    "Class 10",
  ];

  final List<String> _sections = ["A", "B", "C", "D"];

  final List<String> _feeTypes = [
    "Tuition Fee",
    "Exam Fee",
    "Transport Fee",
    "Library Fee",
    "Sports Fee",
    "Development Fee",
    "Activity Fee",
    "Other",
  ];

  final List<String> _recurringPeriods = [
    "Monthly",
    "Quarterly",
    "Half-Yearly",
    "Yearly",
  ];

  final List<String> _adjustmentTypes = [
    "Discount",
    "Concession",
    "Scholarship",
    "Fine",
    "Late Fee",
    "Other",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStudentCount();
    _loadStudentsInClass();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _individualAmountController.dispose();
    _discountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentCount() async {
    try {
      final studentsSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('students')
              .where('class', isEqualTo: _selectedClass)
              .where('section', isEqualTo: _selectedSection)
              .get();

      setState(() {
        _studentCount = studentsSnapshot.docs.length;
      });
    } catch (e) {
      debugPrint('Error loading student count: $e');
    }
  }

  Future<void> _loadStudentsInClass() async {
    try {
      final studentsSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('students')
              .where('class', isEqualTo: _selectedClass)
              .where('section', isEqualTo: _selectedSection)
              .get();

      setState(() {
        _studentsInClass =
            studentsSnapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'name': data['name'] ?? 'Unknown',
                'rollNo': data['rollNo'] ?? '',
              };
            }).toList();
      });
    } catch (e) {
      debugPrint('Error loading students: $e');
    }
  }

  void _updateTotal() {
    if (_amountController.text.isNotEmpty) {
      double amount = double.tryParse(_amountController.text) ?? 0;
      setState(() {
        _totalAmount =
            (amount * _studentCount) - (_bulkDiscount * _studentCount);
      });
    } else {
      setState(() {
        _totalAmount = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text("Fee Management"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.upload_file), text: "Bulk Upload"),
            Tab(icon: Icon(Icons.person), text: "Individual"),
            Tab(icon: Icon(Icons.history), text: "History"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadStudentCount();
              _updateTotal();
              _loadStudentsInClass();
            },
            tooltip: "Refresh",
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBulkUploadTab(),
          _buildIndividualTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  // ================= BULK UPLOAD TAB =================
  Widget _buildBulkUploadTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 20),
          _buildClassSectionCard(),
          const SizedBox(height: 16),
          _buildStudentCountCard(),
          const SizedBox(height: 16),
          _buildBulkFeeDetailsCard(),
          const SizedBox(height: 16),
          _buildBulkAdditionalOptionsCard(),
          const SizedBox(height: 16),
          _buildBulkSummaryCard(),
          const SizedBox(height: 24),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  // ================= INDIVIDUAL TAB =================
  Widget _buildIndividualTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIndividualHeaderCard(),
          const SizedBox(height: 20),
          _buildIndividualStudentSelector(),
          const SizedBox(height: 16),
          _buildStudentCurrentFeesCard(),
          const SizedBox(height: 16),
          _buildIndividualFeeCard(),
          const SizedBox(height: 24),
          _buildIndividualSubmitButton(),
        ],
      ),
    );
  }

  // ================= HISTORY TAB =================
  Widget _buildHistoryTab() {
    return _buildFeeHistory();
  }

  // ================= BULK UPLOAD WIDGETS =================
  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.deepPurple, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Bulk Fee Upload",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Publish fees for an entire class at once",
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassSectionCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Select Class & Section", Icons.class_),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _dropdown("Class", _selectedClass, _classes, (v) {
                  setState(() {
                    _selectedClass = v;
                  });
                  _loadStudentCount();
                  _loadStudentsInClass();
                  _updateTotal();
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dropdown("Section", _selectedSection, _sections, (v) {
                  setState(() {
                    _selectedSection = v;
                  });
                  _loadStudentCount();
                  _loadStudentsInClass();
                  _updateTotal();
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCountCard() {
    return _card(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.people, color: Colors.deepPurple),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Students in this class",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  "$_studentCount Students",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (_studentCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Active",
                style: TextStyle(fontSize: 11, color: Colors.green.shade700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBulkFeeDetailsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Fee Details", Icons.receipt),
          const SizedBox(height: 16),
          _dropdown(
            "Fee Type",
            _selectedFeeType,
            _feeTypes,
            (v) => setState(() => _selectedFeeType = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            onChanged: (value) => _updateTotal(),
            decoration: InputDecoration(
              labelText: "Amount per Student (₹)",
              prefixIcon: const Icon(Icons.currency_rupee),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.deepPurple,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: "Description (Optional)",
              hintText: "e.g., Annual fee for 2024-2025",
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.deepPurple,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _datePicker(),
        ],
      ),
    );
  }

  Widget _buildBulkAdditionalOptionsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Additional Options", Icons.settings),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text("Recurring Fee"),
            subtitle: const Text("Auto-generate fee for future periods"),
            value: _isRecurring,
            onChanged: (value) {
              setState(() {
                _isRecurring = value;
              });
            },
            activeColor: Colors.deepPurple,
            contentPadding: EdgeInsets.zero,
          ),
          if (_isRecurring) ...[
            const SizedBox(height: 8),
            _dropdown(
              "Recurring Period",
              _recurringPeriod,
              _recurringPeriods,
              (v) => setState(() => _recurringPeriod = v),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _lateFee = double.tryParse(value) ?? 0;
              });
            },
            decoration: InputDecoration(
              labelText: "Late Fee (₹) - Per Day After Due Date",
              prefixIcon: const Icon(Icons.warning_amber),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _bulkDiscount = double.tryParse(value) ?? 0;
              });
              _updateTotal();
            },
            decoration: InputDecoration(
              labelText: "Discount per Student (₹) - Bulk",
              prefixIcon: const Icon(Icons.local_offer),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkSummaryCard() {
    double amountPerStudent = double.tryParse(_amountController.text) ?? 0;
    double totalAfterDiscount = _totalAmount;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Summary", Icons.summarize),
          const SizedBox(height: 16),
          _summaryRow("Fee Type", _selectedFeeType),
          _summaryRow("Class/Section", "$_selectedClass - $_selectedSection"),
          _summaryRow("Students", _studentCount.toString()),
          _summaryRow(
            "Amount per Student",
            "₹${amountPerStudent.toStringAsFixed(0)}",
          ),
          if (_bulkDiscount > 0)
            _summaryRow(
              "Discount per Student",
              "-₹${_bulkDiscount.toStringAsFixed(0)}",
            ),
          const Divider(),
          _summaryRow(
            "Total Amount",
            "₹${totalAfterDiscount.toStringAsFixed(0)}",
            isBold: true,
            color: Colors.deepPurple,
          ),
          if (_dueDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _summaryRow(
                "Due Date",
                DateFormat('dd MMM yyyy').format(_dueDate!),
              ),
            ),
          if (_lateFee > 0)
            _summaryRow(
              "Late Fee",
              "₹${_lateFee.toStringAsFixed(0)} per day after due date",
            ),
        ],
      ),
    );
  }

  // ================= INDIVIDUAL FEE WIDGETS =================
  Widget _buildIndividualHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.deepPurple, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Individual Fee Adjustment",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            "Add discounts, concessions, or adjust fees for specific students",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildIndividualStudentSelector() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Select Student", Icons.person_search),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _dropdown("Class", _selectedClass, _classes, (v) {
                  setState(() {
                    _selectedClass = v;
                    _selectedStudentId = null;
                  });
                  _loadStudentsInClass();
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dropdown("Section", _selectedSection, _sections, (v) {
                  setState(() {
                    _selectedSection = v;
                    _selectedStudentId = null;
                  });
                  _loadStudentsInClass();
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _dropdown(
            "Student",
            _selectedStudentId ?? "",
            _studentsInClass.map((s) => s['id'] as String).toList(),
            (v) {
              setState(() {
                _selectedStudentId = v;
                final selected = _studentsInClass.firstWhere(
                  (s) => s['id'] == v,
                );
                _selectedStudentName = selected['name'];
              });
            },
            isStudentDropdown: true,
            studentNames: _studentsInClass,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCurrentFeesCard() {
    if (_selectedStudentId == null) {
      return const SizedBox();
    }

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('student_fees')
              .where('studentId', isEqualTo: _selectedStudentId)
              .where('status', isEqualTo: 'pending')
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final pendingFees = snapshot.data!.docs;

        if (pendingFees.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: const Center(
              child: Text("No pending fees for this student"),
            ),
          );
        }

        double totalPending = 0;
        for (var doc in pendingFees) {
          final data = doc.data() as Map<String, dynamic>;
          totalPending += (data['remainingAmount'] ?? 0).toDouble();
        }

        return _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle("Current Fee Status", Icons.account_balance_wallet),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pending, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Total Pending Amount",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            "₹${totalPending.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ...pendingFees.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.receipt, size: 16),
                  title: Text(data['feeType'] ?? 'Fee'),
                  subtitle: Text(
                    "Due: ${(data['dueDate'] as Timestamp).toDate().toString().split(' ')[0]}",
                  ),
                  trailing: Text("₹${(data['remainingAmount'] ?? 0).toInt()}"),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIndividualFeeCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Fee Adjustment", Icons.edit_note),
          const SizedBox(height: 16),
          _dropdown("Adjustment Type", "Discount", _adjustmentTypes, (v) {}),
          const SizedBox(height: 12),
          TextField(
            controller: _individualAmountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Amount (₹)",
              hintText: "Enter amount to add/deduct",
              prefixIcon: Icon(Icons.currency_rupee),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _discountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Percentage (Optional)",
              hintText: "Apply percentage discount",
              prefixIcon: Icon(Icons.percent),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _remarksController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: "Remarks",
              hintText: "Reason for fee adjustment",
              prefixIcon: Icon(Icons.comment),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndividualSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        icon:
            _isLoading
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : const Icon(Icons.save),
        label: const Text("Apply Adjustment"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _isLoading ? null : _applyIndividualAdjustment,
      ),
    );
  }

  // ================= HISTORY TAB =================
  Widget _buildFeeHistory() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('fees')
              .orderBy('createdAt', descending: true)
              .limit(30)
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
                Icon(Icons.history, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text("No fee records found"),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.deepPurple.shade100,
                  child: Icon(Icons.receipt, color: Colors.deepPurple),
                ),
                title: Text(data['type'] ?? 'Fee'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${data['class']} - ${data['section']}"),
                    Text(
                      "Due: ${(data['dueDate'] as Timestamp).toDate().toString().split(' ')[0]}",
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      "Amount: ₹${(data['amount'] as num).toInt()} x ${data['totalStudents']} students",
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "₹${(data['totalAmount'] as num).toInt()}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        DateFormat(
                          'dd MMM yyyy',
                        ).format((data['createdAt'] as Timestamp).toDate()),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ================= COMMON WIDGETS =================
  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: child,
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

  Widget _sectionTitle(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.deepPurple),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 14 : 13,
              color: isBold ? Colors.black : Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 16 : 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String> onChanged, {
    bool isStudentDropdown = false,
    List<Map<String, dynamic>> studentNames = const [],
  }) {
    if (isStudentDropdown && studentNames.isNotEmpty) {
      return DropdownButtonFormField<String>(
        value: value.isEmpty ? null : value,
        hint: const Text("Select Student"),
        items:
            studentNames.map((student) {
              return DropdownMenuItem<String>(
                value: student['id'],
                child: Text("${student['rollNo']} - ${student['name']}"),
              );
            }).toList(),
        onChanged: (v) => onChanged(v!),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: value,
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (v) => onChanged(v!),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _datePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          initialDate: _dueDate ?? DateTime.now(),
        );
        if (picked != null) {
          setState(() => _dueDate = picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: "Due Date *",
          prefixIcon: const Icon(Icons.calendar_today),
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
          ),
        ),
        child: Text(
          _dueDate == null
              ? "Select due date"
              : DateFormat('dd MMM yyyy').format(_dueDate!),
          style: TextStyle(
            color: _dueDate == null ? Colors.grey : Colors.black,
          ),
        ),
      ),
    );
  }

  // ================= SUBMIT FUNCTIONS =================
  Future<void> _applyIndividualAdjustment() async {
    if (_selectedStudentId == null) {
      _showMessage("Please select a student", isError: true);
      return;
    }

    if (_individualAmountController.text.isEmpty &&
        _discountController.text.isEmpty) {
      _showMessage("Please enter amount or percentage", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get student's current pending fees
       var pendingFees =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('student_fees')
              .where('studentId', isEqualTo: _selectedStudentId)
              .where('status', isEqualTo: 'pending')
              .get();

      if (pendingFees.docs.isEmpty) {
        _showMessage("No pending fees for this student", isError: true);
        setState(() => _isLoading = false);
        return;
      }

      final batch = FirebaseFirestore.instance.batch();
      double amount = double.tryParse(_individualAmountController.text) ?? 0;
      double percentage = double.tryParse(_discountController.text) ?? 0;

      for (var doc in pendingFees.docs) {
        final data = doc.data();
        final originalAmount = (data['remainingAmount'] ?? 0).toDouble();
        double newAmount = originalAmount;

        if (percentage > 0) {
          newAmount = originalAmount * (1 - percentage / 100);
        } else if (amount > 0) {
          newAmount = originalAmount - amount;
        }

        batch.update(doc.reference, {
          'remainingAmount': newAmount,
          'discount': amount + (originalAmount * percentage / 100),
          'remarks': _remarksController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      _showMessage("Fee adjustment applied successfully", isError: false);

      // Clear form
      _individualAmountController.clear();
      _discountController.clear();
      _remarksController.clear();
    } catch (e) {
      _showMessage("Error: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _publishFee() async {
    if (_amountController.text.isEmpty) {
      _showMessage("Please enter fee amount", isError: true);
      return;
    }

    if (_dueDate == null) {
      _showMessage("Please select due date", isError: true);
      return;
    }

    if (_studentCount == 0) {
      _showMessage("No students found in this class/section", isError: true);
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showMessage("Enter valid amount", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final schoolRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId);

      // Create main fee document
      final feeDoc = await schoolRef.collection('fees').add({
        "class": _selectedClass,
        "section": _selectedSection,
        "type": _selectedFeeType,
        "description": _descriptionController.text.trim(),
        "amount": amount,
        "lateFee": _lateFee,
        "discount": _bulkDiscount,
        "dueDate": Timestamp.fromDate(_dueDate!),
        "isRecurring": _isRecurring,
        "recurringPeriod": _recurringPeriod,
        "createdAt": FieldValue.serverTimestamp(),
        "createdBy": FirebaseAuth.instance.currentUser?.email ?? "Admin",
        "totalStudents": _studentCount,
        "totalAmount": (amount - _bulkDiscount) * _studentCount,
      });

      // Get all students in the class/section
      final students =
          await schoolRef
              .collection('students')
              .where('class', isEqualTo: _selectedClass)
              .where('section', isEqualTo: _selectedSection)
              .get();

      // Create individual fee records for each student
      final batch = FirebaseFirestore.instance.batch();

      for (var student in students.docs) {
        final studentData = student.data();
        final finalAmount = amount - _bulkDiscount;

        final studentFeeRef = schoolRef.collection('student_fees').doc();

        batch.set(studentFeeRef, {
          "studentId": student.id,
          "studentName": studentData['name'] ?? 'Unknown',
          "rollNo": studentData['rollNo'] ?? '',
          "feeId": feeDoc.id,
          "feeType": _selectedFeeType,
          "originalAmount": amount,
          "amount": finalAmount,
          "discount": _bulkDiscount,
          "paidAmount": 0,
          "remainingAmount": finalAmount,
          "lateFee": _lateFee,
          "status": "pending",
          "dueDate": Timestamp.fromDate(_dueDate!),
          "createdAt": FieldValue.serverTimestamp(),
          "updatedAt": FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      _showMessage(
        "Fee published successfully for $_studentCount students",
        isError: false,
      );

      // Clear form
      _amountController.clear();
      _descriptionController.clear();
      setState(() {
        _dueDate = null;
        _lateFee = 0;
        _bulkDiscount = 0;
        _isRecurring = false;
      });
    } catch (e) {
      _showMessage("Error: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        icon:
            _isLoading
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : const Icon(Icons.upload),
        label: Text(_isLoading ? "Publishing..." : "Publish Fee"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _isLoading ? null : _publishFee,
      ),
    );
  }
}
