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

  final nameController = TextEditingController();
  final classController = TextEditingController();
  final sectionController = TextEditingController();
  final rollController = TextEditingController();
  final admissionNoController = TextEditingController();
  final parentNameController = TextEditingController();
  final parentPhoneController = TextEditingController();
  final parentEmailController = TextEditingController();
  final bloodGroupController = TextEditingController();
  final addressController = TextEditingController();

  DateTime? dob;
  String? _selectedGender;
  bool loading = true;
  bool isUpdating = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
  List<String> _availableClasses = [];
  List<String> _availableSections = ['A', 'B', 'C', 'D'];

  @override
  void initState() {
    super.initState();
    _loadStudent();
    _loadAvailableClasses();
  }

  @override
  void dispose() {
    nameController.dispose();
    classController.dispose();
    sectionController.dispose();
    rollController.dispose();
    admissionNoController.dispose();
    parentNameController.dispose();
    parentPhoneController.dispose();
    parentEmailController.dispose();
    bloodGroupController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableClasses() async {
    try {
      final classesSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('classes')
          .get();

      setState(() {
        _availableClasses = classesSnapshot.docs
            .map((doc) => doc['class'] as String)
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading classes: $e');
    }
  }

  Future<void> _loadStudent() async {
    setState(() => loading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('students')
          .doc(widget.studentId)
          .get();

      if (!doc.exists) {
        _showError("Student not found");
        Navigator.pop(context);
        return;
      }

      final data = doc.data()!;

      nameController.text = data['name'] ?? '';
      classController.text = data['class'] ?? '';
      sectionController.text = data['section'] ?? '';
      rollController.text = data['rollNo'] ?? '';
      admissionNoController.text = data['admissionNo'] ?? '';
      parentNameController.text = data['parentName'] ?? '';
      parentPhoneController.text = data['parentPhone'] ?? '';
      parentEmailController.text = data['parentEmail'] ?? '';
      bloodGroupController.text = data['bloodGroup'] ?? '';
      addressController.text = data['address'] ?? '';

      _selectedGender = data['gender'];

      if (data['dob'] != null) {
        dob = (data['dob'] as Timestamp).toDate();
      }
    } catch (e) {
      _showError("Error loading student: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _updateStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isUpdating = true);

    try {
      final updateData = {
        'name': nameController.text.trim(),
        'class': classController.text.trim(),
        'section': sectionController.text.trim(),
        'rollNo': rollController.text.trim(),
        'admissionNo': admissionNoController.text.trim(),
        'parentName': parentNameController.text.trim(),
        'parentPhone': parentPhoneController.text.trim(),
        'parentEmail': parentEmailController.text.trim(),
        'bloodGroup': bloodGroupController.text.trim(),
        'address': addressController.text.trim(),
        'gender': _selectedGender,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (dob != null) {
        updateData['dob'] = Timestamp.fromDate(dob!);
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
      setState(() => isUpdating = false);
    }
  }

  Future<void> _selectDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dob ?? DateTime.now().subtract(const Duration(days: 365 * 10)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => dob = picked);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
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
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student Information Card
              _buildStudentInfoCard(),
              const SizedBox(height: 16),

              // Parent Information Card
              _buildParentInfoCard(),
              const SizedBox(height: 16),

              // Additional Information Card
              _buildAdditionalInfoCard(),
              const SizedBox(height: 24),

              // Update Button
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

          // Student Name
          _buildTextField(nameController, "Student Name *", Icons.person_outline),
          const SizedBox(height: 12),

          // Class Dropdown
          _buildClassDropdown(),
          const SizedBox(height: 12),

          // Section Dropdown
          _buildSectionDropdown(),
          const SizedBox(height: 12),

          // Roll Number
          _buildTextField(rollController, "Roll Number *", Icons.numbers),
          const SizedBox(height: 12),

          // Admission Number
          _buildTextField(admissionNoController, "Admission Number", Icons.badge),
          const SizedBox(height: 12),

          // Gender
          _buildGenderDropdown(),
          const SizedBox(height: 12),

          // Date of Birth
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

          // Parent Name
          _buildTextField(parentNameController, "Parent Name", Icons.person),
          const SizedBox(height: 12),

          // Parent Phone
          _buildTextField(parentPhoneController, "Parent Phone", Icons.phone,
              keyboardType: TextInputType.phone),
          const SizedBox(height: 12),

          // Parent Email
          _buildTextField(parentEmailController, "Parent Email", Icons.email,
              keyboardType: TextInputType.emailAddress),
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

          // Blood Group Dropdown
          _buildBloodGroupDropdown(),
          const SizedBox(height: 12),

          // Address
          _buildTextField(addressController, "Address", Icons.location_on,
              maxLines: 2),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (v) {
        if (label.contains('*') && (v == null || v.isEmpty)) {
          return "This field is required";
        }
        if (label.contains('Email') && v != null && v.isNotEmpty) {
          if (!v.contains('@') || !v.contains('.')) {
            return "Enter a valid email";
          }
        }
        if (label.contains('Phone') && v != null && v.isNotEmpty) {
          if (v.length < 10) {
            return "Enter a valid phone number";
          }
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.cyan),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildClassDropdown() {
    if (_availableClasses.isEmpty) {
      return _buildTextField(classController, "Class *", Icons.class_);
    }

    return DropdownButtonFormField<String>(
      value: classController.text.isEmpty ? null : classController.text,
      hint: const Text("Select Class *"),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.class_, color: Colors.cyan),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: _availableClasses.map((className) {
        return DropdownMenuItem(
          value: className,
          child: Text(className),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          classController.text = value ?? '';
        });
      },
      validator: (v) => classController.text.isEmpty ? "Please select a class" : null,
    );
  }

  Widget _buildSectionDropdown() {
    return DropdownButtonFormField<String>(
      value: sectionController.text.isEmpty ? null : sectionController.text,
      hint: const Text("Select Section *"),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.group, color: Colors.cyan),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: _availableSections.map((section) {
        return DropdownMenuItem(
          value: section,
          child: Text(section),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          sectionController.text = value ?? '';
        });
      },
      validator: (v) => sectionController.text.isEmpty ? "Please select a section" : null,
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      hint: const Text("Select Gender"),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.people, color: Colors.cyan),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: _genders.map((gender) {
        return DropdownMenuItem(
          value: gender,
          child: Text(gender),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedGender = value;
        });
      },
    );
  }

  Widget _buildBloodGroupDropdown() {
    return DropdownButtonFormField<String>(
      value: bloodGroupController.text.isEmpty ? null : bloodGroupController.text,
      hint: const Text("Select Blood Group"),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.bloodtype, color: Colors.cyan),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: _bloodGroups.map((bg) {
        return DropdownMenuItem(
          value: bg,
          child: Text(bg),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          bloodGroupController.text = value ?? '';
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
            text: dob != null ? DateFormat('dd/MM/yyyy').format(dob!) : '',
          ),
          decoration: InputDecoration(
            labelText: "Date of Birth",
            prefixIcon: const Icon(Icons.cake, color: Colors.cyan),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
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
        onPressed: isUpdating ? null : _updateStudent,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyan,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isUpdating
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

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
      setState(() => isUpdating = true);

      try {
        await FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolId)
            .collection('students')
            .doc(widget.studentId)
            .delete();

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
        setState(() => isUpdating = false);
      }
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