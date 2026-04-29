import 'package:flutter/material.dart';
import 'package:schoolprojectjan/screens/authentication_page/login_page.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  final List<Map<String, dynamic>> details = const [
    {
      "color": Colors.cyan,
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
      "color": Color(0xff01285f),
      "role": "Parent",
      "roleDescription": "Track your child's progress",
      "text": "Sign in as Parent",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final bool isWeb = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: Colors.cyan,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: EdgeInsets.all(isWeb ? 32 : 16),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.cyanAccent,
                      child: Icon(
                        Icons.school_outlined,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),

                    const SizedBox(height: 16),

                    const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "School Management System",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),
                const Text(
                  "Select your role to continue",

                     style: TextStyle(color: Colors.white),
                    ),

                    const SizedBox(height: 30),

                    isWeb
                        ? GridView.builder(
                      shrinkWrap: true,
                      itemCount: details.length,
                      gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 520,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.75,
                      ),
                      itemBuilder: (_, i) =>
                          RoleCard(data: details[i]),
                    )
                        : ListView.separated(
                      shrinkWrap: true,
                      physics:
                      const NeverScrollableScrollPhysics(),
                      itemCount: details.length,
                      separatorBuilder: (_, __) =>
                      const SizedBox(height: 15),
                      itemBuilder: (_, i) =>
                          RoleCard(data: details[i]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ================= ROLE CARD =================

class RoleCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const RoleCard({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06), // ✅ updated
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: data["color"],
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.group,
                size: 26, color: Colors.white),
          ),

          const SizedBox(height: 12),

          Text(
            data["role"],
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16),
          ),

          const SizedBox(height: 4),

          Text(
            data["roleDescription"],
            style: const TextStyle(fontSize: 13),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: data["color"],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LoginPage(
                      role: data["role"], // ✅ FIXED
                    ),
                  ),
                );
              },
              child: Text(
                data["text"],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
