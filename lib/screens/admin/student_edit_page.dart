import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StudentEditPage extends StatefulWidget {
  final String schoolId;
  final String studentId;

  const StudentEditPage({
    super.key,
    required this.schoolId,
    required this.studentId,
  });

  @override
  State<StudentEditPage> createState() => _StudentEditPageState();
}

class _StudentEditPageState extends State<StudentEditPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _sectionController = TextEditingController();
  final TextEditingController _rollController = TextEditingController();
  final TextEditingController _admissionNoController = TextEditingController();
  final TextEditingController _parentNameController = TextEditingController();
  final TextEditingController _parentPhoneController = TextEditingController();
  final TextEditingController _parentEmailController = TextEditingController();
  final TextEditingController _bloodGroupController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  DateTime? _dob;
  String? _selectedGender;
  String? _selectedClass;
  String? _selectedSection;
  String? _selectedBloodGroup;
  bool _isLoading = true;
  bool _isUpdating = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-',
  ];
  List<String> _availableClasses = [];
  final List<String> _availableSections = ['A', 'B', 'C', 'D'];

  @override
  void initState() {
    super.initState();
    _loadStudent();
    _loadAvailableClasses();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _classController.dispose();
    _sectionController.dispose();
    _rollController.dispose();
    _admissionNoController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _parentEmailController.dispose();
    _bloodGroupController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableClasses() async {
    try {
      final classesSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('classes')
              .get();

      if (classesSnapshot.docs.isNotEmpty) {
        setState(() {
          _availableClasses =
              classesSnapshot.docs
                  .map(
                    (doc) =>
                        doc['name'] as String? ?? doc['class'] as String? ?? '',
                  )
                  .where((name) => name.isNotEmpty)
                  .toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading classes: $e');
    }
  }

  // Helper method to normalize blood group (B+ve -> B+)
  String _normalizeBloodGroup(String? bloodGroup) {
    if (bloodGroup == null) return '';
    // Convert B+ve to B+, A+ve to A+, etc.
    String normalized = bloodGroup
        .replaceAll('+ve', '+')
        .replaceAll('-ve', '-');
    return normalized;
  }

  Future<void> _loadStudent() async {
    setState(() => _isLoading = true);

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('students')
              .doc(widget.studentId)
              .get();

      if (!doc.exists) {
        _showError("Student not found");
        if (mounted) Navigator.pop(context);
        return;
      }

      final data = doc.data()!;

      _nameController.text = data['name'] ?? '';
      _selectedClass = data['class'];
      _selectedSection = data['section'];
      _rollController.text = data['rollNo'] ?? '';
      _admissionNoController.text = data['admissionNo'] ?? '';
      _parentNameController.text = data['parentName'] ?? '';
      _parentPhoneController.text = data['parentPhone'] ?? '';
      _parentEmailController.text = data['parentEmail'] ?? '';

      // Normalize blood group from Firestore
      final rawBloodGroup = data['bloodGroup'] as String?;
      _selectedBloodGroup = _normalizeBloodGroup(rawBloodGroup);

      _addressController.text = data['address'] ?? '';
      _selectedGender = data['gender'];

      if (data['dob'] != null) {
        _dob = (data['dob'] as Timestamp).toDate();
      }
    } catch (e) {
      _showError("Error loading student: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUpdating = true);

    try {
      final updateData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'class': _selectedClass,
        'section': _selectedSection,
        'rollNo': _rollController.text.trim(),
        'admissionNo': _admissionNoController.text.trim(),
        'parentName': _parentNameController.text.trim(),
        'parentPhone': _parentPhoneController.text.trim(),
        'parentEmail': _parentEmailController.text.trim(),
        'bloodGroup': _selectedBloodGroup,
        'address': _addressController.text.trim(),
        'gender': _selectedGender,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_dob != null) {
        updateData['dob'] = Timestamp.fromDate(_dob!);
      }

      await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('students')
          .doc(widget.studentId)
          .update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Student updated successfully"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError("Error updating student: $e");
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _selectDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _dob ?? DateTime.now().subtract(const Duration(days: 365 * 10)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _dob = picked);
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text("Delete Student"),
            content: const Text(
              "Are you sure you want to delete this student? This action cannot be undone.",
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
      setState(() => _isUpdating = true);

      try {
        await FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolId)
            .collection('students')
            .doc(widget.studentId)
            .delete();

        if (_selectedClass != null && _selectedClass!.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('classes')
              .doc(_selectedClass)
              .collection('students')
              .doc(widget.studentId)
              .delete();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Student deleted successfully"),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        _showError("Error deleting student: $e");
        setState(() => _isUpdating = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          "Edit Student",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.cyan,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmDelete,
            tooltip: "Delete Student",
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStudentInfoCard(),
                      const SizedBox(height: 16),
                      _buildParentInfoCard(),
                      const SizedBox(height: 16),
                      _buildAdditionalInfoCard(),
                      const SizedBox(height: 24),
                      _buildUpdateButton(),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildStudentInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.cyan.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person, color: Colors.cyan),
              ),
              const SizedBox(width: 12),
              const Text(
                "Student Information",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _nameController,
            "Student Name *",
            Icons.person_outline,
          ),
          const SizedBox(height: 12),
          _buildClassDropdown(),
          const SizedBox(height: 12),
          _buildSectionDropdown(),
          const SizedBox(height: 12),
          _buildTextField(_rollController, "Roll Number *", Icons.numbers),
          const SizedBox(height: 12),
          _buildTextField(
            _admissionNoController,
            "Admission Number",
            Icons.badge,
          ),
          const SizedBox(height: 12),
          _buildGenderDropdown(),
          const SizedBox(height: 12),
          _buildDatePickerField(),
        ],
      ),
    );
  }

  Widget _buildParentInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.cyan.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.family_restroom, color: Colors.cyan),
              ),
              const SizedBox(width: 12),
              const Text(
                "Parent Information",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(_parentNameController, "Parent Name", Icons.person),
          const SizedBox(height: 12),
          _buildTextField(
            _parentPhoneController,
            "Parent Phone",
            Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            _parentEmailController,
            "Parent Email",
            Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.cyan.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info, color: Colors.cyan),
              ),
              const SizedBox(width: 12),
              const Text(
                "Additional Information",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBloodGroupDropdown(),
          const SizedBox(height: 12),
          _buildTextField(
            _addressController,
            "Address",
            Icons.location_on,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14),
      validator: (value) {
        if (label.contains('*') && (value == null || value.isEmpty)) {
          return "This field is required";
        }
        if (label.contains('Email') && value != null && value.isNotEmpty) {
          if (!value.contains('@') || !value.contains('.')) {
            return "Enter a valid email";
          }
        }
        if (label.contains('Phone') && value != null && value.isNotEmpty) {
          if (value.length < 10) {
            return "Enter a valid phone number (min 10 digits)";
          }
        }
        if (label.contains('Roll Number') &&
            value != null &&
            value.isNotEmpty) {
          if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
            return "Roll number should contain only numbers";
          }
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.cyan, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.cyan, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildClassDropdown() {
    if (_availableClasses.isEmpty) {
      return _buildTextField(_classController, "Class *", Icons.class_);
    }

    return DropdownButtonFormField<String>(
      value: _selectedClass,
      hint: const Text("Select Class *"),
      isExpanded: true,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.class_, color: Colors.cyan, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.cyan, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      items:
          _availableClasses.map((className) {
            return DropdownMenuItem(value: className, child: Text(className));
          }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedClass = value;
        });
      },
      validator:
          (value) => _selectedClass == null ? "Please select a class" : null,
    );
  }

  Widget _buildSectionDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSection,
      hint: const Text("Select Section *"),
      isExpanded: true,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.group, color: Colors.cyan, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.cyan, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      items:
          _availableSections.map((section) {
            return DropdownMenuItem(value: section, child: Text(section));
          }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedSection = value;
        });
      },
      validator:
          (value) =>
              _selectedSection == null ? "Please select a section" : null,
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      hint: const Text("Select Gender"),
      isExpanded: true,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.people, color: Colors.cyan, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.cyan, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      items:
          _genders.map((gender) {
            return DropdownMenuItem(value: gender, child: Text(gender));
          }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedGender = value;
        });
      },
    );
  }

  // FIXED: Blood Group Dropdown with safe value handling
  Widget _buildBloodGroupDropdown() {
    // Check if current value exists in the list
    final bool isValidValue =
        _selectedBloodGroup != null &&
        _bloodGroups.contains(_selectedBloodGroup);

    return DropdownButtonFormField<String>(
      value: isValidValue ? _selectedBloodGroup : null,
      hint: const Text("Select Blood Group"),
      isExpanded: true,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.bloodtype, color: Colors.cyan, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.cyan, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      items:
          _bloodGroups.map((bg) {
            return DropdownMenuItem(value: bg, child: Text(bg));
          }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedBloodGroup = value;
        });
      },
    );
  }

  Widget _buildDatePickerField() {
    return GestureDetector(
      onTap: _selectDateOfBirth,
      child: AbsorbPointer(
        child: TextFormField(
          controller: TextEditingController(
            text: _dob != null ? DateFormat('dd/MM/yyyy').format(_dob!) : '',
          ),
          decoration: InputDecoration(
            labelText: "Date of Birth",
            prefixIcon: const Icon(Icons.cake, color: Colors.cyan, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.cyan, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isUpdating ? null : _updateStudent,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyan,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child:
            _isUpdating
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : const Text(
                  "Update Student",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
      ),
    );
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
