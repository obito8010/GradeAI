import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/ocr_service.dart';
import '../services/groq_service.dart';

class AIGRadingScreen extends StatefulWidget {
  const AIGRadingScreen({super.key});
  @override
  State<AIGRadingScreen> createState() => _AIGRadingScreenState();
}

class _AIGRadingScreenState extends State<AIGRadingScreen> {
  String result = "";
  final TextEditingController questionController = TextEditingController();
  final TextEditingController marksController = TextEditingController();

  Future<void> pickAndGrade() async {
    final picked = await FilePicker.platform.pickFiles();
    if (picked != null) {
      final answerText = await OCRService.extractText(File(picked.files.first.path!));
      final question = questionController.text;
      final marks = int.tryParse(marksController.text) ?? 10;

      final response = await GroqService.gradeAnswer(question, answerText, marks);
      setState(() {
        result = response;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Grading')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: questionController, decoration: const InputDecoration(labelText: "Enter Question")),
            TextField(controller: marksController, decoration: const InputDecoration(labelText: "Total Marks")),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: pickAndGrade, child: const Text("Pick Answer Sheet and Grade")),
            const SizedBox(height: 20),
            Text(result),
          ],
        ),
      ),
    );
  }
}
