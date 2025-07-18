import 'dart:io';
import 'package:google_ml_kit/google_ml_kit.dart';

class OCRService {
  static Future<String> extractText(File file) async {
    final inputImage = InputImage.fromFile(file);
    final textDetector = GoogleMlKit.vision.textRecognizer();
    final RecognizedText recognizedText = await textDetector.processImage(inputImage);
    await textDetector.close();

    return recognizedText.text;
  }
}
