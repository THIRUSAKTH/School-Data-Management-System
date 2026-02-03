import 'package:flutter/material.dart';
import 'package:schoolprojectjan/screens/admin/admin_home.dart';
import 'package:schoolprojectjan/screens/parents/parent_home.dart';
import 'package:schoolprojectjan/screens/student/student_home.dart';
import 'package:schoolprojectjan/screens/teacher/teacher_home.dart';

class LoginPage extends StatefulWidget {
  final Map<String, dynamic> details;

  const LoginPage({super.key, required this.details});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isVisible = true;
  bool isCheck = false;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff8a27e9),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 420, // 👈 perfect for web & mobile
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Back button
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "⬅ Back to Role Selection",
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Icon
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: widget.details["color"],
                        child: const Icon(Icons.group,
                            color: Colors.white, size: 42),
                      ),

                      const SizedBox(height: 16),

                      // Role title
                      Text(
                        widget.details["role"],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Role description
                      Text(
                        widget.details["roleDescription"],
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black54),
                      ),

                      const SizedBox(height: 24),

                      // Email
                      _label("Email Address"),
                      _textField(
                        controller: emailController,
                        hint: "Enter email",
                      ),

                      const SizedBox(height: 16),

                      // Password
                      _label("Password"),
                      _textField(
                        controller: passwordController,
                        hint: "Enter password",
                        obscure: isVisible,
                        suffix: IconButton(
                          icon: Icon(isVisible
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              isVisible = !isVisible;
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Remember + Forgot
                      Row(
                        children: [
                          Checkbox(
                            value: isCheck,
                            onChanged: (value) {
                              setState(() {
                                isCheck = value!;
                              });
                            },
                          ),
                          const Text("Remember Me", style: TextStyle(fontSize: 13)),
                          const Spacer(),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              "Forgot Password?",
                              style: TextStyle(
                                color: widget.details["color"],
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Sign in
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            final role = widget.details["role"];

                            Widget target;

                            if (role == "Admin") {
                              target = const AdminHome();
                            } else if (role == "Teacher") {
                              target = const TeacherHome();
                            } else if (role == "Parent") {
                              target = const ParentHome();
                            } else {
                              target = const StudentHome();
                            }

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => target),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.details["color"],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "Sign In",
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Contact admin
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account?",
                            style: TextStyle(fontSize: 13),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              "Contact Admin",
                              style: TextStyle(
                                color: widget.details["color"],
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------- HELPERS ----------------

  Widget _label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.black12,
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}