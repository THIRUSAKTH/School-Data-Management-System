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

  // Default admin credentials (only for Admin role)
  final String defaultAdminEmail = "admin@school.com";
  final String defaultAdminPassword = "Admin@123";

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

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

  // Ensure default admin account exists (only for Admin)
  Future<void> _ensureDefaultAdminExists() async {
    if (widget.role != "Admin") return;

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: defaultAdminEmail,
        password: defaultAdminPassword,
      );

      print("📝 Default admin account created successfully");

      final user = FirebaseAuth.instance.currentUser!;

      await FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection('admins')
          .doc(user.uid)
          .set({
        'email': defaultAdminEmail,
        'firstLogin': true,
        'name': 'School Admin',
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
      });

    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        print("✅ Default admin already exists");
      }
    }
  }

  void _fillDefaultCredentials() {
    setState(() {
      emailController.text = defaultAdminEmail;
      passwordController.text = defaultAdminPassword;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Default credentials filled. Click Sign In."),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _ensureDefaultAdminExists();
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
                      ? "Enter your credentials or use default admin account"
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
                      // Default Credentials Info Card - ONLY FOR ADMIN
                      if (widget.role == "Admin")
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.deepPurple.shade200),
                          ),
                          child: Column(
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.info_outline, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    "Default Admin Credentials",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.email, size: 16, color: Colors.deepPurple),
                                        const SizedBox(width: 8),
                                        const Text("Email:", style: TextStyle(fontWeight: FontWeight.w500)),
                                        const SizedBox(width: 8),
                                        Text(
                                          defaultAdminEmail,
                                          style: const TextStyle(
                                            color: Colors.deepPurple,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.lock, size: 16, color: Colors.deepPurple),
                                        const SizedBox(width: 8),
                                        const Text("Password:", style: TextStyle(fontWeight: FontWeight.w500)),
                                        const SizedBox(width: 8),
                                        Text(
                                          defaultAdminPassword,
                                          style: const TextStyle(
                                            color: Colors.deepPurple,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

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

                      // Fill Default Credentials Button - ONLY FOR ADMIN
                      if (widget.role == "Admin")
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: isLoading ? null : _fillDefaultCredentials,
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text("Use Default Credentials"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.deepPurple,
                              side: const BorderSide(color: Colors.deepPurple),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 8),

                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: _forgotPassword,
                          child: const Text("Forgot Password?"),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Sign In Button
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

      if (!roleDoc.exists) {
        await FirebaseAuth.instance.signOut();
        _showError("No ${widget.role} account found. Please contact admin.");
        return;
      }

      final data = roleDoc.data()!;
      bool firstLogin = data['firstLogin'] == true;

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

      await FCMService.initialize();

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