// lib/screens/common/settings_page.dart
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.dark_mode),
            title: Text("Dark Mode (Coming Soon)"),
          ),
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text("App Version 1.0"),
          ),
        ],
      ),
    );
  }
}