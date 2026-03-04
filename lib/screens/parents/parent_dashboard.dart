import 'package:flutter/material.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key, required String schoolId});


  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      /// 🔻 Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: "Reports"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: "Profile"),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [

            /// 🔶 Gradient Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Column(
                children: const [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person,
                        size: 45, color: Colors.orange),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Arun Kumar",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Class 10 - A | Roll No: 15",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 🔷 Quick Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: const [
                  _StatCard(
                    title: "Attendance",
                    value: "92%",
                    color: Colors.green,
                  ),
                  _StatCard(
                    title: "Fees Due",
                    value: "₹2000",
                    color: Colors.red,
                  ),
                  _StatCard(
                    title: "Homework",
                    value: "3",
                    color: Colors.blue,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// 🔷 Dashboard Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                shrinkWrap: true,
                physics:
                const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.15,
                children: const [
                  _FeatureCard(
                    title: "Attendance",
                    icon: Icons.fact_check,
                    color: Colors.green,
                  ),
                  _FeatureCard(
                    title: "Homework",
                    icon: Icons.book,
                    color: Colors.blue,
                  ),
                  _FeatureCard(
                    title: "Fees",
                    icon: Icons.payment,
                    color: Colors.red,
                  ),
                  _FeatureCard(
                    title: "Results",
                    icon: Icons.bar_chart,
                    color: Colors.purple,
                  ),
                  _FeatureCard(
                    title: "Notices",
                    icon: Icons.notifications,
                    color: Colors.orange,
                  ),
                  _FeatureCard(
                    title: "Performance",
                    icon: Icons.analytics,
                    color: Colors.indigo,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

/// ---------------- STAT CARD ----------------

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// ---------------- FEATURE CARD ----------------

class _FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _FeatureCard({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.7), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}