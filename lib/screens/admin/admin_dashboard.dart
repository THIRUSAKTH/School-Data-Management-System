import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isWeb = MediaQuery.of(context).size.width >= 900;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// ✅ WEB SIDEBAR
        if (isWeb) const WebSidebar(),

        /// ✅ MAIN CONTENT
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                "Overview",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              LayoutBuilder(
                builder: (context, constraints) {
                  final int count = constraints.maxWidth >= 1200 ? 4 : 2;

                  return GridView.count(
                    crossAxisCount: count,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: const [
                      DashboardCard(
                        title: "Students",
                        value: "520",
                        icon: Icons.group,
                        color: Colors.blue,
                      ),
                      DashboardCard(
                        title: "Teachers",
                        value: "42",
                        icon: Icons.school,
                        color: Colors.purple,
                      ),
                      DashboardCard(
                        title: "Fees Pending",
                        value: "₹1,24,000",
                        icon: Icons.currency_rupee,
                        color: Colors.orange,
                      ),
                      DashboardCard(
                        title: "Attendance",
                        value: "94%",
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              const Text(
                "Quick Actions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              const ActionTile(
                icon: Icons.person,
                title: "Manage Students",
              ),
              const ActionTile(
                icon: Icons.school,
                title: "Manage Teachers",
              ),
              const ActionTile(
                icon: Icons.notifications,
                title: "Broadcast Notice",
              ),
            ],
          ),
        ),
      ],
    );
  }
}

////////////////////////////////////////////////
/// WEB SIDEBAR
////////////////////////////////////////////////

class WebSidebar extends StatelessWidget {
  const WebSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      color: Colors.white,
      child: Column(
        children: const [
          SizedBox(height: 24),
          SidebarItem(
            icon: Icons.dashboard,
            label: "Dashboard",
            selected: true,
          ),
          SidebarItem(
            icon: Icons.check_circle,
            label: "Attendance",
          ),
          SidebarItem(
            icon: Icons.currency_rupee,
            label: "Fees",
          ),
          SidebarItem(
            icon: Icons.notifications,
            label: "Notices",
          ),
        ],
      ),
    );
  }
}

class SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const SidebarItem({
    super.key,
    required this.icon,
    required this.label,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: selected
            ? Colors.deepPurple.withOpacity(0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          child: SizedBox(
            height: 70,
            width: 70,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: selected ? Colors.deepPurple : Colors.grey,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: selected ? Colors.deepPurple : Colors.grey,
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

////////////////////////////////////////////////
/// DASHBOARD CARD
////////////////////////////////////////////////

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////
/// ACTION TILE
////////////////////////////////////////////////

class ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;

  const ActionTile({
    super.key,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () {},
      ),
    );
  }
}
