import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:schoolprojectjan/screens/authentication_page/login_page.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String schoolId;
  final String userId;
  final String role; // Admin, Teacher, or Parent
  final bool isTemporaryAccount; // True for accounts created via default login

  const ChangePasswordScreen({
    super.key,
    required this.schoolId,
    required this.userId,
    required this.role,
    this.isTemporaryAccount = false,
  });

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final newEmailController = TextEditingController();

  bool loading = false;
  bool hide1 = true;
  bool hide2 = true;
  bool hide3 = true;
  String currentEmail = "";
  bool isUpdatingEmail = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentEmail();
  }

  Future<void> _loadCurrentEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      setState(() {
        currentEmail = user.email!;
        // For temporary accounts, don't pre-fill the email field
        if (!widget.isTemporaryAccount) {
          newEmailController.text = user.email!;
        }
      });
    }
  }

  @override
  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    newEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.role.toLowerCase() == 'admin';
    final isTempAccount = widget.isTemporaryAccount;

    return Scaffold(
      backgroundColor: const Color(0xff8a27e9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_reset,
                  size: 70,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 16),
                Text(
                  isAdmin
                      ? (isTempAccount
                          ? "Setup Your Account"
                          : "Change Password & Email")
                      : "Change Your Password",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isTempAccount
                      ? "Please set your email and password to complete setup"
                      : (isAdmin
                          ? "Update your login credentials"
                          : "Enter old password first"),
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 18),

                // Show special message for temporary accounts
                if (isTempAccount && isAdmin) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "You're setting up a new admin account. "
                            "Please set your email and password below.",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // For temporary accounts, don't ask for old password
                if (!(isTempAccount && isAdmin)) ...[
                  // Old Password Field
                  _passwordField(
                    controller: oldPasswordController,
                    hint: "Old Password",
                    hide: hide1,
                    toggle: () => setState(() => hide1 = !hide1),
                  ),
                  const SizedBox(height: 12),
                ],

                // Email Change Option (Admin only)
                if (isAdmin) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ExpansionTile(
                      title: Text(
                        isTempAccount
                            ? "Set Email Address"
                            : "Change Email Address",
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      leading: const Icon(
                        Icons.email,
                        color: Colors.deepPurple,
                      ),
                      trailing: const Icon(Icons.arrow_drop_down),
                      initiallyExpanded: isTempAccount,
                      // Auto-expand for temp accounts
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              if (currentEmail.isNotEmpty && !isTempAccount)
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.info_outline,
                                        size: 16,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "Current Email: $currentEmail",
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (currentEmail.isNotEmpty && !isTempAccount)
                                const SizedBox(height: 12),
                              TextField(
                                controller: newEmailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText:
                                      isTempAccount
                                          ? "Your Email Address"
                                          : "New Email Address",
                                  hintText: "you@school.com",
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  border: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                  ),
                                  helperText:
                                      isTempAccount
                                          ? "This will be your permanent login email"
                                          : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // New Password Field
                _passwordField(
                  controller: newPasswordController,
                  hint: isTempAccount ? "Set Password" : "New Password",
                  hide: hide2,
                  toggle: () => setState(() => hide2 = !hide2),
                ),
                const SizedBox(height: 12),

                // Confirm Password Field
                _passwordField(
                  controller: confirmPasswordController,
                  hint: "Confirm Password",
                  hide: hide3,
                  toggle: () => setState(() => hide3 = !hide3),
                ),
                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                    ),
                    onPressed: loading ? null : _updateCredentials,
                    child:
                        loading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : Text(
                              isTempAccount
                                  ? "Complete Setup"
                                  : "Update Credentials",
                              style: const TextStyle(color: Colors.white),
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

  Widget _passwordField({
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
        fillColor: Colors.black12,
        suffixIcon: IconButton(
          icon: Icon(hide ? Icons.visibility_off : Icons.visibility),
          onPressed: toggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Future<void> _updateCredentials() async {
    final oldPass = oldPasswordController.text.trim();
    final newPass = newPasswordController.text.trim();
    final confirmPass = confirmPasswordController.text.trim();
    final newEmail = newEmailController.text.trim();
    final isAdmin = widget.role.toLowerCase() == 'admin';
    final isTempAccount = widget.isTemporaryAccount;

    // Validation for temporary accounts
    if (isTempAccount && isAdmin) {
      if (newEmail.isEmpty) {
        _msg("Please enter your email address");
        return;
      }
      if (!_isValidEmail(newEmail)) {
        _msg("Please enter a valid email address");
        return;
      }
      if (newPass.isEmpty) {
        _msg("Please set a password");
        return;
      }
      if (newPass.length < 6) {
        _msg("Password must be at least 6 characters");
        return;
      }
      if (newPass != confirmPass) {
        _msg("Passwords do not match");
        return;
      }
    } else {
      // Normal validation
      if (oldPass.isEmpty) {
        _msg("Please enter old password");
        return;
      }

      if (newPass.isEmpty &&
          (!isAdmin || newEmail.isEmpty || newEmail == currentEmail)) {
        _msg("Please enter new password or new email to update");
        return;
      }

      if (newPass.isNotEmpty) {
        if (newPass.length < 6) {
          _msg("Password must be at least 6 characters");
          return;
        }
        if (newPass != confirmPass) {
          _msg("Passwords do not match");
          return;
        }
      }

      if (isAdmin && newEmail.isNotEmpty && newEmail != currentEmail) {
        if (!_isValidEmail(newEmail)) {
          _msg("Please enter a valid email address");
          return;
        }
      }
    }

    setState(() => loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;

      // For temporary accounts, we need to update email AND password
      if (isTempAccount && isAdmin) {
        setState(() => isUpdatingEmail = true);

        // Update email to real email
        await user.verifyBeforeUpdateEmail(newEmail);

        // Update password
        if (newPass.isNotEmpty) {
          await user.updatePassword(newPass);
        }

        _msg(
          "Verification email sent to $newEmail. Please verify to complete setup.",
        );

        // Update Firestore with real email
        await FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolId)
            .collection('admins')
            .doc(widget.userId)
            .update({
              'email': newEmail,
              'realEmail': newEmail,
              'firstLogin': false,
              'isTemporaryAccount': false,
              'updatedAt': FieldValue.serverTimestamp(),
            });

        // Sign out to force login with new email
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Account setup complete! Please verify your email and login with your new credentials.",
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginPage(role: widget.role)),
          (route) => false,
        );
        return;
      }

      // Normal update flow (non-temporary accounts)
      final email = user.email!;

      // Re-authentication (skip for temp accounts since no old password)
      if (!isTempAccount) {
        final credential = EmailAuthProvider.credential(
          email: email,
          password: oldPass,
        );
        await user.reauthenticateWithCredential(credential);
      }

      // Update email (Admin only)
      if (isAdmin &&
          newEmail.isNotEmpty &&
          newEmail != email &&
          !isTempAccount) {
        await user.verifyBeforeUpdateEmail(newEmail);
        _msg(
          "Verification email sent to $newEmail. Please verify to complete email change.",
        );

        // Store pending email in Firestore
        String collection;
        switch (widget.role.toLowerCase()) {
          case 'teacher':
            collection = 'teachers';
            break;
          case 'parent':
            collection = 'parents';
            break;
          case 'admin':
            collection = 'admins';
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
              'pendingEmail': newEmail,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }

      // Update password if provided
      if (newPass.isNotEmpty) {
        await user.updatePassword(newPass);
        _msg("Password updated successfully!");
      }

      // Update Firestore firstLogin flag
      String collection;
      switch (widget.role.toLowerCase()) {
        case 'teacher':
          collection = 'teachers';
          break;
        case 'parent':
          collection = 'parents';
          break;
        case 'admin':
          collection = 'admins';
          break;
        default:
          collection = 'teachers';
      }

      await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection(collection)
          .doc(widget.userId)
          .update({'firstLogin': false});

      // Sign out the user to force login with new credentials
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Credentials updated! Please login with your new credentials.",
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Navigate to login page
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginPage(role: widget.role)),
        (route) => false,
      );
    } catch (e) {
      String errorMessage = "Error: ${e.toString()}";
      if (e.toString().contains("wrong-password")) {
        errorMessage = "Old password is incorrect";
      } else if (e.toString().contains("weak-password")) {
        errorMessage = "Password is too weak";
      } else if (e.toString().contains("requires-recent-login")) {
        errorMessage = "Please login again before changing credentials";
      } else if (e.toString().contains("email-already-in-use")) {
        errorMessage =
            "This email address is already in use by another account";
      } else if (e.toString().contains("invalid-email")) {
        errorMessage = "Invalid email address format";
      }
      _msg(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
          isUpdatingEmail = false;
        });
      }
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}
