// lib/screens/teacher/teacher_leave_application.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:schoolprojectjan/screens/teacher/teacher_leave_history.dart';
import '../../services/leave_service.dart';
import '../../models/leave_request_model.dart';

class TeacherLeaveApplication extends StatefulWidget {
  const TeacherLeaveApplication({Key? key}) : super(key: key);

  @override
  _TeacherLeaveApplicationState createState() => _TeacherLeaveApplicationState();
}

class _TeacherLeaveApplicationState extends State<TeacherLeaveApplication> {
  final LeaveService _leaveService = LeaveService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  String _selectedLeaveType = 'Casual Leave';
  DateTime? _fromDate;
  DateTime? _toDate;
  final TextEditingController _reasonController = TextEditingController();
  String? _documentUrl;
  String? _documentName;
  bool _isLoading = false;
  bool _isUploading = false;

  // Leave balance
  Map<String, dynamic> _leaveBalance = {};
  bool _isLoadingBalance = true;

  @override
  void initState() {
    super.initState();
    _loadLeaveBalance();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaveBalance() async {
    setState(() {
      _isLoadingBalance = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final balance = await _leaveService.getLeaveBalance(user.uid);
        setState(() {
          _leaveBalance = balance['leaveTypes'] ?? {};
          _isLoadingBalance = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingBalance = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load leave balance: $e')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(Duration(days: 30)),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
          // Auto set to date if from date is after to date
          if (_toDate != null && _toDate!.isBefore(_fromDate!)) {
            _toDate = _fromDate;
          }
        } else {
          _toDate = picked;
          // Auto set from date if to date is before from date
          if (_fromDate != null && _toDate!.isBefore(_fromDate!)) {
            _fromDate = _toDate;
          }
        }
      });
    }
  }

  int _calculateDays() {
    if (_fromDate != null && _toDate != null) {
      final difference = _toDate!.difference(_fromDate!).inDays + 1;
      return difference > 0 ? difference : 0;
    }
    return 0;
  }

  Future<void> _pickDocument() async {
    try {
      setState(() {
        _isUploading = true;
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final fileName = file.name;
        final fileBytes = file.bytes;

        if (fileBytes != null) {
          // Upload to Firebase Storage
          final user = _auth.currentUser;
          final storageRef = _storage.ref()
              .child('leave_documents')
              .child(user!.uid)
              .child('${DateTime.now().millisecondsSinceEpoch}_$fileName');

          await storageRef.putData(fileBytes);
          final downloadUrl = await storageRef.getDownloadURL();

          setState(() {
            _documentUrl = downloadUrl;
            _documentName = fileName;
            _isUploading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📎 Document uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload document: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitLeaveRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_fromDate == null || _toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select dates for leave'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final days = _calculateDays();
    if (days <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select valid dates'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if leave balance is sufficient
    final canApply = await _leaveService.canApplyLeave(
      _auth.currentUser!.uid,
      _selectedLeaveType,
      days,
    );

    if (!canApply) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Insufficient leave balance for $_selectedLeaveType'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser!;

      // Get teacher details
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final teacherData = userDoc.data() ?? {};

      // Create leave request
      final leaveRequest = LeaveRequest(
        teacherId: user.uid,
        teacherName: teacherData['name'] ?? 'Teacher',
        teacherEmail: teacherData['email'] ?? '',
        teacherClass: teacherData['class'] ?? 'Not Assigned',
        teacherSubject: teacherData['subject'] ?? 'Not Assigned',
        leaveType: _selectedLeaveType,
        fromDate: _fromDate!,
        toDate: _toDate!,
        days: days,
        reason: _reasonController.text,
        documentUrl: _documentUrl,
        status: 'pending',
        appliedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _leaveService.submitLeaveRequest(leaveRequest);

      setState(() {
        _isLoading = false;
      });

      // Show success dialog with call animation
      _showSuccessDialog();

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit leave request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated checkmark
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.1),
                ),
                padding: EdgeInsets.all(16),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 80,
                ),
              ),
              SizedBox(height: 16),
              Text(
                '✅ Leave Request Submitted!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Admin has been notified.\nYou will receive approval via notification.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone_in_talk, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      '📞 Admin will call you soon!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Go back to dashboard
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'OK',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Apply for Leave',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TeacherLeaveHistory(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoadingBalance
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leave Balance Card
            _buildLeaveBalanceCard(),
            SizedBox(height: 20),

            // Application Form
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📝 Leave Application Form',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),

                      // Leave Type Dropdown
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Leave Type *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: Icon(Icons.event_note),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        value: _selectedLeaveType,
                        items: ['Casual Leave', 'Sick Leave', 'Earned Leave']
                            .map((type) => DropdownMenuItem(
                          value: type,
                          child: Row(
                            children: [
                              Icon(
                                type == 'Casual Leave'
                                    ? Icons.celebration
                                    : type == 'Sick Leave'
                                    ? Icons.local_hospital
                                    : Icons.work,
                                color: Colors.blue,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(type),
                              Spacer(),
                              if (_leaveBalance.containsKey(type))
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${_leaveBalance[type]['remaining'] ?? 0} left',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedLeaveType = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select leave type';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      // Date Range
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, true),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'From Date *',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: Icon(Icons.calendar_today),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                child: Text(
                                  _fromDate != null
                                      ? DateFormat('dd MMM yyyy').format(_fromDate!)
                                      : 'Select date',
                                  style: TextStyle(
                                    color: _fromDate != null
                                        ? Colors.black
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, false),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'To Date *',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: Icon(Icons.calendar_today),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                child: Text(
                                  _toDate != null
                                      ? DateFormat('dd MMM yyyy').format(_toDate!)
                                      : 'Select date',
                                  style: TextStyle(
                                    color: _toDate != null
                                        ? Colors.black
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),

                      // Days count
                      if (_fromDate != null && _toDate != null)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Days:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${_calculateDays()} day${_calculateDays() > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: 16),

                      // Reason
                      TextFormField(
                        controller: _reasonController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Reason for Leave *',
                          hintText: 'Please provide reason for leave...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: Icon(Icons.description),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please provide reason';
                          }
                          if (value.length < 10) {
                            return 'Reason must be at least 10 characters';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      // Document Upload
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[50],
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Icon(
                                Icons.attach_file,
                                color: Colors.blue,
                              ),
                              title: Text(
                                _documentName ?? 'Attach Document (Optional)',
                                style: TextStyle(
                                  color: _documentName != null
                                      ? Colors.black
                                      : Colors.grey[600],
                                ),
                              ),
                              trailing: _isUploading
                                  ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                                  : _documentName != null
                                  ? Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              )
                                  : Icon(
                                Icons.cloud_upload,
                                color: Colors.blue,
                              ),
                              onTap: _pickDocument,
                            ),
                            if (_documentName != null)
                              Padding(
                                padding: EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                  bottom: 8,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '✅ ${_documentName.length > 30 ? _documentName.substring(0, 30) + '...' : _documentName}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _documentUrl = null;
                                          _documentName = null;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _submitLeaveRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: _isLoading
                              ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : Icon(Icons.phone_callback),
                          label: Text(
                            _isLoading
                                ? 'Submitting...'
                                : '📞 Submit & Notify Admin',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '⚠️ Admin will review your request and approve via call-style notification',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveBalanceCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[700]!, Colors.blue[900]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '📊 Your Leave Balance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '2026-2027',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBalanceItem('Casual Leave', 'CL', _leaveBalance),
              _buildBalanceItem('Sick Leave', 'SL', _leaveBalance),
              _buildBalanceItem('Earned Leave', 'EL', _leaveBalance),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(String type, String short, Map<String, dynamic> balance) {
    final data = balance[type] ?? {'total': 0, 'used': 0, 'remaining': 0};
    final remaining = data['remaining'] ?? 0;
    final total = data['total'] ?? 0;
    final percentage = total > 0 ? (remaining / total * 100) : 0;

    return Column(
      children: [
        Text(
          short,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        SizedBox(height: 4),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 50,
              width: 50,
              child: CircularProgressIndicator(
                value: total > 0 ? remaining / total : 0,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  remaining > 0 ? Colors.green[400]! : Colors.red[400]!,
                ),
                strokeWidth: 4,
              ),
            ),
            Text(
              '$remaining',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          '/$total',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}