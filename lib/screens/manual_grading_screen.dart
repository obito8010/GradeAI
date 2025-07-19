import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/ocr_service.dart';

class ManualGradingScreen extends StatefulWidget {
  const ManualGradingScreen({super.key});

  @override
  State<ManualGradingScreen> createState() => _ManualGradingScreenState();
}

class _ManualGradingScreenState extends State<ManualGradingScreen> {
  String result = "";
  String studentAnswer = "";
  String modelAnswer = "";
  int totalMarks = 10;

  Future<void> pickModelAnswer() async {
    final model = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'png', 'jpeg', 'pdf']);
    if (model != null) {
      final modelText = await OCRService.extractText(File(model.files.first.path!));
      setState(() {
        modelAnswer = modelText;
      });
    }
  }

  Future<void> pickStudentAnswer() async {
    final student = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'png', 'jpeg', 'pdf']);
    if (student != null) {
      final studentText = await OCRService.extractText(File(student.files.first.path!));
      setState(() {
        studentAnswer = studentText;
      });
    }
  }

  void gradeAnswer() {
    if (studentAnswer.isEmpty || modelAnswer.isEmpty) {
      setState(() {
        result = "Please upload both model and student answers.";
      });
      return;
    }

    double similarity = _calculateSimilarity(studentAnswer, modelAnswer);
    int marks = (similarity * totalMarks).round();

    setState(() {
      result =
          "Similarity: ${(similarity * 100).toStringAsFixed(2)}%\nMarks: $marks / $totalMarks";
    });
  }

  double _calculateSimilarity(String a, String b) {
    final aWords = a.toLowerCase().split(RegExp(r'\s+'));
    final bWords = b.toLowerCase().split(RegExp(r'\s+'));
    final common = aWords.toSet().intersection(bWords.toSet()).length;
    return common / (bWords.length == 0 ? 1 : bWords.length);
  }

  void _showTotalMarksDialog() {
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
                final value = int.tryParse(controller.text);
                if (value != null && value > 0) {
                  setState(() {
                    totalMarks = value;
                  });
                }
                Navigator.pop(context);
              },
              child: const Text("Save"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manual Grading')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
              onPressed: _showTotalMarksDialog,
              child: Text("🎯 Set Total Marks (Current: $totalMarks)"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: gradeAnswer,
              child: const Text("✅ Grade Answer"),
            ),
            const SizedBox(height: 20),
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
