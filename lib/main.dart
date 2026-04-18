import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:schoolprojectjan/firebase_options.dart';
import 'package:schoolprojectjan/screens/get_started.dart';
import 'package:schoolprojectjan/screens/parents/parent_home_page.dart';
import 'package:schoolprojectjan/screens/parents/parent_login_page.dart';

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
      home: GetStarted(),
      routes: {
        '/parentLogin': (_) => const ParentLoginPage(),
        '/parent_home': (context) => const ParentHomePage(),
      },
    );
  }
}
