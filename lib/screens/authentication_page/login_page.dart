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

  const LoginPage({super.key, required this.role});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool hidePassword = true;
  bool isLoading = false;

  /// Default Admin Credentials - These ALWAYS work for ANY new admin
  /// IMPORTANT: Never delete or modify this account in Firebase Auth
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
                // Role Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(roleIcon, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 20),

                // Role Title
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
                      ? "Use default credentials for first login\n(Works for every new school admin)"
                      : "Login with credentials provided by admin",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // Login Form Card
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
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        // Email Field
                        _buildTextField(
                          emailController,
                          "Email Address",
                          Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        _buildTextField(
                          passwordController,
                          "Password",
                          Icons.lock_outline,
                          isPassword: true,
                        ),
                        const SizedBox(height: 10),

                        // Buttons
                        if (widget.role == "Admin")
                          Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: TextButton(
                                  onPressed: _fillDefaultAdminCredentials,
                                  style: TextButton.styleFrom(
                                    foregroundColor: roleColor,
                                  ),
                                  child: const Text(
                                    "Use Default Admin Credentials",
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  if (emailController.text.trim().isEmpty) {
                                    _showError(
                                      "Please enter your email address first",
                                    );
                                    return;
                                  }
                                  try {
                                    await FirebaseAuth.instance
                                        .sendPasswordResetEmail(
                                          email: emailController.text.trim(),
                                        );
                                    _showSuccess(
                                      "Password reset link sent to your email",
                                    );
                                  } catch (e) {
                                    _showError("Something went wrong");
                                  }
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: roleColor,
                                ),
                                child: const Text("Forgot Password?"),
                              ),
                            ],
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () async {
                                if (emailController.text.trim().isEmpty) {
                                  _showError(
                                    "Please enter your email address first",
                                  );
                                  return;
                                }
                                try {
                                  await FirebaseAuth.instance
                                      .sendPasswordResetEmail(
                                        email: emailController.text.trim(),
                                      );
                                  _showSuccess(
                                    "Password reset link sent to your email",
                                  );
                                } catch (e) {
                                  _showError("Something went wrong");
                                }
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: roleColor,
                              ),
                              child: const Text("Forgot Password?"),
                            ),
                          ),
                        const SizedBox(height: 15),

                        // Login Button
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
                              elevation: 2,
                            ),
                            onPressed: isLoading ? null : _loginUser,
                            child:
                                isLoading
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ================= INPUT FIELD =================
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
      style: const TextStyle(fontSize: 16),
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
        suffixIcon:
            isPassword
                ? IconButton(
                  icon: Icon(
                    hidePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
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
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty) {
      _showError("Please enter email address");
      return;
    }

    if (password.isEmpty) {
      _showError("Please enter password");
      return;
    }

    setState(() => isLoading = true);

    try {
      UserCredential? userCredential;

      // Check if this is a default admin login attempt
      final isDefaultAdminLogin =
          (widget.role == "Admin" &&
              email == defaultAdminEmail &&
              password == defaultAdminPassword);

      if (isDefaultAdminLogin) {
        // SPECIAL HANDLING FOR DEFAULT ADMIN LOGIN
        // We ALWAYS create a NEW user account for each school that uses default credentials
        // NEVER reuse or modify the existing default account

        final String schoolId = AppConfig.schoolId;

        // Check if this specific school already has an admin registered
        final adminCheck =
            await FirebaseFirestore.instance
                .collection('schools')
                .doc(schoolId)
                .collection('admins')
                .where('schoolRegistered', isEqualTo: true)
                .limit(1)
                .get();

        if (adminCheck.docs.isNotEmpty) {
          // This school already has an admin registered
          _showError(
            "❌ This school already has an admin registered.\n\n"
            "Please use your custom email/password to login.\n\n"
            "If you forgot your credentials, contact your school administrator.",
          );
          setState(() => isLoading = false);
          return;
        }

        // Create a TEMPORARY unique user account for this school
        // This temp account will be converted to the real admin account
        final tempEmail =
            "temp_${DateTime.now().millisecondsSinceEpoch}_$schoolId@school.local";

        try {
          // Create a new Firebase Auth user with temporary email
          userCredential = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
                email: tempEmail,
                password: defaultAdminPassword,
              );

          // Store the temporary account info in Firestore
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(schoolId)
              .collection('admins')
              .doc(userCredential.user!.uid)
              .set({
                'tempEmail': tempEmail,
                'realEmail': null, // Will be set when user changes email
                'role': 'Admin',
                'firstLogin': true,
                'isTemporaryAccount': true,
                'schoolRegistered': true,
                'createdAt': FieldValue.serverTimestamp(),
                'createdUsingDefault': true,
              });
        } catch (e) {
          if (e.toString().contains('email-already-in-use')) {
            _showError("System error. Please try again or contact support.");
          } else {
            rethrow;
          }
        }
      } else {
        // NORMAL LOGIN FLOW for existing users (non-default credentials)
        try {
          userCredential = await FirebaseAuth.instance
              .signInWithEmailAndPassword(email: email, password: password);
        } on FirebaseAuthException catch (e) {
          // If user doesn't exist and it's an admin trying to create account normally
          if (e.code == 'user-not-found' && widget.role == "Admin") {
            userCredential = await FirebaseAuth.instance
                .createUserWithEmailAndPassword(
                  email: email,
                  password: password,
                );
          } else {
            rethrow;
          }
        }
      }

      final uid = userCredential!.user!.uid;
      final roleCollection = widget.role.toLowerCase() + "s";

      final roleRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(AppConfig.schoolId)
          .collection(roleCollection)
          .doc(uid);

      final roleDoc = await roleRef.get();

      // ---------- ADMIN ----------
      if (widget.role == "Admin") {
        final docData = roleDoc.data();
        final bool isFirstLogin =
            !roleDoc.exists || docData?['firstLogin'] == true;
        final bool isTemporaryAccount = docData?['isTemporaryAccount'] == true;

        if (!roleDoc.exists) {
          // For normal admin creation (non-default)
          await roleRef.set({
            "email": email,
            "role": "Admin",
            "firstLogin": true,
            "createdAt": FieldValue.serverTimestamp(),
          });
        }

        if (isFirstLogin || isTemporaryAccount) {
          if (!mounted) return;
          // Send to change password screen with special flags
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (_) => ChangePasswordScreen(
                    schoolId: AppConfig.schoolId,
                    userId: uid,
                    role: "Admin",
                    isTemporaryAccount: isTemporaryAccount, // Pass this flag
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

      // ---------- TEACHER ----------
      if (widget.role == "Teacher") {
        if (!roleDoc.exists) {
          _showError(
            "Your account has not been created by admin yet. Please contact school admin.",
          );
          setState(() => isLoading = false);
          return;
        }

        final data = roleDoc.data();
        final bool firstLogin = data?['firstLogin'] == true;

        if (firstLogin) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (_) => ChangePasswordScreen(
                    schoolId: AppConfig.schoolId,
                    userId: uid,
                    role: "Teacher",
                    isTemporaryAccount: false,
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

      // ---------- PARENT ----------
      if (widget.role == "Parent") {
        if (!roleDoc.exists) {
          _showError(
            "Your account has not been created by admin yet. Please contact school admin.",
          );
          setState(() => isLoading = false);
          return;
        }

        final data = roleDoc.data();
        final bool firstLogin = data?['firstLogin'] == true;

        if (firstLogin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (_) => ChangePasswordScreen(
                    schoolId: AppConfig.schoolId,
                    userId: uid,
                    role: "Parent",
                    isTemporaryAccount: false,
                  ),
            ),
          );
        } else {
          final childrenSnapshot =
              await FirebaseFirestore.instance
                  .collection('schools')
                  .doc(AppConfig.schoolId)
                  .collection('students')
                  .where('parentUid', isEqualTo: uid)
                  .get();

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
        case 'email-already-in-use':
          message = "Email already in use";
          break;
        default:
          message = "Login failed: ${e.message}";
      }
      _showError(message);
    } catch (e) {
      _showError("Login failed: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  /// ================= SHOW ERROR =================
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// ================= SHOW SUCCESS =================
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
