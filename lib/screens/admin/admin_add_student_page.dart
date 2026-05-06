import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app_config.dart';

class AdminAddStudentPage extends StatefulWidget {
  final String schoolId;

  const AdminAddStudentPage({super.key, required this.schoolId});

  @override
  State<AdminAddStudentPage> createState() => _AdminAddStudentPageState();
}

class _AdminAddStudentPageState extends State<AdminAddStudentPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _sectionController = TextEditingController();
  final TextEditingController _rollController = TextEditingController();
  final TextEditingController _parentEmailController = TextEditingController();
  final TextEditingController _parentNameController = TextEditingController();
  final TextEditingController _parentPhoneController = TextEditingController();
  final TextEditingController _admissionNoController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _bloodGroupController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingClasses = true;
  String? _selectedClass;
  String? _selectedSection;

  // Default classes as fallback
  List<String> _availableClasses = [
    "LKG", "UKG",
    "CLASS 1", "CLASS 2", "CLASS 3", "CLASS 4", "CLASS 5",
    "CLASS 6", "CLASS 7", "CLASS 8", "CLASS 9", "CLASS 10",
    "CLASS 11", "CLASS 12",
  ];

  List<String> _availableSections = ['A', 'B', 'C', 'D'];

  // Default password for new parent accounts
  static const String defaultParentPassword = "Parent@123";

  @override
  void initState() {
    super.initState();
    _loadAvailableClasses();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _classController.dispose();
    _sectionController.dispose();
    _rollController.dispose();
    _parentEmailController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _admissionNoController.dispose();
    _dobController.dispose();
    _bloodGroupController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableClasses() async {
    setState(() => _isLoadingClasses = true);

    try {
      final classesSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('classes')
          .get();

      if (classesSnapshot.docs.isNotEmpty) {
        final loadedClasses = classesSnapshot.docs
            .map((doc) {
          final data = doc.data();
          return (data['class'] ?? data['className'] ?? '').toString();
        })
            .where((name) => name.isNotEmpty)
            .toList();

        if (loadedClasses.isNotEmpty) {
          setState(() {
            _availableClasses = loadedClasses;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading classes: $e');
    } finally {
      setState(() => _isLoadingClasses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          "Add New Student",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAvailableClasses,
            tooltip: "Refresh Classes",
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
              // Student Information Section
              _buildSectionHeader("Student Information", Icons.person),
              const SizedBox(height: 12),
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
              _buildTextField(
                _rollController,
                "Roll Number *",
                Icons.numbers,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                _admissionNoController,
                "Admission Number",
                Icons.badge,
              ),
              const SizedBox(height: 12),
              _buildDatePickerField(),
              const SizedBox(height: 12),
              _buildTextField(
                _bloodGroupController,
                "Blood Group",
                Icons.bloodtype,
              ),

              const SizedBox(height: 24),

              // Parent Information Section
              _buildSectionHeader("Parent Information", Icons.family_restroom),
              const SizedBox(height: 12),
              _buildTextField(
                _parentNameController,
                "Parent Name *",
                Icons.person,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                _parentEmailController,
                "Parent Email *",
                Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                _parentPhoneController,
                "Parent Phone *",
                Icons.phone,
                keyboardType: TextInputType.phone,
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
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.blue, size: 20),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
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
        if (label.contains('Roll Number') && value != null && value.isNotEmpty) {
          if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
            return "Roll number should contain only numbers";
          }
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.blue, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
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
    if (_isLoadingClasses) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: const Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedClass,
      hint: const Text("Select Class *"),
      isExpanded: true,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.class_, color: Colors.blue, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
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
          child: Text("Select Class"),
        ),
        ..._availableClasses.map((className) {
          return DropdownMenuItem<String>(
            value: className,
            child: Text(className),
          );
        }).toList(),
      ],
      onChanged: (value) {
        setState(() {
          _selectedClass = value;
          if (value != null) {
            _classController.text = value;
          } else {
            _classController.text = '';
          }
        });
      },
      validator: (value) {
        if (_selectedClass == null && _classController.text.isEmpty) {
          return "Please select a class";
        }
        return null;
      },
    );
  }

  Widget _buildSectionDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSection,
      hint: const Text("Select Section *"),
      isExpanded: true,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.group, color: Colors.blue, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
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
          child: Text("Select Section"),
        ),
        ..._availableSections.map((section) {
          return DropdownMenuItem<String>(
            value: section,
            child: Text(section),
          );
        }).toList(),
      ],
      onChanged: (value) {
        setState(() {
          _selectedSection = value;
          if (value != null) {
            _sectionController.text = value;
          } else {
            _sectionController.text = '';
          }
        });
      },
      validator: (value) {
        if (_selectedSection == null && _sectionController.text.isEmpty) {
          return "Please select a section";
        }
        return null;
      },
    );
  }

  Widget _buildDatePickerField() {
    return GestureDetector(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() {
            _dobController.text = "${picked.day}/${picked.month}/${picked.year}";
          });
        }
      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: _dobController,
          decoration: InputDecoration(
            labelText: "Date of Birth",
            prefixIcon: const Icon(Icons.cake, color: Colors.blue, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
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
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Parent Account Information",
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
                        text: defaultParentPassword,
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  "Parent can change password after first login",
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
        onPressed: _isLoading ? null : _addStudent,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
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
          "Create Student & Parent Account",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _addStudent() async {
    // Validate form
    if (!_formKey.currentState!.validate()) return;

    // Get class name
    final String className = _selectedClass ?? _classController.text.trim();
    if (className.isEmpty) {
      _showError("Please select a class");
      return;
    }

    // Get section
    final String section = _selectedSection ?? _sectionController.text.trim();
    if (section.isEmpty) {
      _showError("Please select a section");
      return;
    }

    // Validate parent email
    final String parentEmail = _parentEmailController.text.trim().toLowerCase();
    if (parentEmail.isEmpty) {
      _showError("Parent email is required");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final schoolRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId);

      final adminUser = FirebaseAuth.instance.currentUser;
      if (adminUser == null) {
        _showError("Admin not logged in");
        setState(() => _isLoading = false);
        return;
      }

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
            setState(() => _isLoading = false);
            return;
          }
          rethrow;
        }
      } else {
        parentUid = parentQuery.docs.first.id;
      }

      // Create/Update parent profile in Firestore
      await schoolRef.collection('parents').doc(parentUid).set({
        'email': parentEmail,
        'name': _parentNameController.text.trim(),
        'phone': _parentPhoneController.text.trim(),
        'firstLogin': isNewParent,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Create student record
      final studentData = {
        'name': _nameController.text.trim(),
        'class': className,
        'section': section,
        'rollNo': _rollController.text.trim(),
        'parentUid': parentUid,
        'parentEmail': parentEmail,
        'admissionNo': _admissionNoController.text.trim(),
        'dob': _dobController.text.trim(),
        'bloodGroup': _bloodGroupController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final studentRef = await schoolRef
          .collection('students')
          .add(studentData);

      // Also add to class-specific collection
      await schoolRef
          .collection('classes')
          .doc(className)
          .collection('students')
          .doc(studentRef.id)
          .set({
        'studentId': studentRef.id,
        'name': _nameController.text.trim(),
        'rollNo': _rollController.text.trim(),
        'parentUid': parentUid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        String successMessage = isNewParent
            ? "Student created successfully!\n\nParent Login Details:\nEmail: $parentEmail\nPassword: $defaultParentPassword"
            : "Student linked to existing parent successfully!";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              successMessage,
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
    } catch (e) {
      debugPrint('Error adding student: $e');
      _showError("Error: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _classController.clear();
    _sectionController.clear();
    _rollController.clear();
    _parentEmailController.clear();
    _parentNameController.clear();
    _parentPhoneController.clear();
    _admissionNoController.clear();
    _dobController.clear();
    _bloodGroupController.clear();
    setState(() {
      _selectedClass = null;
      _selectedSection = null;
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