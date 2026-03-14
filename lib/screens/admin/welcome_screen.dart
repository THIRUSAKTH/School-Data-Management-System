import 'package:flutter/material.dart';
import 'admin_dashboard.dart';

class WelcomeScreen extends StatefulWidget {

  final String schoolId;
  final String schoolName;
  final String logoUrl;

  const WelcomeScreen({
    super.key,
    required this.schoolId,
    required this.schoolName,
    required this.logoUrl,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 2), () {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AdminDashboard(
            schoolId: widget.schoolId,
          ),
        ),
      );

    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            /// SCHOOL LOGO
            CircleAvatar(
              radius: 50,
              backgroundImage: widget.logoUrl.isNotEmpty
                  ? NetworkImage(widget.logoUrl)
                  : null,
              child: widget.logoUrl.isEmpty
                  ? const Icon(Icons.school, size: 40)
                  : null,
            ),

            const SizedBox(height: 20),

            /// SCHOOL NAME
            Text(
              widget.schoolName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Welcome Admin",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 30),

            const CircularProgressIndicator(),

          ],
        ),
      ),
    );
  }
}