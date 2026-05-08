import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:schoolprojectjan/screens/authentication_page/login_page.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String schoolId;
  final String userId;
  final String role;
  final bool isTemporaryAccount;

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
                          ? "Setup Your Admin Account"
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
                            "Please set your email and password below. "
                            "You'll be logged out and need to login with your new credentials.",
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

                if (!(isTempAccount && isAdmin)) ...[
                  _buildPasswordField(
                    controller: oldPasswordController,
                    hint: "Old Password",
                    hide: hide1,
                    toggle: () => setState(() => hide1 = !hide1),
                  ),
                  const SizedBox(height: 12),
                ],

                if (isAdmin) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.email, color: Colors.deepPurple),
                              const SizedBox(width: 8),
                              Text(
                                isTempAccount
                                    ? "Email Address"
                                    : "Change Email",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (currentEmail.isNotEmpty && !isTempAccount) ...[
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
                            const SizedBox(height: 12),
                          ],
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
                              errorText: _getEmailError(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                _buildPasswordField(
                  controller: newPasswordController,
                  hint: isTempAccount ? "Set Password" : "New Password",
                  hide: hide2,
                  toggle: () => setState(() => hide2 = !hide2),
                ),
                const SizedBox(height: 12),

                _buildPasswordField(
                  controller: confirmPasswordController,
                  hint: "Confirm Password",
                  hide: hide3,
                  toggle: () => setState(() => hide3 = !hide3),
                ),
                const SizedBox(height: 22),

                if (isTempAccount && newPasswordController.text.isNotEmpty)
                  _buildPasswordStrengthIndicator(newPasswordController.text),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: loading ? null : _updateCredentials,
                    child:
                        loading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Text(
                              isTempAccount
                                  ? "Complete Setup"
                                  : "Update Credentials",
                              style: const TextStyle(
                                color: Colors.white,
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
      ),
    );
  }

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
          icon: Icon(hide ? Icons.visibility_off : Icons.visibility),
          onPressed: toggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 1),
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator(String password) {
    int strength = _getPasswordStrength(password);
    String strengthText = "";
    Color strengthColor = Colors.red;

    if (strength <= 2) {
      strengthText = "Weak";
      strengthColor = Colors.red;
    } else if (strength <= 4) {
      strengthText = "Medium";
      strengthColor = Colors.orange;
    } else {
      strengthText = "Strong";
      strengthColor = Colors.green;
    }

    return Column(
      children: [
        LinearProgressIndicator(
          value: strength / 6,
          backgroundColor: Colors.grey.shade200,
          color: strengthColor,
          minHeight: 4,
        ),
        const SizedBox(height: 4),
        Text(
          "Password strength: $strengthText",
          style: TextStyle(fontSize: 12, color: strengthColor),
        ),
      ],
    );
  }

  int _getPasswordStrength(String password) {
    int strength = 0;
    if (password.length >= 6) strength++;
    if (password.length >= 8) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;
    return strength;
  }

  String? _getEmailError() {
    final email = newEmailController.text.trim();
    if (email.isNotEmpty && !_isValidEmail(email)) {
      return "Please enter a valid email address";
    }
    return null;
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
        _showMessage("Please enter your email address", isError: true);
        return;
      }
      if (!_isValidEmail(newEmail)) {
        _showMessage("Please enter a valid email address", isError: true);
        return;
      }
      if (newPass.isEmpty) {
        _showMessage("Please set a password", isError: true);
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
    } else {
      // Normal validation
      if (oldPass.isEmpty) {
        _showMessage("Please enter old password", isError: true);
        return;
      }

      if (newPass.isEmpty &&
          (!isAdmin || newEmail.isEmpty || newEmail == currentEmail)) {
        _showMessage(
          "Please enter new password or new email to update",
          isError: true,
        );
        return;
      }

      if (newPass.isNotEmpty) {
        if (newPass.length < 6) {
          _showMessage("Password must be at least 6 characters", isError: true);
          return;
        }
        if (newPass != confirmPass) {
          _showMessage("Passwords do not match", isError: true);
          return;
        }
      }

      if (isAdmin && newEmail.isNotEmpty && newEmail != currentEmail) {
        if (!_isValidEmail(newEmail)) {
          _showMessage("Please enter a valid email address", isError: true);
          return;
        }
      }
    }

    setState(() => loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showMessage("User not found. Please login again.", isError: true);
        return;
      }

      // For temporary accounts, create a completely new account with real credentials
      if (isTempAccount && isAdmin) {
        setState(() => isUpdatingEmail = true);

        try {
          // Try to create new account - if email exists, FirebaseAuth will throw an error
          final newUserCredential = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
                email: newEmail,
                password: newPass,
              );

          // Copy data from old temp account to new real account
          final oldAdminDoc =
              await FirebaseFirestore.instance
                  .collection('schools')
                  .doc(widget.schoolId)
                  .collection('admins')
                  .doc(widget.userId)
                  .get();

          final oldData = oldAdminDoc.data() ?? {};

          // Create new admin document with new UID
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('admins')
              .doc(newUserCredential.user!.uid)
              .set({
                'email': newEmail,
                'realEmail': newEmail,
                'role': 'Admin',
                'firstLogin': false,
                'isRealAdmin': true,
                'isTemporaryAccount': false,
                'isDemoAdmin': false,
                'schoolRegistered': true,
                'createdAt': FieldValue.serverTimestamp(),
                'convertedFromTemp': widget.userId,
                'originalCreatedAt':
                    oldData['createdAt'] ?? FieldValue.serverTimestamp(),
              });

          // Mark the old temp account as converted
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('admins')
              .doc(widget.userId)
              .update({
                'convertedTo': newUserCredential.user!.uid,
                'convertedAt': FieldValue.serverTimestamp(),
                'isActive': false,
              });

          // Delete the temporary account
          try {
            await user.delete();
          } catch (e) {
            debugPrint("Could not delete temp account: $e");
          }

          _showMessage(
            "✅ Account setup complete!\n\nPlease login with your new credentials: $newEmail",
            isError: false,
          );

          await FirebaseAuth.instance.signOut();

          if (!mounted) return;

          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginPage(role: widget.role)),
                (route) => false,
              );
            }
          });
          return;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            _showMessage(
              "❌ This email is already registered.\n\nPlease use a different email or try logging in.",
              isError: true,
            );
            setState(() => loading = false);
            return;
          }
          rethrow;
        }
      }

      // Normal update flow (non-temporary accounts)
      final email = user.email!;

      if (!isTempAccount) {
        final credential = EmailAuthProvider.credential(
          email: email,
          password: oldPass,
        );
        await user.reauthenticateWithCredential(credential);
      }

      // Update email (Admin only, non-temp accounts)
      if (isAdmin &&
          newEmail.isNotEmpty &&
          newEmail != email &&
          !isTempAccount) {
        try {
          await user.verifyBeforeUpdateEmail(newEmail);
          _showMessage(
            "✅ Verification email sent to $newEmail.\n\nPlease verify your email to complete the update.",
            isError: false,
          );

          await FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('admins')
              .doc(widget.userId)
              .update({
                'pendingEmail': newEmail,
                'updatedAt': FieldValue.serverTimestamp(),
              });
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            _showMessage(
              "This email is already in use by another account",
              isError: true,
            );
            setState(() => loading = false);
            return;
          }
          rethrow;
        }
      }

      // Update password if provided
      if (newPass.isNotEmpty) {
        await user.updatePassword(newPass);
        _showMessage("✅ Password updated successfully!", isError: false);
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
          .update({
            'firstLogin': false,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      _showMessage(
        "✅ Credentials updated successfully!\n\nPlease login with your new credentials.",
        isError: false,
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => LoginPage(role: widget.role)),
            (route) => false,
          );
        }
      });
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Error: ${e.message}";
      switch (e.code) {
        case 'wrong-password':
          errorMessage = "❌ Old password is incorrect";
          break;
        case 'weak-password':
          errorMessage =
              "❌ Password is too weak. Use at least 6 characters with letters and numbers";
          break;
        case 'requires-recent-login':
          errorMessage = "❌ Please login again before changing credentials";
          break;
        case 'email-already-in-use':
          errorMessage =
              "❌ This email address is already in use by another account";
          break;
        case 'invalid-email':
          errorMessage = "❌ Invalid email address format";
          break;
        case 'network-request-failed':
          errorMessage = "❌ Network error. Please check your connection";
          break;
        case 'user-not-found':
          errorMessage = "❌ User account not found";
          break;
        default:
          errorMessage = "❌ ${e.message}";
      }
      _showMessage(errorMessage, isError: true);
    } catch (e) {
      _showMessage("❌ Login failed: ${e.toString()}", isError: true);
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

  void _showMessage(String text, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(fontSize: 14)),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
