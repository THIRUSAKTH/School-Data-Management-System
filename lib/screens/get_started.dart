import 'package:flutter/material.dart';
import 'package:schoolprojectjan/screens/login_page.dart';
import 'package:schoolprojectjan/screens/role_select_screen.dart';

class GetStarted extends StatelessWidget {
  const GetStarted({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        //if you click this button,it goes to role based login screens.
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return RoleSelectScreen();
                },
              ),
            );
          },
          child: Text(
            "Get Started",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
