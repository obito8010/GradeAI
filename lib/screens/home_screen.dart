import 'package:flutter/material.dart';
import 'manual_grading_screen.dart';
import 'ai_grading_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Answer Grader')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text("📄 Manual Grading"),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManualGradingScreen()),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text("🤖 AI Grading"),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AIGRadingScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
