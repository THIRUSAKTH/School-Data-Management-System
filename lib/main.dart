import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:schoolprojectjan/firebase_options.dart';
import 'package:schoolprojectjan/screens/get_started.dart';
import 'package:schoolprojectjan/screens/parents/parent_home_page.dart';
import 'package:schoolprojectjan/screens/parents/parent_login_page.dart';
import 'package:schoolprojectjan/screens/parents/select_child_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "School Management System",
      home: const PermissionHandlerScreen(),
      routes: {
        '/get_started': (context) => const GetStarted(),
        '/select_child': (context) => const SelectChildPage(),
        '/parentLogin': (_) => const ParentLoginPage(),
        '/parent_home': (context) => const ParentHomePage(),
      },
    );
  }
}

// Permission Handler Screen - Shows before the main app
class PermissionHandlerScreen extends StatefulWidget {
  const PermissionHandlerScreen({super.key});

  @override
  State<PermissionHandlerScreen> createState() => _PermissionHandlerScreenState();
}

class _PermissionHandlerScreenState extends State<PermissionHandlerScreen> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
  }

  Future<void> _checkAndRequestPermissions() async {
    // For Android 8, we need storage permission
    if (await Permission.storage.isGranted) {
      // Permission already granted
      _navigateToMain();
      return;
    }

    // Request permission
    final status = await Permission.storage.request();

    if (status.isGranted) {
      _navigateToMain();
    } else if (status.isDenied) {
      // Show dialog explaining why permission is needed
      _showPermissionDeniedDialog();
    } else if (status.isPermanentlyDenied) {
      _showSettingsDialog();
    }
  }

  void _navigateToMain() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const GetStarted()),
      );
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Storage Permission Required",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "This app needs storage permission to:\n"
              "• Upload profile pictures\n"
              "• Attach files to homework\n"
              "• Add images to notices\n"
              "• Share documents\n\n"
              "Please grant permission to continue.",
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final status = await Permission.storage.request();
              if (status.isGranted) {
                _navigateToMain();
              } else {
                _showPermissionDeniedDialog();
              }
            },
            child: const Text("Grant Permission"),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Permission Permanently Denied",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: const Text(
          "Storage permission has been permanently denied.\n\n"
              "Please enable it from app settings to use all features.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text("Open Settings"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showPermissionDeniedDialog();
            },
            child: const Text("Try Again"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              "Checking permissions...",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}