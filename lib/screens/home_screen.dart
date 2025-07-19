import 'package:flutter/material.dart';
import 'manual_grading_screen.dart';
import 'ai_grading_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Answer Grader'),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.edit_document),
                label: const Text("📄 Manual Grading"),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AIAutoGradingScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.smart_toy),
                label: const Text("🤖 AI Grading"),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AIGRadingScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
