import 'dart:convert';
import 'package:http/http.dart' as http;

class GroqService {
  static const String _apiKey = 'YOUR_GROQ_API_KEY';
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  static Future<String> gradeAnswer(String question, String studentAnswer, int totalMarks) async {
    final prompt = '''
You are a precise evaluator.
Question: "$question"
Student Answer: "$studentAnswer"
Total Marks: $totalMarks
Evaluate and return in JSON: { "score": number, "feedback": string }
''';

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "llama3-8b-8192",
        "messages": [
          {"role": "system", "content": "You are an answer sheet evaluator."},
          {"role": "user", "content": prompt}
        ],
        "temperature": 0.2
      }),
    );

    final json = jsonDecode(response.body);
    final content = json['choices'][0]['message']['content'];
    return content;
  }
}
