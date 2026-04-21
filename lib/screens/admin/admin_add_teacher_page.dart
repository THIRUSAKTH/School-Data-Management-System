import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app_config.dart';

class AdminAddTeacherPage extends StatefulWidget {
  final String schoolId;

  const AdminAddTeacherPage({super.key, required this.schoolId});

  @override
  State<AdminAddTeacherPage> createState() => _AdminAddTeacherPageState();
}

class _AdminAddTeacherPageState extends State<AdminAddTeacherPage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final qualificationController = TextEditingController();
  final experienceController = TextEditingController();
  final addressController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  List<String> _selectedSubjects = [];
  List<String> _availableSubjects = [];
  List<Map<String, String>> _assignedClasses = [];

  bool loading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  DateTime? _joiningDate;
  String? _gender;
  String? _selectedDepartment;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _departments = [
    'Tamizh',
    'Science',
    'Mathematics',
    'Languages',
    'Social Studies',
    'Computer Science',
    'Physical Education',
    'Arts',
  ];

  @override
  void initState() {
    super.initState();
    _loadAvailableSubjects();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    qualificationController.dispose();
    experienceController.dispose();
    addressController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableSubjects() async {
    try {
      final subjectsSnapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('subjects')
              .get();

      if (subjectsSnapshot.docs.isNotEmpty) {
        setState(() {
          _availableSubjects =
              subjectsSnapshot.docs
                  .map((doc) => doc['name'] as String)
                  .toList();
        });
      } else {
        // Default subjects
        _availableSubjects = [
          "Tamil",
          "English",
          'Mathematics',
          'Physics',
          'Chemistry',
          'Biology',
          'History',
          'Geography',
          'Computer Science',
          "Accountancy",
          'Physical Education',
          'Art',
          'Music',
          "Commerce",
          "Economics",
        ];
      }
    } catch (e) {
      debugPrint('Error loading subjects: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          "Add New Teacher",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Personal Information Section
              _buildSectionHeader("Personal Information", Icons.person),
              const SizedBox(height: 12),
              _buildTextField(
                nameController,
                "Full Name *",
                Icons.person_outline,
              ),
              const SizedBox(height: 12),
              _buildGenderDropdown(),
              const SizedBox(height: 12),
              _buildTextField(
                emailController,
                "Email Address *",
                Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                phoneController,
                "Phone Number *",
                Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _buildDatePickerField(),

              const SizedBox(height: 24),

              // Professional Information Section
              _buildSectionHeader("Professional Information", Icons.work),
              const SizedBox(height: 12),
              _buildDepartmentDropdown(),
              const SizedBox(height: 12),
              _buildSubjectsMultiselect(),
              const SizedBox(height: 12),
              _buildTextField(
                qualificationController,
                "Qualification",
                Icons.school,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                experienceController,
                "Years of Experience",
                Icons.timeline,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                addressController,
                "Address",
                Icons.location_on,
                maxLines: 2,
              ),

              const SizedBox(height: 24),

              // Account Information Section
              _buildSectionHeader("Account Information", Icons.lock),
              const SizedBox(height: 12),
              _buildTextField(
                passwordController,
                "Temporary Password *",
                Icons.lock,
                hide: !_showPassword,
                isPassword: true,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                confirmPasswordController,
                "Confirm Password *",
                Icons.lock_outline,
                hide: !_showConfirmPassword,
                isPassword: true,
              ),

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
        Icon(icon, color: Colors.deepPurple, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool hide = false,
    int maxLines = 1,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: hide,
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
        if (isPassword && v != null && v.isNotEmpty) {
          if (v.length < 6) {
            return "Password must be at least 6 characters";
          }
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        suffixIcon:
            isPassword
                ? IconButton(
                  icon: Icon(hide ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      if (label.contains('Temporary')) {
                        _showPassword = !_showPassword;
                      } else if (label.contains('Confirm')) {
                        _showConfirmPassword = !_showConfirmPassword;
                      }
                    });
                  },
                )
                : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _gender,
      hint: const Text("Select Gender *"),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.people, color: Colors.deepPurple),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items:
          _genders.map((gender) {
            return DropdownMenuItem(value: gender, child: Text(gender));
          }).toList(),
      onChanged: (value) {
        setState(() {
          _gender = value;
        });
      },
      validator: (v) => v == null ? "Please select gender" : null,
    );
  }

  Widget _buildDepartmentDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedDepartment,
      hint: const Text("Select Department"),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.business, color: Colors.deepPurple),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items:
          _departments.map((dept) {
            return DropdownMenuItem(value: dept, child: Text(dept));
          }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedDepartment = value;
        });
      },
    );
  }

  Widget _buildSubjectsMultiselect() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              "Subjects *",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _availableSubjects.map((subject) {
                  final isSelected = _selectedSubjects.contains(subject);
                  return FilterChip(
                    label: Text(subject),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSubjects.add(subject);
                        } else {
                          _selectedSubjects.remove(subject);
                        }
                      });
                    },
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: Colors.deepPurple.shade100,
                    checkmarkColor: Colors.deepPurple,
                  );
                }).toList(),
          ),
          if (_selectedSubjects.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                "Please select at least one subject",
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDatePickerField() {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _joiningDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() {
            _joiningDate = date;
          });
        }
      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: TextEditingController(
            text:
                _joiningDate != null
                    ? "${_joiningDate!.day}/${_joiningDate!.month}/${_joiningDate!.year}"
                    : '',
          ),
          decoration: InputDecoration(
            labelText: "Joining Date",
            prefixIcon: const Icon(
              Icons.calendar_today,
              color: Colors.deepPurple,
            ),
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
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.deepPurple.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Teacher Account Info",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "Teacher will receive a welcome email with login credentials",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
                Text(
                  "Teacher must change password on first login",
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
        onPressed: loading ? null : _addTeacher,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child:
            loading
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : const Text(
                  "Create Teacher Account",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
      ),
    );
  }

  Future<void> _addTeacher() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSubjects.isEmpty) {
      _showError("Please select at least one subject");
      return;
    }

    if (passwordController.text.trim() !=
        confirmPasswordController.text.trim()) {
      _showError("Passwords do not match");
      return;
    }

    setState(() => loading = true);

    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      // Create Firebase Auth user
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;

      // Send email verification
      await cred.user!.sendEmailVerification();

      // Prepare teacher data
      final teacherData = {
        'uid': uid,
        'name': nameController.text.trim(),
        'email': email,
        'phone': phoneController.text.trim(),
        'gender': _gender,
        'qualification': qualificationController.text.trim(),
        'experience': experienceController.text.trim(),
        'address': addressController.text.trim(),
        'subjects': _selectedSubjects,
        'department': _selectedDepartment,
        'joiningDate':
            _joiningDate != null
                ? "${_joiningDate!.year}-${_joiningDate!.month.toString().padLeft(2, '0')}-${_joiningDate!.day.toString().padLeft(2, '0')}"
                : null,
        'assignedClasses': [], // Initially no classes assigned
        'firstLogin': true, // Force password change on first login
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save teacher in school collection
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('teachers')
          .doc(uid)
          .set(teacherData);

      // Also add to global teachers collection for easier querying
      await FirebaseFirestore.instance.collection('teachers').doc(uid).set({
        ...teacherData,
        'schoolId': widget.schoolId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Teacher created successfully!\nEmail: $email\nPassword: $password",
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error adding teacher: $e');
      _showError("Error: $e");
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
