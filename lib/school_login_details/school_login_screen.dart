import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:schoolprojectjan/school_login_details/create_school_screen.dart';
import 'package:schoolprojectjan/screens/role_router/role_select_screen.dart';

class SchoolLoginScreen extends StatelessWidget {
  SchoolLoginScreen({super.key});

  final TextEditingController schoolEmailController = TextEditingController();
  final TextEditingController schoolCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:Colors.cyan,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.cyan.shade200,
                    child: const Icon(
                      Icons.school_outlined,
                      size: 45,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// ✅ SINGLE LINE RESPONSIVE HEADING
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: const Text(
                      "School Management System",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    "Manage your school digitally",
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
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: schoolEmailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: "School Email ID",
                            prefixIcon:
                            const Icon(Icons.alternate_email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextField(
                          controller: schoolCodeController,
                          textCapitalization:
                          TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: "School Code (Ex: ABC-7XQ2)",
                            prefixIcon:
                            const Icon(Icons.vpn_key_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyan,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              final email = schoolEmailController.text
                                  .trim()
                                  .toLowerCase();
                              final code =
                              schoolCodeController.text.trim();

                              if (email.isEmpty || code.isEmpty) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          "Enter email and school code")),
                                );
                                return;
                              }

                              try {
                                final query =
                                await FirebaseFirestore.instance
                                    .collection('schools')
                                    .where('schoolEmail',
                                    isEqualTo: email)
                                    .where('schoolCode',
                                    isEqualTo: code)
                                    .limit(1)
                                    .get();

                                if (query.docs.isEmpty) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            "Invalid school login")),
                                  );
                                  return;
                                }

                                final schoolId =
                                    query.docs.first.id;

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        RoleSelectScreen(
                                            schoolId: schoolId),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                      content:
                                      Text("Error: $e")),
                                );
                              }
                            },
                            child: const Text(
                              "Continue",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: const [
                            Expanded(child: Divider()),
                            Padding(
                              padding:
                              EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                "OR",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 18),

                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Colors.black),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CreateSchoolScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              "Create New School Account",
                              style: TextStyle(
                                color: Colors.cyan,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
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
}
