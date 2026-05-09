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
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends State<ChangePasswordScreen> {

  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool loading = false;

  bool hideOld = true;
  bool hideNew = true;
  bool hideConfirm = true;

  @override
  void dispose() {
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
                  widget.role == "Admin"
                      ? "Update your admin password"
                      : "Please change your temporary password",
                  style: const TextStyle(
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 25),

                /// OLD PASSWORD
                _buildPasswordField(
                  controller: oldPasswordController,
                  hint: "Old Password",
                  hide: hideOld,
                  toggle: () {
                    setState(() {
                      hideOld = !hideOld;
                    });
                  },
                ),

                const SizedBox(height: 14),

                /// NEW PASSWORD
                _buildPasswordField(
                  controller: newPasswordController,
                  hint: "New Password",
                  hide: hideNew,
                  toggle: () {
                    setState(() {
                      hideNew = !hideNew;
                    });
                  },
                ),

                const SizedBox(height: 14),

                /// CONFIRM PASSWORD
                _buildPasswordField(
                  controller: confirmPasswordController,
                  hint: "Confirm Password",
                  hide: hideConfirm,
                  toggle: () {
                    setState(() {
                      hideConfirm = !hideConfirm;
                    });
                  },
                ),

                const SizedBox(height: 20),

                /// PASSWORD STRENGTH
                if (newPasswordController.text.isNotEmpty)
                  _buildPasswordStrength(
                    newPasswordController.text,
                  ),

                const SizedBox(height: 25),

                /// BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 50,

                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(12),
                      ),
                    ),

                    onPressed:
                    loading ? null : _changePassword,

                    child: loading
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child:
                      CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text(
                      "Update Password",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight:
                        FontWeight.bold,
                      ),
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

  /// ================= PASSWORD FIELD =================
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool hide,
    required VoidCallback toggle,
  }) {

    return TextField(
      controller: controller,
      obscureText: hide,

      decoration: InputDecoration(
        hintText: hint,

        filled: true,
        fillColor: Colors.grey.shade100,

        suffixIcon: IconButton(
          icon: Icon(
            hide
                ? Icons.visibility_off
                : Icons.visibility,
          ),
          onPressed: toggle,
        ),

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
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]')
        .hasMatch(password)) {
      strength++;
    }

    return strength;
  }

  /// ================= CHANGE PASSWORD =================
  Future<void> _changePassword() async {

    final oldPass =
    oldPasswordController.text.trim();

    final newPass =
    newPasswordController.text.trim();

    final confirmPass =
    confirmPasswordController.text.trim();

    /// VALIDATION
    if (oldPass.isEmpty) {
      _showMessage(
        "Please enter old password",
        isError: true,
      );
      return;
    }

    if (newPass.isEmpty) {
      _showMessage(
        "Please enter new password",
        isError: true,
      );
      return;
    }

    if (newPass.length < 6) {
      _showMessage(
        "Password must be at least 6 characters",
        isError: true,
      );
      return;
    }

    if (newPass != confirmPass) {
      _showMessage(
        "Passwords do not match",
        isError: true,
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {

      final user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        _showMessage(
          "User not found",
          isError: true,
        );
        return;
      }

      /// REAUTHENTICATE
      final credential =
      EmailAuthProvider.credential(
        email: user.email!,
        password: oldPass,
      );

      await user.reauthenticateWithCredential(
        credential,
      );

      /// UPDATE PASSWORD
      await user.updatePassword(newPass);

      /// COLLECTION NAME
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

      /// UPDATE FIRESTORE
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection(collection)
          .doc(widget.userId)
          .update({

        'firstLogin': false,
        'updatedAt':
        FieldValue.serverTimestamp(),

      });

      /// SIGN OUT
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
              builder: (_) =>
                  LoginPage(role: widget.role),
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
          message =
          "Please login again and retry";
          break;

        case 'network-request-failed':
          message =
          "Please check internet connection";
          break;

        default:
          message =
              e.message ?? "Password update failed";
      }

      _showMessage(
        message,
        isError: true,
      );

    } catch (e) {

      _showMessage(
        "Something went wrong",
        isError: true,
      );

    } finally {

      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  /// ================= SNACKBAR =================
  void _showMessage(
      String message, {
        required bool isError,
      }) {

    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(
        content: Text(message),

        backgroundColor:
        isError
            ? Colors.red
            : Colors.green,

        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }
}