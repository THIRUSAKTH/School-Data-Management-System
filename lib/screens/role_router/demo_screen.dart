// lib/screens/demo_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import '../app_config.dart';
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
  bool _skipDemo = false;

  @override
  void initState() {
    super.initState();
    _checkSkipStatus();
  }

  Future<void> _checkSkipStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _skipDemo = prefs.getBool('skipDemo') ?? false;
    });

    if (_skipDemo) {
      // Auto navigate to role select after 1 second
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RoleSelectScreen()),
          );
        }
      });
    }
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

  Future<void> _submitLead() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Store lead in Firestore
      await FirebaseFirestore.instance.collection('leads').add({
        'name': _nameController.text.trim(),
        'schoolName': _schoolNameController.text.trim(),
        'email': _emailController.text.trim().toLowerCase(),
        'phone': _phoneController.text.trim(),
        'message': _messageController.text.trim(),
        'source': 'Demo App',
        'status': 'new',
        'createdAt': FieldValue.serverTimestamp(),
        'isContacted': false,
      });

      // Send email notification (using Cloud Function or API)
      await _sendEmailNotification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Thank you! Our team will contact you soon."),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Mark that user has seen demo
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('skipDemo', true);

        // Navigate to role select
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoleSelectScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _sendEmailNotification() async {
    // You can use Firebase Cloud Function or third-party API
    // For now, just store in Firestore and later process
    // You can also use EmailJS, SendGrid, etc.
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
    if (_skipDemo) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6C3CE1), Color(0xFF26D0CE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header Section
                  _buildHeaderSection(),

                  // Form Card
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildInputField(
                            controller: _nameController,
                            label: "Your Name *",
                            icon: Icons.person,
                            validator: (v) => v?.isEmpty == true ? "Enter your name" : null,
                          ),
                          const SizedBox(height: 16),

                          _buildInputField(
                            controller: _schoolNameController,
                            label: "School Name *",
                            icon: Icons.school,
                            validator: (v) => v?.isEmpty == true ? "Enter school name" : null,
                          ),
                          const SizedBox(height: 16),

                          _buildInputField(
                            controller: _emailController,
                            label: "Email Address *",
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v?.isEmpty == true) return "Enter email";
                              if (!v!.contains('@') || !v.contains('.')) return "Invalid email";
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          _buildInputField(
                            controller: _phoneController,
                            label: "Phone Number *",
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            validator: (v) => v?.isEmpty == true ? "Enter phone number" : null,
                          ),
                          const SizedBox(height: 16),

                          _buildInputField(
                            controller: _messageController,
                            label: "Message (Optional)",
                            icon: Icons.message,
                            maxLines: 3,
                          ),

                          const SizedBox(height: 24),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submitLead,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6C3CE1),
                                foregroundColor: Colors.white,
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

                          const SizedBox(height: 16),

                          // Skip Link
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

                  // Info Section
                  _buildInfoSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Logo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.school,
              size: 45,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            "Get Your Own School App",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Try the demo then get a fully customized app for your school",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
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
          const SizedBox(height: 12),

          _infoRow(Icons.verified, "Your own branded app with school logo"),
          _infoRow(Icons.color_lens, "Custom colors & school name"),
          _infoRow(Icons.store, "Published on Google Play Store"),
          _infoRow(Icons.security, "Secure & dedicated database"),
          _infoRow(Icons.support_agent, "Free support & lifetime updates"),
          _infoRow(Icons.currency_rupee, "Affordable pricing plans"),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6C3CE1)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6C3CE1), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}