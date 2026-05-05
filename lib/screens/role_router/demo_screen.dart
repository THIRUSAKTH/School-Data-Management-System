// lib/screens/role_router/demo_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:schoolprojectjan/screens/get_started.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'role_select_screen.dart';

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _schoolNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isSubmitting = false;
  bool _hasSubmitted = false;

  // YOUR TELEGRAM CREDENTIALS (Updated)
  static const String _botToken = '8586271534:AAEj5Ge0S1VEeq-uKOJx-5_MtyzTznfucUs';
  static const String _chatId = '5230749142';  // Your Chat ID

  @override
  void initState() {
    super.initState();
    _checkSubmissionStatus();
  }

  Future<void> _checkSubmissionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasSubmitted = prefs.getBool('hasSubmittedLead') ?? false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _schoolNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendTelegramNotification({
    required String name,
    required String schoolName,
    required String email,
    required String phone,
    required String message,
  }) async {
    try {
      final String text = """
🎉 *NEW SCHOOL DEMO REQUEST!* 🎉

🏫 *School:* $schoolName
👤 *Contact:* $name
📧 *Email:* $email
📞 *Phone:* $phone
💬 *Message:* ${message.isEmpty ? 'No message' : message}
📅 *Time:* ${DateTime.now().toString()}

*Action Required:* Contact this school immediately!

#Lead #DemoRequest #SchoolManagement
      """;

      final url = "https://api.telegram.org/bot$_botToken/sendMessage";
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'chat_id': _chatId,
          'text': text,
          'parse_mode': 'Markdown',
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Telegram notification sent successfully!");
      } else {
        print("❌ Telegram error: ${response.body}");
      }
    } catch (e) {
      print("❌ Telegram error: $e");
    }
  }

  Future<void> _submitLead() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final String name = _nameController.text.trim();
      final String schoolName = _schoolNameController.text.trim();
      final String email = _emailController.text.trim().toLowerCase();
      final String phone = _phoneController.text.trim();
      final String message = _messageController.text.trim();

      // 1. Save to Firestore
      await FirebaseFirestore.instance.collection('leads').add({
        'name': name,
        'schoolName': schoolName,
        'email': email,
        'phone': phone,
        'message': message,
        'status': 'new',
        'createdAt': FieldValue.serverTimestamp(),
        'source': 'Demo App',
        'isContacted': false,
      });

      print("✅ Lead saved to Firestore");

      // 2. Send Telegram Notification
      await _sendTelegramNotification(
        name: name,
        schoolName: schoolName,
        email: email,
        phone: phone,
        message: message,
      );

      // 3. Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSubmittedLead', true);
      await prefs.setBool('skipDemo', true);

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      print("❌ Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 30),
            SizedBox(width: 10),
            Text("Thank You!"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Our team will contact you soon.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "📧 What happens next?",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "1. You'll receive a confirmation email\n"
                        "2. Our sales team will call you within 24 hours\n"
                        "3. We'll schedule a personalized demo\n"
                        "4. Get your customized school app",
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const RoleSelectScreen()),
              );
            },
            child: const Text("Continue to Demo"),
          ),
        ],
      ),
    );
  }

  void _skipToApp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('skipDemo', true);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RoleSelectScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F9B8E)),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const GetStarted()),
            );
          },
        ),
        title: const Text(
          "Get Your School App",
          style: TextStyle(
            color: Color(0xFF0F9B8E),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (_hasSubmitted)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Thank you for your interest! Our team will contact you soon.",
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                    ),
                  ],
                ),
              ),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F9B8E), Color(0xFF1EC8D9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.school, size: 50, color: Colors.white),
                  const SizedBox(height: 15),
                  const Text(
                    "Get Your Own School App",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Try the demo then get a fully customized app for your school",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: "Your Name *",
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: _schoolNameController,
                      label: "School Name *",
                      icon: Icons.school,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: _emailController,
                      label: "Email Address *",
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: _phoneController,
                      label: "Phone Number *",
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: _messageController,
                      label: "Message (Optional)",
                      icon: Icons.message,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitLead,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F9B8E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text(
                          "Get Your School App",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _skipToApp,
                      child: const Text(
                        "Try Demo First",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    "What You'll Get:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _infoRow(Icons.verified, "Your own branded app with school logo"),
                  _infoRow(Icons.color_lens, "Custom colors & school name"),
                  _infoRow(Icons.store, "Published on Google Play Store"),
                  _infoRow(Icons.security, "Secure & dedicated database"),
                  _infoRow(Icons.support_agent, "Free support & lifetime updates"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (value) {
        if (label.contains('*') && (value == null || value.isEmpty)) {
          return "This field is required";
        }
        if (label.contains('Email') && value != null && value.isNotEmpty) {
          if (!value.contains('@') || !value.contains('.')) {
            return "Enter valid email";
          }
        }
        if (label.contains('Phone') && value != null && value.isNotEmpty) {
          if (value.length < 10) {
            return "Enter valid phone number";
          }
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF0F9B8E)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0F9B8E), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}