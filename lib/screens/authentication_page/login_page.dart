import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:schoolprojectjan/app_config.dart'; // ✅ IMPORTANT
import 'package:schoolprojectjan/screens/admin/admin_home.dart';
import 'package:schoolprojectjan/screens/admin/welcome_screen.dart';
import 'package:schoolprojectjan/screens/parents/parent_dashboard.dart';
import 'package:schoolprojectjan/screens/teacher/teacher_home.dart';
import 'package:schoolprojectjan/screens/authentication_page/change_password_screen.dart';

class LoginPage extends StatefulWidget {
  final String role;

  const LoginPage({
    super.key,
    required this.role,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool hidePassword = true;

  /// ROLE COLOR
  Color get roleColor {
    switch (widget.role) {
      case "Admin":
        return Colors.cyan;
      case "Teacher":
        return Colors.green;
      case "Parent":
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  /// ROLE ICON
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
          child: Column(
            children: [

              Icon(roleIcon, size: 70, color: Colors.white),

              const SizedBox(height: 10),

              Text(
                "${widget.role} Login",
                style: const TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [

                    _field(emailController, "Email"),

                    const SizedBox(height: 15),

                    _field(passwordController, "Password", hide: true),

                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: roleColor,
                        ),
                        onPressed: _loginUser,
                        child: const Text(
                          "Sign In",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),

                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  /// ================= INPUT FIELD =================

  Widget _field(TextEditingController c, String hint, {bool hide = false}) {
    return TextField(
      controller: c,
      obscureText: hide ? hidePassword : false,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        suffixIcon: hide
            ? IconButton(
          icon: Icon(
            hidePassword
                ? Icons.visibility_off
                : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              hidePassword = !hidePassword;
            });
          },
        )
            : null,
      ),
    );
  }

  /// ================= LOGIN FUNCTION =================

  Future<void> _loginUser() async {

    try {

      final result = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = result.user!.uid;

      final roleCollection = widget.role.toLowerCase() + "s";

      final roleDoc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId) // ✅ FIXED
          .collection(roleCollection)
          .doc(uid)
          .get();

      if (!roleDoc.exists) {
        _msg("Not registered in this school");
        return;
      }

      /// ---------- ADMIN ----------
      if (widget.role == "Admin") {

        final schoolDoc = await FirebaseFirestore.instance
            .collection('schools')
            .doc(AppConfig.schoolId)
            .get();

        String schoolName = schoolDoc['schoolName'] ?? "School";
        String logoUrl = schoolDoc['logoUrl'] ?? "";

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => WelcomeScreen(
              schoolId: AppConfig.schoolId,
              schoolName: schoolName,
              logoUrl: logoUrl,
            ),
          ),
        );

        return;
      }

      /// ---------- TEACHER ----------
      if (widget.role == "Teacher") {

        if (roleDoc['firstLogin'] == true) {

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ChangePasswordScreen(
                schoolId: AppConfig.schoolId,
                userId: uid,
                role: "Teacher",
              ),
            ),
          );

          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TeacherHome(
              schoolId: AppConfig.schoolId,
            ),
          ),
        );

        return;
      }

      /// ---------- PARENT ----------
      if (widget.role == "Parent") {

        if (roleDoc['firstLogin'] == true) {

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ChangePasswordScreen(
                schoolId: AppConfig.schoolId,
                userId: uid,
                role: "Parent",
              ),
            ),
          );

          return;
        }

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const ParentDashboard(), // ✅ FIXED
          ),
        );
      }

    } catch (e) {
      _msg("Login failed: ${e.toString()}");
    }
  }

  /// ================= SNACKBAR =================

  void _msg(String t) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(t)));
  }
}