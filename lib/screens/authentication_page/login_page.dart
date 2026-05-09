import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:schoolprojectjan/app_config.dart';
import 'package:schoolprojectjan/screens/admin/admin_dashboard.dart';
import 'package:schoolprojectjan/screens/authentication_page/change_password_screen.dart';
import 'package:schoolprojectjan/screens/parents/parent_dashboard.dart';
import 'package:schoolprojectjan/screens/parents/select_child_page.dart';
import 'package:schoolprojectjan/screens/teacher/teacher_home.dart';

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
  bool isLoading = false;

  /// DEMO ADMIN
  final String defaultAdminEmail = "admin@school.com";
  final String defaultAdminPassword = "Admin@123";

  /// ROLE COLOR
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
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// ================= DEMO ADMIN FILL =================
  void _fillDefaultAdminCredentials() {
    emailController.text = defaultAdminEmail;
    passwordController.text = defaultAdminPassword;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: roleColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                /// ROLE ICON
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    roleIcon,
                    size: 50,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 20),

                /// TITLE
                Text(
                  "${widget.role} Login",
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  widget.role == "Admin"
                      ? "Continue as Demo Admin or login with your credentials"
                      : "Login with credentials provided by admin",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.85),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),

                /// LOGIN CARD
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [

                      /// EMAIL
                      _buildTextField(
                        emailController,
                        "Email Address",
                        Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 16),

                      /// PASSWORD
                      _buildTextField(
                        passwordController,
                        "Password",
                        Icons.lock_outline,
                        isPassword: true,
                      ),

                      const SizedBox(height: 10),

                      /// DEMO BUTTON
                      if (widget.role == "Admin")
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: _fillDefaultAdminCredentials,
                            child: const Text(
                              "Continue as Demo Admin",
                            ),
                          ),
                        ),

                      /// FORGOT PASSWORD
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: _forgotPassword,
                          child: const Text("Forgot Password?"),
                        ),
                      ),

                      const SizedBox(height: 15),

                      /// LOGIN BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: roleColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: isLoading ? null : _loginUser,
                          child: isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Text(
                            "Sign In",
                            style: TextStyle(
                              fontSize: 16,
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
    );
  }

  /// ================= TEXT FIELD =================
  Widget _buildTextField(
      TextEditingController controller,
      String hint,
      IconData icon, {
        bool isPassword = false,
        TextInputType keyboardType = TextInputType.text,
      }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? hidePassword : false,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: roleColor),
        filled: true,
        fillColor: Colors.grey.shade50,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: roleColor,
            width: 1,
          ),
        ),

        suffixIcon: isPassword
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

  /// ================= FORGOT PASSWORD =================
  Future<void> _forgotPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _showError("Please enter your email first");
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      _showSuccess(
        "Password reset link sent to your email",
      );

    } catch (e) {

      _showError("Failed to send reset email");
    }
  }

  /// ================= LOGIN FUNCTION =================
  Future<void> _loginUser() async {

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty) {
      _showError("Please enter email");
      return;
    }

    if (password.isEmpty) {
      _showError("Please enter password");
      return;
    }

    setState(() => isLoading = true);

    try {

      /// ================= FIREBASE AUTH =================
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      if (user == null) {
        _showError("Login failed");
        return;
      }

      final uid = user.uid;

      /// ================= COLLECTION =================
      final roleCollection =
          widget.role.toLowerCase() + "s";

      final roleRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection(roleCollection)
          .doc(uid);

      final roleDoc = await roleRef.get();

      /// ================= DOCUMENT CHECK =================
      if (!roleDoc.exists) {

        await FirebaseAuth.instance.signOut();

        _showError(
          "No ${widget.role} account found",
        );

        return;
      }

      final data = roleDoc.data()!;

      final bool firstLogin =
          data['firstLogin'] == true;

      final bool isDemoAccount =
          data['isDemoAccount'] == true;

      /// =================================================
      /// ================= ADMIN =========================
      /// =================================================
      if (widget.role == "Admin") {

        /// DEMO ADMIN
        if (isDemoAccount) {

          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => AdminDashboard(
                schoolId: AppConfig.schoolId,
              ),
            ),
          );

          return;
        }

        /// REAL ADMIN FIRST LOGIN
        if (firstLogin) {

          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ChangePasswordScreen(
                schoolId: AppConfig.schoolId,
                userId: uid,
                role: "Admin",
              ),
            ),
          );

          return;
        }

        /// NORMAL ADMIN
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AdminDashboard(
              schoolId: AppConfig.schoolId,
            ),
          ),
        );

        return;
      }

      /// =================================================
      /// ================= TEACHER =======================
      /// =================================================
      if (widget.role == "Teacher") {

        /// FIRST LOGIN
        if (firstLogin) {

          if (!mounted) return;

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

        /// NORMAL LOGIN
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const TeacherHome(),
          ),
        );

        return;
      }

      /// =================================================
      /// ================= PARENT ========================
      /// =================================================
      if (widget.role == "Parent") {

        /// FIRST LOGIN
        if (firstLogin) {

          if (!mounted) return;

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

        /// CHECK CHILD COUNT
        final childrenSnapshot =
        await FirebaseFirestore.instance
            .collection('schools')
            .doc(AppConfig.schoolId)
            .collection('students')
            .where('parentUid', isEqualTo: uid)
            .get();

        if (!mounted) return;

        if (childrenSnapshot.docs.length > 1) {

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const SelectChildPage(),
            ),
          );

        } else {

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const ParentDashboard(),
            ),
          );
        }

        return;
      }

    } on FirebaseAuthException catch (e) {

      String message;

      switch (e.code) {

        case 'user-not-found':
          message = "No user found with this email";
          break;

        case 'wrong-password':
          message = "Incorrect password";
          break;

        case 'invalid-email':
          message = "Invalid email address";
          break;

        case 'user-disabled':
          message = "This account has been disabled";
          break;

        case 'network-request-failed':
          message = "Please check internet connection";
          break;

        default:
          message = e.message ?? "Login failed";
      }

      _showError(message);

    } catch (e) {

      _showError(
        "Something went wrong",
      );

    } finally {

      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  /// ================= ERROR =================
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// ================= SUCCESS =================
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}