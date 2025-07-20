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
  List<Map<String, dynamic>> modelFiles = [];
  List<Map<String, dynamic>> studentFiles = [];
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
        final text = await OCRService.extractText(File(image.path));
        setState(() {
          final file = {"text": text, "path": image.path};
          if (isModel) modelFiles.add(file);
          else studentFiles.add(file);
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
            final item = {"text": text, "path": file.path!};
            if (isModel) modelFiles.add(item);
            else studentFiles.add(item);
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

  void _showImageDialog(String imagePath) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Image.file(File(imagePath)),
      ),
    );
  }

  Widget _buildPreviewRow(bool isModel) {
    final files = isModel ? modelFiles : studentFiles;

    return files.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isModel ? "📘 Model Pages:" : "📕 Student Pages:"),
                const SizedBox(height: 6),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: files.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, index) {
                      final file = files[index];
                      return Stack(
                        children: [
                          GestureDetector(
                            onTap: () => _showImageDialog(file["path"]),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(file["path"]),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () {
                                setState(() => files.removeAt(index));
                              },
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black54,
                                ),
                                child: const Icon(Icons.close, size: 18, color: Colors.white),
                              ),
                            ),
                          )
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
  }

  Future<void> gradeAnswer() async {
    if (studentFiles.isEmpty || modelFiles.isEmpty) {
      setState(() => result = "❗ Please upload both answers before grading.");
      return;
    }

    final studentAnswer = studentFiles.map((e) => e['text']).join('\n');
    final modelAnswer = modelFiles.map((e) => e['text']).join('\n');

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
              onPressed: () => _showUploadOptions(isModel: true),
              child: const Text("📄 Upload Model Answer"),
            ),
            _buildPreviewRow(true),
            ElevatedButton(
              onPressed: () => _showUploadOptions(isModel: false),
              child: const Text("📄 Upload Student Answer"),
            ),
            _buildPreviewRow(false),
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
