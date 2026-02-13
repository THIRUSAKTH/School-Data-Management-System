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
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

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
          child: Column(
            children: [
              Icon(roleIcon, size: 70, color: Colors.white),
              const SizedBox(height: 10),
              Text("${widget.role} Login",
                  style: const TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),

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
                        child: const Text("Sign In",
                            style: TextStyle(color: Colors.white)),
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

  Widget _field(TextEditingController c, String hint, {bool hide = false}) {
    return TextField(
      controller: c,
      obscureText: hide,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ================= LOGIN LOGIC =================

  Future<void> _loginUser() async {
    try {
      final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = result.user!.uid;
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

      // -------- ADMIN --------
      if (widget.role == "Admin") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => AdminHome(schoolId: widget.schoolId)),
        );
        return;
      }

      // -------- TEACHER --------
      if (widget.role == "Teacher") {
        if (roleDoc['firstLogin'] == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ChangePasswordScreen(
                schoolId: widget.schoolId,
                userId: uid,
                role: "Teacher",
              ),
            ),
          );
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TeacherHome()),
        );
        return;
      }

      // -------- PARENT --------
      if (widget.role == "Parent") {
        if (roleDoc['firstLogin'] == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ChangePasswordScreen(
                schoolId: widget.schoolId,
                userId: uid,
                role: "Parent",
              ),
            ),
          );
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const ParentHomePage(),
            settings: RouteSettings(arguments: widget.schoolId),
          ),
        );

      }
    } catch (e) {
      _msg(e.toString());
    }
  }

  void _msg(String t) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }
}
