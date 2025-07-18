import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() => runApp(const StudentGraderApp());

class StudentGraderApp extends StatelessWidget {
  const StudentGraderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Grader',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}
