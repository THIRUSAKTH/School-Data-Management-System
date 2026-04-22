import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../app_config.dart';

class TeacherAddStudentPage extends StatefulWidget {
  final String className;
  final String section;

  const TeacherAddStudentPage({
    super.key,
    required this.className,
    required this.section,
  });

  @override
  State<TeacherAddStudentPage> createState() => _TeacherAddStudentPageState();
}

class _TeacherAddStudentPageState extends State<TeacherAddStudentPage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final rollController = TextEditingController();
  final parentNameController = TextEditingController();
  final parentEmailController = TextEditingController();
  final parentPhoneController = TextEditingController();
  final admissionNoController = TextEditingController();
  final dobController = TextEditingController();
  final bloodGroupController = TextEditingController();
  final addressController = TextEditingController();

  bool loading = false;
  String? _selectedGender;
  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  final String defaultParentPassword = "Parent@123";

  @override
  void dispose() {
    nameController.dispose();
    rollController.dispose();
    parentNameController.dispose();
    parentEmailController.dispose();
    parentPhoneController.dispose();
    admissionNoController.dispose();
    dobController.dispose();
    bloodGroupController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text(
          "Add Student - ${widget.className} ${widget.section}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student Information Section
              _buildSectionHeader("Student Information", Icons.person),
              const SizedBox(height: 12),
              _buildTextField(nameController, "Student Name *", Icons.person_outline),
              const SizedBox(height: 12),
              _buildTextField(rollController, "Roll Number *", Icons.numbers),
              const SizedBox(height: 12),
              _buildTextField(admissionNoController, "Admission Number", Icons.badge),
              const SizedBox(height: 12),
              _buildGenderDropdown(),
              const SizedBox(height: 12),
              _buildDatePickerField(),
              const SizedBox(height: 12),
              _buildBloodGroupDropdown(),
              const SizedBox(height: 12),
              _buildTextField(addressController, "Address", Icons.location_on, maxLines: 2),

              const SizedBox(height: 24),

              // Parent Information Section
              _buildSectionHeader("Parent Information", Icons.family_restroom),
              const SizedBox(height: 12),
              _buildTextField(parentNameController, "Parent Name *", Icons.person),
              const SizedBox(height: 12),
              _buildTextField(parentEmailController, "Parent Email *", Icons.email,
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _buildTextField(parentPhoneController, "Parent Phone *", Icons.phone,
                  keyboardType: TextInputType.phone),

              const SizedBox(height: 24),

              // Info Card
              _buildInfoCard(),

              const SizedBox(height: 24),

              // Submit Button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.green, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ],
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
        prefixIcon: Icon(icon, color: Colors.green),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      hint: const Text("Select Gender"),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.people, color: Colors.green),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
        prefixIcon: const Icon(Icons.bloodtype, color: Colors.green),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() {
            dobController.text = DateFormat('yyyy-MM-dd').format(date);
          });
        }
      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: dobController,
          decoration: InputDecoration(
            labelText: "Date of Birth",
            prefixIcon: const Icon(Icons.cake, color: Colors.green),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.green.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Parent Account Info",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "Default password for parent: $defaultParentPassword",
                  style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                ),
                Text(
                  "Parent can change password after first login",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : _addStudent,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: loading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : const Text(
          "Add Student",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _addStudent() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate parent email
    if (parentEmailController.text.trim().isEmpty) {
      _showError("Parent email is required");
      return;
    }

    setState(() => loading = true);

    try {
      final schoolRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId);

      final parentEmail = parentEmailController.text.trim().toLowerCase();

      String parentUid;
      bool isNewParent = false;

      // Check if parent already exists
      final parentQuery = await schoolRef
          .collection('parents')
          .where('email', isEqualTo: parentEmail)
          .limit(1)
          .get();

      if (parentQuery.docs.isEmpty) {
        isNewParent = true;

        try {
          final userCredential = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
            email: parentEmail,
            password: defaultParentPassword,
          );
          parentUid = userCredential.user!.uid;
          await userCredential.user!.sendEmailVerification();
        } catch (authError) {
          if (authError.toString().contains('email-already-in-use')) {
            _showError(
              "Parent email already registered. Please use a different email.",
            );
            setState(() => loading = false);
            return;
          }
          rethrow;
        }
      } else {
        parentUid = parentQuery.docs.first.id;
      }

      // Create parent profile in Firestore
      await schoolRef.collection('parents').doc(parentUid).set({
        'email': parentEmail,
        'name': parentNameController.text.trim(),
        'phone': parentPhoneController.text.trim(),
        'firstLogin': isNewParent,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Create student record with class and section from widget
      final studentData = {
        'name': nameController.text.trim(),
        'class': widget.className,
        'section': widget.section,
        'rollNo': rollController.text.trim(),
        'parentUid': parentUid,
        'parentEmail': parentEmail,
        'admissionNo': admissionNoController.text.trim(),
        'dob': dobController.text.trim(),
        'bloodGroup': bloodGroupController.text.trim(),
        'gender': _selectedGender,
        'address': addressController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final studentRef = await schoolRef
          .collection('students')
          .add(studentData);

      // Also add to class-specific collection
      await schoolRef
          .collection('classes')
          .doc(widget.className)
          .collection('students')
          .doc(studentRef.id)
          .set({
        'studentId': studentRef.id,
        'name': nameController.text.trim(),
        'rollNo': rollController.text.trim(),
        'parentUid': parentUid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        String successMessage = isNewParent
            ? "Student added! Parent can login with:\nEmail: $parentEmail\nPassword: $defaultParentPassword"
            : "Student added successfully!";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error adding student: $e');
      _showError("Error: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => loading = false);
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
}