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

  Future<void> pickAndCompare() async {
    final student = await FilePicker.platform.pickFiles();
    final model = await FilePicker.platform.pickFiles();

    if (student != null && model != null) {
      final studentText = await OCRService.extractText(File(student.files.first.path!));
      final modelText = await OCRService.extractText(File(model.files.first.path!));

      double similarity = _calculateSimilarity(studentText, modelText);
      int marks = (similarity * 10).round();

      setState(() {
        result = "Similarity: ${(similarity * 100).toStringAsFixed(2)}%\nMarks: $marks / 10";
      });
    }
  }

  double _calculateSimilarity(String a, String b) {
    final aWords = a.toLowerCase().split(' ');
    final bWords = b.toLowerCase().split(' ');
    final common = aWords.toSet().intersection(bWords.toSet()).length;
    return common / bWords.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manual Grading')),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 20),
            ElevatedButton(onPressed: pickAndCompare, child: const Text("Pick Student & Model Answer")),
            const SizedBox(height: 20),
            Text(result),
          ],
        ),
      ),
    );
  }
}
