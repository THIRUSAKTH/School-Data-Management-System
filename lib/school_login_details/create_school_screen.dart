import 'package:flutter/material.dart';

class CreateSchoolScreen extends StatelessWidget {
  CreateSchoolScreen({super.key});

  final _formKey = GlobalKey<FormState>();

  final TextEditingController schoolNameController =
  TextEditingController();
  final TextEditingController addressController =
  TextEditingController();
  final TextEditingController adminNameController =
  TextEditingController();
  final TextEditingController emailController =
  TextEditingController();
  final TextEditingController mobileController =
  TextEditingController();
  final TextEditingController passwordController =
  TextEditingController();

  String selectedBoard = "State Board";

  final List<String> boards = [
    "State Board",
    "CBSE",
    "ICSE",
    "IB",
    "Other",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff851ef3),
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
                  /// ICON
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: const Color(0xff9c45f8),
                    child: const Icon(
                      Icons.school_outlined,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 14),

                  /// TITLE
                  const Text(
                    "Create School Account",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    "Register your school to get started",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// FORM CARD
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
                          /// SECTION: SCHOOL DETAILS
                          const Text(
                            "School Details",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),

                          _inputField(
                            controller: schoolNameController,
                            label: "School Name",
                            icon: Icons.apartment,
                          ),

                          const SizedBox(height: 12),

                          DropdownButtonFormField<String>(
                            value: selectedBoard,
                            items: boards
                                .map(
                                  (b) => DropdownMenuItem(
                                value: b,
                                child: Text(b),
                              ),
                            )
                                .toList(),
                            onChanged: (value) {
                              selectedBoard = value!;
                            },
                            decoration: _inputDecoration(
                              "Board / School Type",
                              Icons.school,
                            ),
                          ),

                          const SizedBox(height: 12),

                          _inputField(
                            controller: addressController,
                            label: "School Address",
                            icon: Icons.location_on_outlined,
                            maxLines: 2,
                          ),

                          const SizedBox(height: 24),

                          /// SECTION: ADMIN DETAILS
                          const Text(
                            "Admin Details",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),

                          _inputField(
                            controller: adminNameController,
                            label: "Admin Name",
                            icon: Icons.person_outline,
                          ),

                          const SizedBox(height: 12),

                          _inputField(
                            controller: emailController,
                            label: "Email",
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

                          /// CREATE BUTTON
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  // TODO:
                                  // 1. Create School
                                  // 2. Generate School Code
                                  // 3. Create Admin user
                                  // 4. Save data in backend
                                  // 5. Navigate to RoleSelectScreen
                                }
                              },
                              child: const Text(
                                "Create School Account",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white
                                ),
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

  /// INPUT FIELD
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
      validator: (value) =>
      value == null || value.isEmpty ? "Required field" : null,
      decoration: _inputDecoration(label, icon),
    );
  }

  /// INPUT DECORATION
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
