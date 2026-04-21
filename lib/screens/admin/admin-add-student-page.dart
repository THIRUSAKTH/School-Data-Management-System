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

  final nameController = TextEditingController();
  final classController = TextEditingController();
  final sectionController = TextEditingController();
  final rollController = TextEditingController();
  final parentEmailController = TextEditingController();
  final parentNameController = TextEditingController();
  final parentPhoneController = TextEditingController();
  final admissionNoController = TextEditingController();
  final dobController = TextEditingController();
  final bloodGroupController = TextEditingController();

  bool loading = false;
  bool _isLoadingClasses = true;
  String? _selectedClass;

  // Default classes as fallback
  List<String> _availableClasses = [
    "LKG", "UKG",
    "CLASS I", "CLASS II", "CLASS III", "CLASS IV", "CLASS V",
    "CLASS VI", "CLASS VII", "CLASS VIII", "CLASS IX", "CLASS X",
    "CLASS XI", "CLASS XII",
  ];

  List<String> _availableSections = ['A', 'B', 'C', 'D'];

  // Default password for new parent accounts
  final String defaultParentPassword = "Parent@123";

  @override
  void initState() {
    super.initState();
    _loadAvailableClasses();
  }

  @override
  void dispose() {
    nameController.dispose();
    classController.dispose();
    sectionController.dispose();
    rollController.dispose();
    parentEmailController.dispose();
    parentNameController.dispose();
    parentPhoneController.dispose();
    admissionNoController.dispose();
    dobController.dispose();
    bloodGroupController.dispose();
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
      // Keep default classes as fallback
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
                nameController,
                "Student Name *",
                Icons.person_outline,
              ),
              const SizedBox(height: 12),
              _buildClassDropdown(),
              const SizedBox(height: 12),
              _buildSectionDropdown(),
              const SizedBox(height: 12),
              _buildTextField(rollController, "Roll Number *", Icons.numbers),
              const SizedBox(height: 12),
              _buildTextField(
                admissionNoController,
                "Admission Number",
                Icons.badge,
              ),
              const SizedBox(height: 12),
              _buildDatePickerField(),
              const SizedBox(height: 12),
              _buildTextField(
                bloodGroupController,
                "Blood Group",
                Icons.bloodtype,
              ),

              const SizedBox(height: 24),

              // Parent Information Section
              _buildSectionHeader("Parent Information", Icons.family_restroom),
              const SizedBox(height: 12),
              _buildTextField(
                parentNameController,
                "Parent Name *",
                Icons.person,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                parentEmailController,
                "Parent Email *",
                Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                parentPhoneController,
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
        Icon(icon, color: Colors.blue, size: 22),
        const SizedBox(width: 8),
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
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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
        prefixIcon: Icon(icon, color: Colors.blue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildClassDropdown() {
    if (_isLoadingClasses) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedClass,
      hint: const Text("Select Class *"),
      isExpanded: true,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.class_, color: Colors.blue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
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
            classController.text = value;
          } else {
            classController.text = '';
          }
        });
      },
      validator: (value) {
        if (_selectedClass == null && classController.text.isEmpty) {
          return "Please select a class";
        }
        return null;
      },
    );
  }

  Widget _buildSectionDropdown() {
    return DropdownButtonFormField<String>(
      value: sectionController.text.isEmpty ? null : sectionController.text,
      hint: const Text("Select Section *"),
      isExpanded: true,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.group, color: Colors.blue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: [
        const DropdownMenuItem<String>(value: null, child: Text("Select Section")),
        ..._availableSections.map((section) {
          return DropdownMenuItem<String>(
            value: section,
            child: Text(section),
          );
        }).toList(),
      ],
      onChanged: (value) {
        setState(() {
          sectionController.text = value ?? '';
        });
      },
      validator: (value) {
        if (sectionController.text.isEmpty) {
          return "Please select a section";
        }
        return null;
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
            dobController.text = "${date.day}/${date.month}/${date.year}";
          });
        }
      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: dobController,
          decoration: InputDecoration(
            labelText: "Date of Birth",
            prefixIcon: const Icon(Icons.cake, color: Colors.blue),
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
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700),
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
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
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
          backgroundColor: Colors.blue,
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
          "Create Student & Parent Account",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _addStudent() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate class selection
    final className = _selectedClass ?? classController.text.trim();
    if (className.isEmpty) {
      _showError("Please select a class");
      return;
    }

    // Validate parent email
    if (parentEmailController.text.trim().isEmpty) {
      _showError("Parent email is required");
      return;
    }

    setState(() => loading = true);

    try {
      final schoolRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId);

      final parentEmail = parentEmailController.text.trim().toLowerCase();
      final adminUser = FirebaseAuth.instance.currentUser;

      if (adminUser == null) {
        _showError("Admin not logged in");
        setState(() => loading = false);
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

      // Create student record
      final studentData = {
        'name': nameController.text.trim(),
        'class': className,
        'section': sectionController.text.trim(),
        'rollNo': rollController.text.trim(),
        'parentUid': parentUid,
        'parentEmail': parentEmail,
        'admissionNo': admissionNoController.text.trim(),
        'dob': dobController.text.trim(),
        'bloodGroup': bloodGroupController.text.trim(),
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
        'name': nameController.text.trim(),
        'rollNo': rollController.text.trim(),
        'parentUid': parentUid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        String successMessage = isNewParent
            ? "Student created! Parent can login with:\nEmail: $parentEmail\nPassword: $defaultParentPassword"
            : "Student linked to existing parent successfully";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
        Navigator.pop(context);
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