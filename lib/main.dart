import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:schoolprojectjan/firebase_options.dart';
import 'package:schoolprojectjan/screens/get_started.dart';
import 'package:schoolprojectjan/screens/parents/parent_home_page.dart';
import 'package:schoolprojectjan/screens/parents/parent_login_page.dart';
import 'package:schoolprojectjan/screens/parents/select_child_page.dart';
import 'package:schoolprojectjan/services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // This will automatically use the correct implementation for web/mobile
  await FCMService.initialize();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "School Management System",
      home: GetStarted(),
      routes: {
        '/select_child': (context) => const SelectChildPage(),
        '/parentLogin': (_) => const ParentLoginPage(),
        '/parent_home': (context) => const ParentHomePage(),
      },
    );
  }
}