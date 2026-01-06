import 'package:flutter/material.dart';
import 'package:schoolprojectjan/screens/admin/admin_home.dart';

class LoginPage extends StatefulWidget {
  final Map<String, dynamic> details;
  const LoginPage({super.key, required this.details});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isVisible = true;
  bool isCheck = false;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isWeb = size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xff8a27e9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWeb ? 420 : double.infinity,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// 🔝 HEADER – BACK TO ROLE
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: widget.details["color"].withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: widget.details["color"],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Back to Role Selection",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: widget.details["color"],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  /// 👤 ROLE ICON
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: widget.details["color"],
                    child: const Icon(
                      Icons.group,
                      color: Colors.white,
                      size: 46,
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// ROLE TITLE
                  Text(
                    widget.details["role"],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  /// ROLE DESCRIPTION
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Text(
                      widget.details["roleDescription"],
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),

                  const SizedBox(height: 28),

                  /// EMAIL
                  _label("Email Address"),
                  _textField(
                    controller: emailController,
                    hint: "Enter email",
                  ),

                  const SizedBox(height: 18),

                  /// PASSWORD
                  _label("Password"),
                  _textField(
                    controller: passwordController,
                    obscure: isVisible,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() => isVisible = !isVisible);
                      },
                      icon: Icon(
                        isVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// REMEMBER + FORGOT
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isCheck,
                          onChanged: (value) {
                            setState(() => isCheck = value!);
                          },
                        ),
                        const Text(
                          "Remember Me",
                          style: TextStyle(fontSize: 13),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            "Forgot Password?",
                            style: TextStyle(
                              color: widget.details["color"],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  /// 🔐 SIGN IN BUTTON (FIXED FOR SMALL MOBILE)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: size.width < 600 ? double.infinity : 220,
                      height: size.width < 600 ? 48 : 52,
                      child: ElevatedButton(
                        onPressed: () {
                          final role = widget.details["role"];

                          Widget target;

                          if (role == "Admin") {
                            target = const AdminHome();
                          }
                          // else if (role == "Teacher") {
                          //   target = const TeacherHome();
                          // } else if (role == "Parent") {
                          //   target = const ParentHome();
                          // } else {
                          //   target = const StudentHome();
                          // }

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => AdminHome()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 5,
                          backgroundColor: widget.details["color"],
                          foregroundColor: Colors.white,
                          shadowColor:
                          widget.details["color"].withOpacity(0.35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.login, size: 18),
                            SizedBox(width: 8),
                            Text(
                              "Sign In",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// CONTACT ADMIN
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account?",
                        style: TextStyle(fontSize: 13),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          "Contact Admin",
                          style: TextStyle(
                            color: widget.details["color"],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ===== REUSABLE WIDGETS =====

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    bool obscure = false,
    Widget? suffixIcon,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.black12,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
