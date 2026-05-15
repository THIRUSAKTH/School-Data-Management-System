import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:schoolprojectjan/app_config.dart';
import 'package:schoolprojectjan/screens/admin/admin_dashboard.dart';
import 'package:schoolprojectjan/screens/authentication_page/change_password_screen.dart';
import 'package:schoolprojectjan/screens/parents/parent_dashboard.dart';
import 'package:schoolprojectjan/screens/parents/select_child_page.dart';
import 'package:schoolprojectjan/screens/teacher/teacher_home.dart';
import 'package:schoolprojectjan/services/fcm_service.dart';

class LoginPage extends StatefulWidget {
  final String role;

  const LoginPage({super.key, required this.role});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool hidePassword = true;
  bool isLoading = false;

  final String defaultAdminEmail = "admin@school.com";
  final String defaultAdminPassword = "Admin@123";

  Color get roleColor {
    switch (widget.role) {
      case "Admin":
        return Colors.deepPurple;
      case "Teacher":
        return Colors.green;
      case "Parent":
        return Colors.orangeAccent;
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
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _fillDefaultAdminCredentials() {
    emailController.text = defaultAdminEmail;
    passwordController.text = defaultAdminPassword;
    _loginUser();
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
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(roleIcon, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 20),
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
                      _buildTextField(
                        emailController,
                        "Email Address",
                        Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        passwordController,
                        "Password",
                        Icons.lock_outline,
                        isPassword: true,
                      ),
                      const SizedBox(height: 10),
                      if (widget.role == "Admin")
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: isLoading ? null : _fillDefaultAdminCredentials,
                            child: const Text("Continue as Demo Admin"),
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: _forgotPassword,
                          child: const Text("Forgot Password?"),
                        ),
                      ),
                      const SizedBox(height: 15),
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
          borderSide: BorderSide(color: roleColor, width: 1),
        ),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            hidePassword ? Icons.visibility_off : Icons.visibility,
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

  Future<void> _forgotPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      _showError("Please enter your email first");
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showSuccess("Password reset link sent to your email");
    } catch (e) {
      _showError("Failed to send reset email");
    }
  }

  // Helper method to create demo admin account if it doesn't exist
  Future<void> _ensureDemoAdminExists(String uid) async {
    final adminDocRef = FirebaseFirestore.instance
        .collection('schools')
        .doc(AppConfig.schoolId)
        .collection('admins')
        .doc(uid);

    final doc = await adminDocRef.get();

    if (!doc.exists) {
      // Create the admin document
      await adminDocRef.set({
        'email': defaultAdminEmail,
        'firstLogin': true,
        'isDemoAccount': true,
        'name': 'Admin User',
        'createdAt': FieldValue.serverTimestamp(),
      });
      print("Demo admin account created successfully");
    }
  }

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
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;
      if (user == null) {
        _showError("Login failed");
        return;
      }

      final uid = user.uid;
      final roleCollection = widget.role.toLowerCase() + "s";
      final roleRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection(roleCollection)
          .doc(uid);

      final roleDoc = await roleRef.get();

      // If admin account doesn't exist in Firestore, create it
      if (!roleDoc.exists && widget.role == "Admin") {
        await _ensureDemoAdminExists(uid);
        // Fetch the document again after creation
        final newRoleDoc = await roleRef.get();
        if (!newRoleDoc.exists) {
          await FirebaseAuth.instance.signOut();
          _showError("Failed to create admin account");
          return;
        }
      } else if (!roleDoc.exists) {
        await FirebaseAuth.instance.signOut();
        _showError("No ${widget.role} account found");
        return;
      }

      // Re-fetch the document data
      final finalRoleDoc = await roleRef.get();
      final data = finalRoleDoc.data()!;

      // Check if firstLogin field exists, default to true if not set
      bool firstLogin = data['firstLogin'] == true;

      // For demo admin account, also check if it's first time using demo
      final bool isDemoAccount = data['isDemoAccount'] == true;

      // Force first login for demo account if firstLogin is not explicitly set to false
      if (isDemoAccount && !data.containsKey('firstLogin')) {
        firstLogin = true;
      }

      // =============================================
      // SAVE USER TO USERS COLLECTION (ALL ROLES)
      // =============================================
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('users')
          .doc(uid)
          .set({
        'email': email,
        'role': widget.role.toLowerCase(),
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // =============================================
      // INITIALIZE FCM FOR ALL ROLES
      // =============================================
      await FCMService.initialize();

      // =============================================
      // ADMIN LOGIN - FORCE PASSWORD CHANGE FOR FIRST LOGIN
      // =============================================
      if (widget.role == "Admin") {
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
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AdminDashboard(schoolId: AppConfig.schoolId),
          ),
        );
        return;
      }

      // =============================================
      // TEACHER LOGIN
      // =============================================
      if (widget.role == "Teacher") {
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
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TeacherHome()),
        );
        return;
      }

      // =============================================
      // PARENT LOGIN
      // =============================================
      if (widget.role == "Parent") {
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

        final childrenSnapshot = await FirebaseFirestore.instance
            .collection('schools')
            .doc(AppConfig.schoolId)
            .collection('students')
            .where('parentUid', isEqualTo: uid)
            .get();

        if (!mounted) return;

        if (childrenSnapshot.docs.length > 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SelectChildPage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ParentDashboard()),
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
      _showError("Something went wrong: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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