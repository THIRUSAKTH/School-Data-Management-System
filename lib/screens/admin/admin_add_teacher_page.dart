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

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _qualificationController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Data variables
  List<String> _selectedSubjects = [];
  List<String> _availableSubjects = [];
  List<Map<String, String>> _assignedClasses = [];

  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  DateTime? _joiningDate;
  String? _gender;
  String? _selectedDepartment;

  // Constants
  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _departments = [
    'Tamil',
    'English',
    'Mathematics',
    'Science',
    'Physics',
    'Chemistry',
    'Biology',
    'History',
    'Geography',
    'Computer Science',
    'Accountancy',
    'Commerce',
    'Economics',
    'Physical Education',
    'Arts',
    'Music',
  ];

  // Default password for new teacher accounts
  static const String defaultTeacherPassword = "Teacher@123";

  @override
  void initState() {
    super.initState();
    _loadAvailableSubjects();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _qualificationController.dispose();
    _experienceController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableSubjects() async {
    try {
      final subjectsSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('subjects')
          .get();

      if (subjectsSnapshot.docs.isNotEmpty) {
        setState(() {
          _availableSubjects = subjectsSnapshot.docs
              .map((doc) => doc['name'] as String)
              .toList();
        });
      } else {
        // Default subjects as fallback
        setState(() {
          _availableSubjects = [
            "Tamil", "English", "Mathematics", "Physics", "Chemistry",
            "Biology", "History", "Geography", "Computer Science",
            "Accountancy", "Commerce", "Economics", "Physical Education",
            "Art", "Music",
          ];
        });
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAvailableSubjects,
            tooltip: "Refresh Subjects",
          ),
        ],
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
                _nameController,
                "Full Name *",
                Icons.person_outline,
              ),
              const SizedBox(height: 12),
              _buildGenderDropdown(),
              const SizedBox(height: 12),
              _buildTextField(
                _emailController,
                "Email Address *",
                Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                _phoneController,
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
                _qualificationController,
                "Qualification",
                Icons.school,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                _experienceController,
                "Years of Experience",
                Icons.timeline,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                _addressController,
                "Address",
                Icons.location_on,
                maxLines: 2,
              ),

              const SizedBox(height: 24),

              // Account Information Section
              _buildSectionHeader("Account Information", Icons.lock),
              const SizedBox(height: 12),
              _buildTextField(
                _passwordController,
                "Temporary Password *",
                Icons.lock,
                isPassword: true,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                _confirmPasswordController,
                "Confirm Password *",
                Icons.lock_outline,
                isPassword: true,
                isConfirmPassword: true,
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
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.deepPurple, size: 20),
        ),
        const SizedBox(width: 10),
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
        int maxLines = 1,
        bool isPassword = false,
        bool isConfirmPassword = false,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword
          ? (label.contains('Temporary') ? !_showPassword : !_showConfirmPassword)
          : false,
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
        if (isPassword && value != null && value.isNotEmpty) {
          if (value.length < 6) {
            return "Password must be at least 6 characters";
          }
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.deepPurple, size: 20),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            (label.contains('Temporary') ? _showPassword : _showConfirmPassword)
                ? Icons.visibility_off
                : Icons.visibility,
            color: Colors.grey,
          ),
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
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _gender,
      hint: const Text("Select Gender *"),
      isExpanded: true,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.people, color: Colors.deepPurple, size: 20),
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
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      items: _genders.map((gender) {
        return DropdownMenuItem(
          value: gender,
          child: Text(gender),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _gender = value;
        });
      },
      validator: (value) => value == null ? "Please select gender" : null,
    );
  }

  Widget _buildDepartmentDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedDepartment,
      hint: const Text("Select Department"),
      isExpanded: true,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.business, color: Colors.deepPurple, size: 20),
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
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text("Select Department"),
        ),
        ..._departments.map((dept) {
          return DropdownMenuItem(
            value: dept,
            child: Text(dept),
          );
        }).toList(),
      ],
      onChanged: (value) {
        setState(() {
          _selectedDepartment = value;
        });
      },
    );
  }

  Widget _buildSubjectsMultiselect() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Subjects *",
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableSubjects.map((subject) {
              final isSelected = _selectedSubjects.contains(subject);
              return FilterChip(
                label: Text(subject, style: const TextStyle(fontSize: 12)),
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
              padding: EdgeInsets.only(top: 12),
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
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _joiningDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() {
            _joiningDate = picked;
          });
        }
      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: TextEditingController(
            text: _joiningDate != null
                ? "${_joiningDate!.day}/${_joiningDate!.month}/${_joiningDate!.year}"
                : '',
          ),
          decoration: InputDecoration(
            labelText: "Joining Date",
            prefixIcon: const Icon(Icons.calendar_today, color: Colors.deepPurple, size: 20),
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

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade50, Colors.deepPurple.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.info_outline, color: Colors.deepPurple.shade700, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Teacher Account Information",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 11),
                    children: [
                      const TextSpan(
                        text: "Default Password: ",
                        style: TextStyle(color: Colors.grey),
                      ),
                      TextSpan(
                        text: defaultTeacherPassword,
                        style: TextStyle(
                          color: Colors.deepPurple.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  "Teacher must change password on first login",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
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
        onPressed: _isLoading ? null : _addTeacher,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
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
    // Validate form
    if (!_formKey.currentState!.validate()) return;

    // Validate subjects
    if (_selectedSubjects.isEmpty) {
      _showError("Please select at least one subject");
      return;
    }

    // Validate password match
    final String password = _passwordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      _showError("Passwords do not match");
      return;
    }

    if (password.length < 6) {
      _showError("Password must be at least 6 characters");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String email = _emailController.text.trim().toLowerCase();

      // Create Firebase Auth user
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String uid = userCredential.user!.uid;

      // Send email verification
      await userCredential.user!.sendEmailVerification();

      // Prepare teacher data
      final Map<String, dynamic> teacherData = {
        'uid': uid,
        'name': _nameController.text.trim(),
        'email': email,
        'phone': _phoneController.text.trim(),
        'gender': _gender,
        'qualification': _qualificationController.text.trim(),
        'experience': _experienceController.text.trim(),
        'address': _addressController.text.trim(),
        'subjects': _selectedSubjects,
        'department': _selectedDepartment,
        'joiningDate': _joiningDate != null
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
              "✅ Teacher created successfully!\n\nEmail: $email\nPassword: $password",
              style: const TextStyle(fontSize: 13),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );

        // Clear form after success
        _clearForm();

        // Wait a moment before popping
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "";
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = "Email already in use. Please use a different email.";
          break;
        case 'invalid-email':
          errorMessage = "Invalid email format.";
          break;
        case 'weak-password':
          errorMessage = "Password is too weak. Use at least 6 characters.";
          break;
        default:
          errorMessage = "Error: ${e.message}";
      }
      _showError(errorMessage);
    } catch (e) {
      debugPrint('Error adding teacher: $e');
      _showError("Error: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _qualificationController.clear();
    _experienceController.clear();
    _addressController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    setState(() {
      _selectedSubjects = [];
      _gender = null;
      _selectedDepartment = null;
      _joiningDate = null;
      _showPassword = false;
      _showConfirmPassword = false;
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}