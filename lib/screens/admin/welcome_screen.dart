import 'package:flutter/material.dart';
import 'package:schoolprojectjan/app_config.dart';
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

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    /// 🔷 Animation Controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    /// 🔷 Fade Animation
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    /// 🔷 Scale Animation
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    /// 🔷 Navigate after delay (SAFE)
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return; // ✅ FIX

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminDashboard(schoolId: AppConfig.schoolId,), // ✅ FIXED
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Container(

        /// 🔷 Gradient Background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF00BCD4),
              Color(0xFF2196F3),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                /// 🔷 LOGO WITH SCALE ANIMATION
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25), // optional change later
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.white,
                      backgroundImage: widget.logoUrl.isNotEmpty
                          ? NetworkImage(widget.logoUrl)
                          : null,
                      child: widget.logoUrl.isEmpty
                          ? const Icon(Icons.school,
                          size: 50, color: Colors.blue)
                          : null,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                /// 🔷 SCHOOL NAME
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    widget.schoolName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                /// 🔷 WELCOME TEXT
                const Text(
                  "Welcome Admin",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 30),

                /// 🔷 LOADER
                const CircularProgressIndicator(
                  color: Colors.white,
                ),

                const SizedBox(height: 10),

                const Text(
                  "Loading Dashboard...",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}