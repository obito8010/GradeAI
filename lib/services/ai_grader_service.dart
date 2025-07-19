import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AIGRaderService {
  static Future<Map<String, dynamic>> gradeWithGroq({
    required String studentAnswer,
    required String modelAnswer,
    required int totalMarks,
  }) async {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    final uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final prompt = '''
You are an examiner. Grade the following student answer out of $totalMarks based on the model answer.
Also give a short feedback on where the student did well and what was missing.

Model Answer:
$modelAnswer

Student Answer:
$studentAnswer

Return your response in JSON format like:
{
  "marks": 7,
  "feedback": "Good understanding but missed key points on [topic]."
}
''';

    final body = jsonEncode({
      "model": "llama3-70b-8192", 
      "messages": [
        {"role": "system", "content": "You are a helpful examiner."},
        {"role": "user", "content": prompt}
      ],
      "temperature": 0.3,
    });

    final response = await http.post(uri, headers: headers, body: body);

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final content = decoded['choices'][0]['message']['content'];
      final parsed = json.decode(content);
      return {
        "marks": parsed["marks"],
        "feedback": parsed["feedback"],
      };
    } else {
      throw Exception('Failed to get AI grading: ${response.body}');
    }
  }
}
