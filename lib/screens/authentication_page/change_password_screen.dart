import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:schoolprojectjan/screens/teacher/teacher_home.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String schoolId;
  final String userId;
  final String role; // Teacher or Parent

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
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool loading = false;
  bool hide1 = true;
  bool hide2 = true;
  bool hide3 = true;

  @override
  Widget build(BuildContext context) {
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
                const Icon(Icons.lock_reset,
                    size: 70, color: Colors.deepPurple),

                const SizedBox(height: 16),

                const Text(
                  "Change Your Password",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 6),

                const Text(
                  "Enter old password first",
                  style: TextStyle(color: Colors.black54),
                ),

                const SizedBox(height: 18),

                _passwordField(
                  controller: oldPasswordController,
                  hint: "Old Password",
                  hide: hide1,
                  toggle: () => setState(() => hide1 = !hide1),
                ),

                const SizedBox(height: 12),

                _passwordField(
                  controller: newPasswordController,
                  hint: "New Password",
                  hide: hide2,
                  toggle: () => setState(() => hide2 = !hide2),
                ),

                const SizedBox(height: 12),

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
                    onPressed: loading ? null : _updatePassword,
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Update Password",
                        style: TextStyle(color: Colors.white)),
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

  Future<void> _updatePassword() async {
    final oldPass = oldPasswordController.text.trim();
    final newPass = newPasswordController.text.trim();
    final confirmPass = confirmPasswordController.text.trim();

    if (newPass.length < 6) {
      _msg("Password must be at least 6 characters");
      return;
    }

    if (newPass != confirmPass) {
      _msg("Passwords do not match");
      return;
    }

    setState(() => loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final email = user.email!;

      // 🔐 Re-authentication (THIS FIXES YOUR ERROR)
      final credential = EmailAuthProvider.credential(
        email: email,
        password: oldPass,
      );

      await user.reauthenticateWithCredential(credential);
      // ✅ Update password
      await user.updatePassword(newPass);
      // ✅ Update Firestore firstLogin flag
      final collection =
      widget.role == "Teacher" ? "teachers" : "parents";

      await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection(collection)
          .doc(widget.userId)
          .update({'firstLogin': false});

      _msg("Password updated successfully");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TeacherHome()),
      );
    } catch (e) {
      _msg("Error: ${e.toString()}");
    }

    setState(() => loading = false);
  }

  void _msg(String text) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
  }
}
