import 'package:flutter/material.dart';
import 'package:schoolprojectjan/screens/get_started.dart';

void main(){
 runApp(MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false,home: GetStarted(),);
  }
}
