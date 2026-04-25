import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminFeeUploadPage extends StatefulWidget {
  final String schoolId;

  const AdminFeeUploadPage({super.key, required this.schoolId});

  @override
  State<AdminFeeUploadPage> createState() => _AdminFeeUploadPageState();
}

class _AdminFeeUploadPageState extends State<AdminFeeUploadPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedClass = "Class 6";
  String _selectedSection = "A";
  String _selectedFeeType = "Tuition Fee";
  DateTime? _dueDate;
  bool _isRecurring = false;
  String _recurringPeriod = "Monthly";
  double _lateFee = 0;
  double _discount = 0;

  int _studentCount = 0;
  double _totalAmount = 0;
  bool _isLoading = false;

  final List<String> _classes = [
    "LKG", "UKG", "Class 1", "Class 2", "Class 3", "Class 4",
    "Class 5", "Class 6", "Class 7", "Class 8", "Class 9", "Class 10"
  ];

  final List<String> _sections = ["A", "B", "C", "D"];

  final List<String> _feeTypes = [
    "Tuition Fee", "Exam Fee", "Transport Fee", "Library Fee",
    "Sports Fee", "Development Fee", "Activity Fee", "Other"
  ];

  final List<String> _recurringPeriods = ["Monthly", "Quarterly", "Half-Yearly", "Yearly"];

  @override
  void initState() {
    super.initState();
    _loadStudentCount();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentCount() async {
    try {
      final studentsSnapshot = await FirebaseFirestore.instance
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

  void _updateTotal() {
    if (_amountController.text.isNotEmpty) {
      double amount = double.tryParse(_amountController.text) ?? 0;
      setState(() {
        _totalAmount = amount * _studentCount;
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
        title: const Text("Upload Fees"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _viewFeeHistory,
            tooltip: "Fee History",
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadStudentCount();
              _updateTotal();
            },
            tooltip: "Refresh",
          ),
        ],
      ),
      body: SingleChildScrollView(
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
            _buildFeeDetailsCard(),
            const SizedBox(height: 16),
            _buildAdditionalOptionsCard(),
            const SizedBox(height: 16),
            _buildSummaryCard(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

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
            color: Colors.deepPurple.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Fee Management",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Create and publish fees for students",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
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
                child: _dropdown(
                  "Class",
                  _selectedClass,
                  _classes,
                      (v) {
                    setState(() {
                      _selectedClass = v;
                    });
                    _loadStudentCount();
                    _updateTotal();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dropdown(
                  "Section",
                  _selectedSection,
                  _sections,
                      (v) {
                    setState(() {
                      _selectedSection = v;
                    });
                    _loadStudentCount();
                    _updateTotal();
                  },
                ),
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

  Widget _buildFeeDetailsCard() {
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
                borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
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
                borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _datePicker(),
        ],
      ),
    );
  }

  Widget _buildAdditionalOptionsCard() {
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
              labelText: "Late Fee (₹) - Optional",
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
                _discount = double.tryParse(value) ?? 0;
              });
            },
            decoration: InputDecoration(
              labelText: "Discount (₹) - Optional",
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

  Widget _buildSummaryCard() {
    double amountPerStudent = double.tryParse(_amountController.text) ?? 0;
    double totalAfterDiscount = _totalAmount - (_discount * _studentCount);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Summary", Icons.summarize),
          const SizedBox(height: 16),
          _summaryRow("Fee Type", _selectedFeeType),
          _summaryRow("Class/Section", "$_selectedClass - $_selectedSection"),
          _summaryRow("Students", _studentCount.toString()),
          _summaryRow("Amount per Student", "₹${amountPerStudent.toStringAsFixed(0)}"),
          if (_discount > 0)
            _summaryRow("Discount per Student", "-₹${_discount.toStringAsFixed(0)}"),
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
              "₹${_lateFee.toStringAsFixed(0)} after due date",
            ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        icon: _isLoading
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
          elevation: 2,
        ),
        onPressed: _isLoading ? null : _publishFee,
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.deepPurple),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false, Color? color}) {
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
      ValueChanged<String> onChanged,
      ) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (v) => onChanged(v!),
      decoration: InputDecoration(
        labelText: label,
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
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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

  Future<void> _publishFee() async {
    // Validation
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
      final feeDoc = await schoolRef
          .collection('fees')
          .add({
        "class": _selectedClass,
        "section": _selectedSection,
        "type": _selectedFeeType,
        "description": _descriptionController.text.trim(),
        "amount": amount,
        "lateFee": _lateFee,
        "discount": _discount,
        "dueDate": Timestamp.fromDate(_dueDate!),
        "isRecurring": _isRecurring,
        "recurringPeriod": _recurringPeriod,
        "createdAt": FieldValue.serverTimestamp(),
        "createdBy": "Admin",
        "totalStudents": _studentCount,
        "totalAmount": amount * _studentCount,
      });

      // Get all students in the class/section
      final students = await schoolRef
          .collection('students')
          .where('class', isEqualTo: _selectedClass)
          .where('section', isEqualTo: _selectedSection)
          .get();

      // Create individual fee records for each student
      final batch = FirebaseFirestore.instance.batch();

      for (var student in students.docs) {
        final studentData = student.data();
        final studentFeeRef = schoolRef
            .collection('student_fees')
            .doc();

        batch.set(studentFeeRef, {
          "studentId": student.id,
          "studentName": studentData['name'] ?? 'Unknown',
          "rollNo": studentData['rollNo'] ?? '',
          "feeId": feeDoc.id,
          "feeType": _selectedFeeType,
          "amount": amount,
          "paidAmount": 0,
          "remainingAmount": amount,
          "discount": _discount,
          "lateFee": _lateFee,
          "status": "pending",
          "dueDate": Timestamp.fromDate(_dueDate!),
          "createdAt": FieldValue.serverTimestamp(),
          "updatedAt": FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      _showMessage("Fee published successfully for $_studentCount students", isError: false);

      // Clear form
      _amountController.clear();
      _descriptionController.clear();
      setState(() {
        _dueDate = null;
        _lateFee = 0;
        _discount = 0;
        _isRecurring = false;
      });

    } catch (e) {
      _showMessage("Error: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _viewFeeHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
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
                const Text(
                  "Recent Fee Publications",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('schools')
                        .doc(widget.schoolId)
                        .collection('fees')
                        .orderBy('createdAt', descending: true)
                        .limit(20)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text("No fee records found"),
                        );
                      }

                      return ListView.builder(
                        controller: scrollController,
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final doc = snapshot.data!.docs[index];
                          final data = doc.data() as Map<String, dynamic>;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.deepPurple.shade100,
                                child: Icon(Icons.receipt, color: Colors.deepPurple),
                              ),
                              title: Text(data['type'] ?? 'Fee'),
                              subtitle: Text(
                                "${data['class']} - ${data['section']}\nDue: ${(data['dueDate'] as Timestamp).toDate().toString().split(' ')[0]}",
                              ),
                              trailing: Text(
                                "₹${(data['amount'] as num).toInt()}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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
}