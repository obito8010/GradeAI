import 'dart:io';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class OCRService {
  static Future<String> extractText(File file) async {
    final ext = file.path.split('.').last.toLowerCase();

    if (ext == 'pdf') {
      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final text = PdfTextExtractor(document).extractText();
      document.dispose();
      return text;
    } else {
      final inputImage = InputImage.fromFile(file);
      final textDetector = GoogleMlKit.vision.textRecognizer();
      final RecognizedText recognizedText = await textDetector.processImage(inputImage);
      await textDetector.close();
      return recognizedText.text;
    }
  }
}
