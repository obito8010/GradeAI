import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ocr_service.dart';
import '../services/ai_grader_service.dart';

class AIAutoGradingScreen extends StatefulWidget {
  const AIAutoGradingScreen({super.key});

  @override
  State<AIAutoGradingScreen> createState() => _AIAutoGradingScreenState();
}

class _AIAutoGradingScreenState extends State<AIAutoGradingScreen> {
  List<String> studentAnswers = [];
  List<String> modelAnswers = [];
  int totalMarks = 10;
  String result = '';
  bool isLoading = false;

  final ImagePicker picker = ImagePicker();

  Future<void> _pickFile({
    required bool isModel,
    required bool useCamera,
  }) async {
    try {
      if (useCamera) {
        final image = await picker.pickImage(source: ImageSource.camera);
        if (image == null) return;

        final extracted = await OCRService.extractText(File(image.path));
        setState(() {
          if (isModel) {
            modelAnswers.add(extracted);
          } else {
            studentAnswers.add(extracted);
          }
        });
      } else {
        final picked = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        );
        if (picked == null) return;

        for (var file in picked.files) {
          final text = await OCRService.extractText(File(file.path!));
          setState(() {
            if (isModel) {
              modelAnswers.add(text);
            } else {
              studentAnswers.add(text);
            }
          });
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${isModel ? 'Model' : 'Student'} upload completed ✅')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  Future<void> _showUploadOptions({required bool isModel}) async {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickFile(isModel: isModel, useCamera: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Pick from Gallery or PDF'),
              onTap: () {
                Navigator.pop(context);
                _pickFile(isModel: isModel, useCamera: false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> gradeAnswer() async {
    if (studentAnswers.isEmpty || modelAnswers.isEmpty) {
      setState(() => result = "❗ Please upload both answers before grading.");
      return;
    }

    final fullStudentAnswer = studentAnswers.join('\n');
    final fullModelAnswer = modelAnswers.join('\n');

    setState(() {
      result = "";
      isLoading = true;
    });

    try {
      final response = await AIGRaderService.gradeWithGroq(
        studentAnswer: fullStudentAnswer,
        modelAnswer: fullModelAnswer,
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

  Widget _buildPreviewList(String label, List<String> texts) {
    return ExpansionTile(
      title: Text("$label Pages (${texts.length})"),
      children: texts.asMap().entries.map((entry) {
        return ListTile(
          title: Text("Page ${entry.key + 1}"),
          subtitle: Text(
            entry.value.length > 100 ? "${entry.value.substring(0, 100)}..." : entry.value,
            maxLines: 2,
          ),
        );
      }).toList(),
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
              onPressed: () => _showUploadOptions(isModel: true),
              child: const Text("📄 Upload Model Answer"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _showUploadOptions(isModel: false),
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
            _buildPreviewList("📘 Model Answer", modelAnswers),
            _buildPreviewList("📕 Student Answer", studentAnswers),
            const SizedBox(height: 10),
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
