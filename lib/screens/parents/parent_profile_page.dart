import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ParentProfilePage extends StatefulWidget {
  final String studentId;
  final String schoolId;

  const ParentProfilePage({
    super.key,
    required this.studentId,
    required this.schoolId,
  });

  @override
  State<ParentProfilePage> createState() => _ParentProfilePageState();
}

class _ParentProfilePageState extends State<ParentProfilePage> {
  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _parentUid;

  // Controllers
  late TextEditingController _fatherNameController;
  late TextEditingController _motherNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _occupationController;
  late TextEditingController _emergencyContactNameController;
  late TextEditingController _emergencyPhoneController;
  late TextEditingController _emergencyRelationController;

  Map<String, dynamic> _studentData = {};
  Map<String, dynamic> _parentData = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadData();
  }

  @override
  void dispose() {
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _occupationController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    _fatherNameController = TextEditingController();
    _motherNameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
    _occupationController = TextEditingController();
    _emergencyContactNameController = TextEditingController();
    _emergencyPhoneController = TextEditingController();
    _emergencyRelationController = TextEditingController();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load student data
      final studentDoc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('students')
          .doc(widget.studentId)
          .get();

      if (studentDoc.exists) {
        _studentData = studentDoc.data() as Map<String, dynamic>;

        // Load parent data
        _parentUid = _studentData['parentUid'];
        if (_parentUid != null && _parentUid.toString().isNotEmpty) {
          final parentDoc = await FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('parents')
              .doc(_parentUid)
              .get();

          if (parentDoc.exists) {
            _parentData = parentDoc.data() as Map<String, dynamic>;
          }
        }

        // Populate controllers
        _fatherNameController.text = _studentData['fatherName'] ?? '';
        _motherNameController.text = _studentData['motherName'] ?? '';
        _phoneController.text = _parentData['phone'] ?? _studentData['phone'] ?? '';
        _emailController.text = _parentData['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '';
        _addressController.text = _studentData['address'] ?? '';
        _occupationController.text = _parentData['occupation'] ?? '';
        _emergencyContactNameController.text = _studentData['emergencyContactName'] ?? '';
        _emergencyPhoneController.text = _studentData['emergencyPhone'] ?? '';
        _emergencyRelationController.text = _studentData['emergencyRelation'] ?? '';
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading data: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_isEditing) return;

    setState(() => _isSaving = true);

    try {
      final batch = FirebaseFirestore.instance.batch();

      // Update student document
      final studentRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('students')
          .doc(widget.studentId);

      final studentUpdates = {
        'fatherName': _fatherNameController.text.trim(),
        'motherName': _motherNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'emergencyContactName': _emergencyContactNameController.text.trim(),
        'emergencyPhone': _emergencyPhoneController.text.trim(),
        'emergencyRelation': _emergencyRelationController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      batch.update(studentRef, studentUpdates);

      // Update parent document if exists
      if (_parentUid != null && _parentUid!.isNotEmpty) {
        final parentRef = FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolId)
            .collection('parents')
            .doc(_parentUid);

        final parentUpdates = {
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'occupation': _occupationController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        batch.update(parentRef, parentUpdates);
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile updated successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _isEditing = false);
        await _loadData(); // Reload fresh data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _cancelEdit() {
    setState(() => _isEditing = false);
    _loadData(); // Reload original data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          "Parent Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        centerTitle: false,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(_isEditing ? Icons.save : Icons.edit),
              onPressed: _isEditing ? _saveProfile : () => setState(() => _isEditing = true),
              tooltip: _isEditing ? "Save" : "Edit",
            ),
          if (_isEditing && !_isLoading)
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Icon(Icons.cancel),
              onPressed: _isSaving ? null : _cancelEdit,
              tooltip: "Cancel",
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStudentInfoCard(),
            const SizedBox(height: 16),
            _buildParentInfoCard(),
            const SizedBox(height: 16),
            _buildContactInfoCard(),
            const SizedBox(height: 16),
            _buildAddressCard(),
            const SizedBox(height: 16),
            _buildEmergencyContactCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.school, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  "Student Information",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              icon: Icons.person,
              label: "Student Name",
              value: _studentData['name'] ?? 'N/A',
            ),
            _buildInfoRow(
              icon: Icons.class_,
              label: "Class & Section",
              value: "${_studentData['class'] ?? 'N/A'} - ${_studentData['section'] ?? 'N/A'}",
            ),
            _buildInfoRow(
              icon: Icons.numbers,
              label: "Roll Number",
              value: _studentData['rollNo']?.toString() ?? 'N/A',
            ),
            _buildInfoRow(
              icon: Icons.badge,
              label: "Admission No",
              value: _studentData['admissionNo']?.toString() ?? 'N/A',
            ),
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: "Date of Birth",
              value: _formatDate(_studentData['dob']),
            ),
            _buildInfoRow(
              icon: Icons.bloodtype,
              label: "Blood Group",
              value: _studentData['bloodGroup'] ?? 'N/A',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParentInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.family_restroom, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  "Parent Information",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildEditableRow(
              icon: Icons.man,
              label: "Father's Name",
              value: _fatherNameController.text,
              onChanged: (val) => _fatherNameController.text = val,
            ),
            _buildEditableRow(
              icon: Icons.woman,
              label: "Mother's Name",
              value: _motherNameController.text,
              onChanged: (val) => _motherNameController.text = val,
            ),
            _buildEditableRow(
              icon: Icons.work,
              label: "Occupation",
              value: _occupationController.text,
              onChanged: (val) => _occupationController.text = val,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.contact_phone, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  "Contact Information",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildEditableRow(
              icon: Icons.phone,
              label: "Phone Number",
              value: _phoneController.text,
              onChanged: (val) => _phoneController.text = val,
              keyboardType: TextInputType.phone,
            ),
            _buildInfoRow(
              icon: Icons.email,
              label: "Email Address",
              value: _emailController.text.isEmpty ? 'Not provided' : _emailController.text,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.location_on, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  "Address",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildEditableRow(
              icon: Icons.home,
              label: "Residential Address",
              value: _addressController.text,
              onChanged: (val) => _addressController.text = val,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.emergency, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  "Emergency Contact",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildEditableRow(
              icon: Icons.person,
              label: "Contact Person",
              value: _emergencyContactNameController.text,
              onChanged: (val) => _emergencyContactNameController.text = val,
            ),
            _buildEditableRow(
              icon: Icons.phone,
              label: "Emergency Number",
              value: _emergencyPhoneController.text,
              onChanged: (val) => _emergencyPhoneController.text = val,
              keyboardType: TextInputType.phone,
            ),
            _buildEditableRow(
              icon: Icons.people,
              label: "Relationship",
              value: _emergencyRelationController.text,
              onChanged: (val) => _emergencyRelationController.text = val,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableRow({
    required IconData icon,
    required String label,
    required String value,
    required Function(String) onChanged,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          Expanded(
            child: _isEditing
                ? TextFormField(
              initialValue: value,
              onChanged: onChanged,
              keyboardType: keyboardType,
              maxLines: maxLines,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              style: const TextStyle(fontSize: 13),
            )
                : Text(
              value.isEmpty ? 'Not provided' : value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    if (date is Timestamp) {
      return DateFormat('dd MMM yyyy').format(date.toDate());
    }
    if (date is String) {
      // Try to parse string date
      try {
        final parsedDate = DateTime.parse(date);
        return DateFormat('dd MMM yyyy').format(parsedDate);
      } catch (e) {
        return date;
      }
    }
    return date.toString();
  }
}