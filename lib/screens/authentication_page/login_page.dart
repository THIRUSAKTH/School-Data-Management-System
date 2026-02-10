import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:schoolprojectjan/screens/admin/admin_home.dart';
import 'package:schoolprojectjan/screens/teacher/teacher_home.dart';
import 'package:schoolprojectjan/screens/parents/parent_home_page.dart';
import 'package:schoolprojectjan/screens/authentication_page/change_password_screen.dart';

class LoginPage extends StatefulWidget {
  final String schoolId;
  final String role;

  const LoginPage({
    super.key,
    required this.schoolId,
    required this.role,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Color get roleColor {
    switch (widget.role) {
      case "Admin":
        return Colors.deepPurple;
      case "Teacher":
        return Colors.green;
      case "Parent":
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData get roleIcon {
    switch (widget.role) {
      case "Admin":
        return Icons.admin_panel_settings;
      case "Teacher":
        return Icons.school;
      case "Parent":
        return Icons.family_restroom;
      default:
        return Icons.lock_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: roleColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  decoration: BoxDecoration(
                    color: roleColor,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(roleIcon, size: 50, color: Colors.white),
                      const SizedBox(height: 12),
                      Text(
                        "${widget.role} Login",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _input(
                        controller: emailController,
                        hint: "Email Address",
                        icon: Icons.email_outlined,
                      ),

                      const SizedBox(height: 16),

                      _input(
                        controller: passwordController,
                        hint: "Password",
                        icon: Icons.lock_outline,
                        hide: true,
                      ),

                      const SizedBox(height: 22),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: roleColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _loginUser,
                          child: const Text(
                            "Sign In",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Back to Role Selection",
                          style: TextStyle(color: roleColor),
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
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool hide = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: hide,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: roleColor),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Future<void> _loginUser() async {
    try {
      final user = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = user.user!.uid;

      final roleCollection = widget.role.toLowerCase() + "s";

      final roleDoc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection(roleCollection)
          .doc(uid)
          .get();

      if (!roleDoc.exists) {
        _msg("Not registered in this school");
        return;
      }

      Widget target;

      if (widget.role == "Admin") {
        target = AdminHome(schoolId: widget.schoolId);
      }

      else if (widget.role == "Teacher") {

        if (roleDoc['firstLogin'] == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ChangePasswordScreen(
                schoolId: widget.schoolId,
                userId: uid,
              ),
            ),
          );
          return;
        }

        target = const TeacherHome();
      }

      else {
        target = const ParentHomePage();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => target),
      );

    } catch (e) {
      _msg("Login failed: $e");
    }
  }

  void _msg(String text) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
  }
}
