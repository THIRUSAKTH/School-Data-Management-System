import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'school_created_success_screen.dart';

class CreateSchoolScreen extends StatelessWidget {
  CreateSchoolScreen({super.key});

  final _formKey = GlobalKey<FormState>();

  final TextEditingController schoolNameController = TextEditingController();
  final TextEditingController schoolEmailController = TextEditingController(); // ✅ NEW
  final TextEditingController addressController = TextEditingController();
  final TextEditingController adminNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String selectedBoard = "State Board";

  final List<String> boards = ["State Board", "CBSE", "ICSE", "IB", "Other"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.cyan,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.cyan.shade200,
                    child: const Icon(
                      Icons.school_outlined,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "Create School Account",
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Register your school to get started",
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("School Details",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),

                          _inputField(
                            controller: schoolNameController,
                            label: "School Name",
                            icon: Icons.apartment,
                          ),

                          const SizedBox(height: 12),

                          // ✅ SCHOOL EMAIL FIELD ADDED
                          _inputField(
                            controller: schoolEmailController,
                            label: "School Email ID",
                            icon: Icons.alternate_email,
                            keyboardType: TextInputType.emailAddress,
                          ),

                          const SizedBox(height: 12),

                          DropdownButtonFormField<String>(
                            value: selectedBoard,
                            items: boards
                                .map((b) => DropdownMenuItem(
                              value: b,
                              child: Text(b),
                            ))
                                .toList(),
                            onChanged: (v) => selectedBoard = v!,
                            decoration: _inputDecoration(
                                "Board / School Type", Icons.school),
                          ),

                          const SizedBox(height: 12),

                          _inputField(
                            controller: addressController,
                            label: "School Address",
                            icon: Icons.location_on_outlined,
                            maxLines: 2,
                          ),

                          const SizedBox(height: 24),

                          const Text("Admin Details",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),

                          _inputField(
                            controller: adminNameController,
                            label: "Admin Name",
                            icon: Icons.person_outline,
                          ),

                          const SizedBox(height: 12),

                          _inputField(
                            controller: emailController,
                            label: "Admin Email",
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),

                          const SizedBox(height: 12),

                          _inputField(
                            controller: mobileController,
                            label: "Mobile Number",
                            icon: Icons.phone_android,
                            keyboardType: TextInputType.phone,
                          ),

                          const SizedBox(height: 12),

                          _inputField(
                            controller: passwordController,
                            label: "Password",
                            icon: Icons.lock_outline,
                            obscure: true,
                          ),

                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  try {
                                    final schoolCode =
                                    _generateSchoolCode(
                                        schoolNameController.text);

                                    final userCredential = await FirebaseAuth
                                        .instance
                                        .createUserWithEmailAndPassword(
                                      email: emailController.text.trim(),
                                      password:
                                      passwordController.text.trim(),
                                    );

                                    final adminUid =
                                        userCredential.user!.uid;

                                    final schoolRef = FirebaseFirestore.instance
                                        .collection('schools')
                                        .doc();

                                    await schoolRef.set({
                                      'schoolId': schoolRef.id,
                                      'schoolCode': schoolCode,
                                      'schoolName':
                                      schoolNameController.text,
                                      'schoolEmail':
                                      schoolEmailController.text,
                                      'board': selectedBoard,
                                      'address': addressController.text,
                                      'createdAt':
                                      FieldValue.serverTimestamp(),
                                    });

                                    await schoolRef
                                        .collection('admins')
                                        .doc(adminUid)
                                        .set({
                                      'uid': adminUid,
                                      'name':
                                      adminNameController.text,
                                      'email':
                                      emailController.text,
                                      'mobile':
                                      mobileController.text,
                                      'role': 'Admin',
                                      'createdAt':
                                      FieldValue.serverTimestamp(),
                                    });

                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            SchoolCreatedSuccessScreen(
                                              schoolCode: schoolCode,
                                            ),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                          content: Text("Error: $e")),
                                    );
                                  }
                                }
                              },
                              child: const Text(
                                "Create School Account",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      maxLines: maxLines,
      validator: (v) => v == null || v.isEmpty ? "Required field" : null,
      decoration: _inputDecoration(label, icon),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

/// SCHOOL CODE GENERATOR
String _generateSchoolCode(String schoolName) {
  final prefix = schoolName
      .replaceAll(RegExp(r'[^A-Za-z]'), '')
      .toUpperCase()
      .padRight(3, 'X')
      .substring(0, 3);

  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final rand = Random();

  return "$prefix-${List.generate(4, (_) => chars[rand.nextInt(chars.length)]).join()}";
}
