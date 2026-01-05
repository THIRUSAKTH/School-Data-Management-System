import 'package:flutter/material.dart';
import 'package:schoolprojectjan/screens/login_page.dart';

class RoleSelectScreen extends StatelessWidget {
  RoleSelectScreen({super.key});

  final List<Map<String, dynamic>> details = [
    {
      "color": Colors.deepPurple,
      "role": "Admin",
      "roleDescription": "School Management & Administration",
      "text": "Sign in as Admin",
    },
    {
      "color": Colors.green,
      "role": "Teacher",
      "roleDescription": "Manage classes & student progress",
      "text": "Sign in as Teacher",
    },
    {
      "color": Colors.orange,
      "role": "Parent",
      "roleDescription": "Track your child's progress",
      "text": "Sign in as Parent",
    },
    {
      "color": Colors.blue,
      "role": "Student",
      "roleDescription": "Access homework & schedules",
      "text": "Sign in as Student",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isWeb = size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xff851ef3),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: EdgeInsets.all(size.width * 0.04),
              child: Column(
                children: [
                  /// HEADER
                  CircleAvatar(
                    radius: size.width < 600 ? 45 : 55,
                    backgroundColor: const Color(0xff9c45f8),
                    child: const Icon(
                      Icons.school_outlined,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "School Management System",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: size.width < 600 ? 22 : 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Select your role to continue",
                    style: TextStyle(fontSize: 15, color: Colors.white),
                  ),
                  const SizedBox(height: 30),

                  /// RESPONSIVE LAYOUT
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (isWeb) {
                        /// 🌐 WEB GRID
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: details.length,
                          gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 520,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.75,
                          ),
                          itemBuilder: (context, index) {
                            return HoverCard(
                              child: RoleCard(data: details[index]),
                            );
                          },
                        );
                      } else {
                        /// 📱 MOBILE LIST
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: details.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 15),
                          itemBuilder: (context, index) {
                            return RoleCard(data: details[index]);
                          },
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ================= HOVER EFFECT WRAPPER =================
class HoverCard extends StatefulWidget {
  final Widget child;

  const HoverCard({super.key, required this.child});

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: _hovering
            ? (Matrix4.identity()..translate(0, -6))
            : Matrix4.identity(),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 180),
          scale: _hovering ? 1.02 : 1.0,
          child: widget.child,
        ),
      ),
    );
  }
}

/// ================= ROLE CARD =================
class RoleCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const RoleCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ICON
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: data["color"],
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.group,
              size: 26,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 12),

          /// ROLE
          Text(
            data["role"],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 4),

          /// DESCRIPTION
          Text(
            data["roleDescription"],
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
            ),
          ),

          const Spacer(),

          /// BUTTON
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: data["color"],
                foregroundColor: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginPage(details: data),
                  ),
                );
              },
              child: Text(
                data["text"],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
