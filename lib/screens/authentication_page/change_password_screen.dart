import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:schoolprojectjan/screens/authentication_page/login_page.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String schoolId;
  final String userId;
  final String role;

  const ChangePasswordScreen({
    super.key,
    required this.schoolId,
    required this.userId,
    required this.role,
  });

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final emailController = TextEditingController();
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool loading = false;
  bool isDemoAccount = false; // Track if this is the demo account

  bool hideOld = true;
  bool hideNew = true;
  bool hideConfirm = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentEmail();
    _checkIfDemoAccount();
  }

  Future<void> _checkIfDemoAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email == "demo@school.com") {
        setState(() {
          isDemoAccount = true;
        });
      }
    } catch (e) {
      print('Error checking demo account: $e');
    }
  }

  Future<void> _loadCurrentEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        emailController.text = user.email!;
      }
    } catch (e) {
      print('Error loading email: $e');
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff8a27e9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// ICON
                const Icon(
                  Icons.lock_reset,
                  size: 70,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 18),

                /// TITLE
                const Text(
                  "Change Password",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  isDemoAccount
                      ? "⚠️ Demo Account - Cannot be modified"
                      : (widget.role == "Admin"
                      ? "Update your admin email and password"
                      : "Please change your temporary email and password"),
                  style: TextStyle(
                    color: isDemoAccount ? Colors.red : Colors.black54,
                    fontWeight: isDemoAccount ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),

                /// DEMO ACCOUNT WARNING
                if (isDemoAccount)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Demo account cannot be modified. Please sign out and create your own admin account.",
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                /// =============================================
                /// EMAIL FIELD - Disabled for demo account
                /// =============================================
                _buildEmailField(),
                const SizedBox(height: 14),

                /// OLD PASSWORD - Disabled for demo account
                _buildPasswordField(
                  controller: oldPasswordController,
                  hint: "Old Password",
                  hide: hideOld,
                  enabled: !isDemoAccount,
                  toggle: () {
                    setState(() {
                      hideOld = !hideOld;
                    });
                  },
                ),
                const SizedBox(height: 14),

                /// NEW PASSWORD - Disabled for demo account
                _buildPasswordField(
                  controller: newPasswordController,
                  hint: "New Password",
                  hide: hideNew,
                  enabled: !isDemoAccount,
                  toggle: () {
                    setState(() {
                      hideNew = !hideNew;
                    });
                  },
                ),
                const SizedBox(height: 14),

                /// CONFIRM PASSWORD - Disabled for demo account
                _buildPasswordField(
                  controller: confirmPasswordController,
                  hint: "Confirm Password",
                  hide: hideConfirm,
                  enabled: !isDemoAccount,
                  toggle: () {
                    setState(() {
                      hideConfirm = !hideConfirm;
                    });
                  },
                ),
                const SizedBox(height: 20),

                /// PASSWORD STRENGTH
                if (newPasswordController.text.isNotEmpty && !isDemoAccount)
                  _buildPasswordStrength(newPasswordController.text),
                const SizedBox(height: 25),

                /// BUTTON - Disabled for demo account
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDemoAccount ? Colors.grey : Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: (loading || isDemoAccount) ? null : _changePassword,
                    child: loading
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Text(
                      isDemoAccount ? "Demo Account Protected" : "Update Password",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                /// Sign out button for demo account
                if (isDemoAccount)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: TextButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LoginPage(role: widget.role),
                            ),
                                (route) => false,
                          );
                        }
                      },
                      child: const Text(
                        "Sign Out",
                        style: TextStyle(color: Colors.deepPurple),
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

  /// ================= EMAIL FIELD =================
  Widget _buildEmailField() {
    return TextField(
      controller: emailController,
      keyboardType: TextInputType.emailAddress,
      enabled: !isDemoAccount, // Disable for demo account
      decoration: InputDecoration(
        hintText: "Email Address",
        labelText: "Email Address",
        prefixIcon: const Icon(Icons.email_outlined, color: Colors.deepPurple),
        filled: true,
        fillColor: isDemoAccount ? Colors.grey.shade200 : Colors.grey.shade100,
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
          borderSide: const BorderSide(
            color: Colors.deepPurple,
          ),
        ),
      ),
    );
  }

  /// ================= PASSWORD FIELD =================
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool hide,
    required VoidCallback toggle,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      obscureText: hide,
      enabled: enabled,
      decoration: InputDecoration(
        hintText: hint,
        labelText: hint,
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.deepPurple),
        filled: true,
        fillColor: enabled ? Colors.grey.shade100 : Colors.grey.shade200,
        suffixIcon: enabled
            ? IconButton(
          icon: Icon(
            hide ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: toggle,
        )
            : null,
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
          borderSide: const BorderSide(
            color: Colors.deepPurple,
          ),
        ),
      ),
    );
  }

  /// ================= PASSWORD STRENGTH =================
  Widget _buildPasswordStrength(String password) {
    int strength = _passwordStrength(password);
    String text = "";
    Color color = Colors.red;

    if (strength <= 2) {
      text = "Weak";
      color = Colors.red;
    } else if (strength <= 4) {
      text = "Medium";
      color = Colors.orange;
    } else {
      text = "Strong";
      color = Colors.green;
    }

    return Column(
      children: [
        LinearProgressIndicator(
          value: strength / 6,
          minHeight: 5,
          color: color,
          backgroundColor: Colors.grey.shade300,
        ),
        const SizedBox(height: 5),
        Text(
          "Password Strength: $text",
          style: TextStyle(
            color: color,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  int _passwordStrength(String password) {
    int strength = 0;
    if (password.length >= 6) strength++;
    if (password.length >= 8) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      strength++;
    }
    return strength;
  }

  /// ================= CHANGE PASSWORD & EMAIL =================
  Future<void> _changePassword() async {
    final email = emailController.text.trim();
    final oldPass = oldPasswordController.text.trim();
    final newPass = newPasswordController.text.trim();
    final confirmPass = confirmPasswordController.text.trim();

    /// PROTECT DEMO ACCOUNT - Extra safety check
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.email == "demo@school.com") {
      _showMessage(
        "⚠️ Demo account cannot be modified.\n\n"
            "Please sign out and create your own admin account.",
        isError: true,
      );
      return;
    }

    /// VALIDATION
    if (email.isEmpty) {
      _showMessage("Please enter email address", isError: true);
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      _showMessage("Please enter a valid email address", isError: true);
      return;
    }

    if (oldPass.isEmpty) {
      _showMessage("Please enter old password", isError: true);
      return;
    }

    if (newPass.isEmpty) {
      _showMessage("Please enter new password", isError: true);
      return;
    }

    if (newPass.length < 6) {
      _showMessage("Password must be at least 6 characters", isError: true);
      return;
    }

    if (newPass != confirmPass) {
      _showMessage("Passwords do not match", isError: true);
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        _showMessage("User not found", isError: true);
        return;
      }

      // =============================================
      // STEP 1: Update email if changed
      // =============================================
      if (user.email != email) {
        await user.verifyBeforeUpdateEmail(email);
        _showMessage(
          "Verification email sent to $email.\nPlease verify and login again.",
          isError: false,
        );
        await FirebaseAuth.instance.signOut();

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => LoginPage(role: widget.role),
            ),
                (route) => false,
          );
        }
        return;
      }

      // =============================================
      // STEP 2: Re-authenticate user before password change
      // =============================================
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPass,
      );

      await user.reauthenticateWithCredential(credential);

      // =============================================
      // STEP 3: Update password
      // =============================================
      await user.updatePassword(newPass);

      // =============================================
      // STEP 4: Update Firestore
      // =============================================
      String collection;
      switch (widget.role.toLowerCase()) {
        case 'admin':
          collection = 'admins';
          break;
        case 'teacher':
          collection = 'teachers';
          break;
        case 'parent':
          collection = 'parents';
          break;
        default:
          collection = 'teachers';
      }

      await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection(collection)
          .doc(widget.userId)
          .update({
        'firstLogin': false,
        'email': email,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update users collection as well
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('users')
          .doc(widget.userId)
          .update({'email': email});

      // =============================================
      // STEP 5: Sign out and redirect to login
      // =============================================
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      _showMessage(
        "Password updated successfully.\nPlease login again.",
        isError: false,
      );

      Future.delayed(
        const Duration(seconds: 2),
            () {
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => LoginPage(role: widget.role),
            ),
                (route) => false,
          );
        },
      );
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'wrong-password':
          message = "Old password is incorrect";
          break;
        case 'weak-password':
          message = "Password is too weak";
          break;
        case 'requires-recent-login':
          message = "Please login again and retry";
          break;
        case 'network-request-failed':
          message = "Please check internet connection";
          break;
        case 'email-already-in-use':
          message = "This email is already in use by another account";
          break;
        case 'invalid-email':
          message = "Please enter a valid email address";
          break;
        default:
          message = e.message ?? "Password update failed";
      }
      _showMessage(message, isError: true);
    } catch (e) {
      _showMessage("Something went wrong: $e", isError: true);
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }
  /// ================= SNACKBAR =================
  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 3 : 2),
      ),
    );
  }
}