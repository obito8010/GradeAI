import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/ocr_service.dart';
import '../services/ai_grader_service.dart';

class AIAutoGradingScreen extends StatefulWidget {
  const AIAutoGradingScreen({super.key});

  @override
  State<AIAutoGradingScreen> createState() => _AIAutoGradingScreenState();
}

class _AIAutoGradingScreenState extends State<AIAutoGradingScreen> {
  String studentAnswer = '';
  String modelAnswer = '';
  int totalMarks = 10;
  String result = '';
  bool isLoading = false;

  /// Pick model answer image/PDF and extract text
  Future<void> pickModelAnswer() async {
    final model = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (model != null) {
      final modelText = await OCRService.extractText(File(model.files.first.path!));
      setState(() => modelAnswer = modelText);
    }
  }

  /// Pick student answer image/PDF and extract text
  Future<void> pickStudentAnswer() async {
    final student = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (student != null) {
      final studentText = await OCRService.extractText(File(student.files.first.path!));
      setState(() => studentAnswer = studentText);
    }
  }

  /// Grade the student's answer using Groq
  Future<void> gradeAnswer() async {
    if (studentAnswer.isEmpty || modelAnswer.isEmpty) {
      setState(() => result = "❗ Please upload both answers before grading.");
      return;
    }

    setState(() {
      result = "";
      isLoading = true;
    });

    try {
      final response = await AIGRaderService.gradeWithGroq(
        studentAnswer: studentAnswer,
        modelAnswer: modelAnswer,
        totalMarks: totalMarks,
      );

      setState(() {
        result = "✅ Marks: ${response['marks']} / $totalMarks\n\n📝 Feedback:\n${response['feedback']}";
      });
    } catch (e) {
      setState(() => result = "❌ Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// Dialog to set total marks
  void _showMarkDialog() {
    final controller = TextEditingController(text: totalMarks.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Set Total Marks"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Enter total marks"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0) {
                setState(() => totalMarks = val);
              }
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Grading (Groq)")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: pickModelAnswer,
              child: const Text("📄 Upload Model Answer"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: pickStudentAnswer,
              child: const Text("📄 Upload Student Answer"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _showMarkDialog,
              child: Text("🎯 Set Total Marks (Current: $totalMarks)"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : gradeAnswer,
              child: const Text("✅ Grade Answer"),
            ),
            const SizedBox(height: 20),
            if (isLoading) const CircularProgressIndicator(),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  result,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
