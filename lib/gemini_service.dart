import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  // 🔑 6 SEPARATE API KEYS
  static const String apiKey1 = String.fromEnvironment(
    'API_KEY_1',
    defaultValue: 'AIzaSyBFA9N14fgqZMydbP2kHyiZXVCklFuU7mo',
  );
  static const String apiKey2 = String.fromEnvironment(
    'API_KEY_2',
    defaultValue: 'AIzaSyC45MNVg9pZ72QV5EkESMCgPmxKw6ohzmg',
  );
  static const String apiKey3 = String.fromEnvironment(
    'API_KEY_3',
    defaultValue: 'AIzaSyDXkrEtfOPVlxX099yFkHRsJcotvuORRgs',
  );
  static const String apiKey4 = String.fromEnvironment(
    'API_KEY_4',
    defaultValue: 'AIzaSyBdN-6qaS-p6FVoGIii0jJi9xItQSD3m6w',
  );
  static const String apiKey5 = String.fromEnvironment(
    'API_KEY_5',
    defaultValue: 'AIzaSyBiRG75cbPz2AbY2_vwjjuoN0O3hBIUFI4',
  );
  static const String apiKey6 = String.fromEnvironment(
    'API_KEY_6',
    defaultValue: 'AIzaSyBBI5wY38QHf2RuaJETnnL3fb3Tmlc7pIQ',
  );

  // ✅ Generate content with streaming callback
  static Future<void> _generateContentStreaming(
      String prompt,
      String apiKey,
      Function(String) onChunk,
      ) async {
    try {
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey'
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final fullText = data['candidates'][0]['content']['parts'][0]['text'] ?? 'No response';

        // Simulate streaming by sending text chunk by chunk
        await _streamText(fullText, onChunk);
      } else {
        onChunk('Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      onChunk('Error: ${e.toString()}');
    }
  }

  // 📝 Stream text word by word with animation
  static Future<void> _streamText(String text, Function(String) onChunk) async {
    final words = text.split(' ');
    String currentText = '';

    for (int i = 0; i < words.length; i++) {
      currentText += words[i] + ' ';
      onChunk(currentText);

      // Adjust delay for speed (30ms = fast, 80ms = slower)
      await Future.delayed(Duration(milliseconds: 30));
    }
  }

  // 💼 Get Tech Careers (uses apiKey1)
  static Future<void> getTechCareersStreaming(Function(String) onChunk) async {
    final prompt = '''
List 10 trending tech careers for DIET college students in India in 2025.
For each career, include:
- Job title
- Average salary in India (LPA)
- Required skills
- Career growth potential

Format as a clear, structured response with emojis.
''';
    return _generateContentStreaming(prompt, apiKey1, onChunk);
  }

  // 💰 Get Salary Information (uses apiKey2)
  static Future<void> getSalaryInfoStreaming(String role, Function(String) onChunk) async {
    final prompt = '''
Provide detailed salary information for $role in India (2025):
- Fresher salary (0-1 years)
- Mid-level salary (3-5 years)
- Senior-level salary (8+ years)
- Top companies paying highest
- Location-wise breakdown (Bangalore, Mumbai, Delhi, Pune)

Show in INR (Lakhs per annum). Use emojis and clear formatting.
''';
    return _generateContentStreaming(prompt, apiKey2, onChunk);
  }

  // 📚 Get Learning Paths (uses apiKey3)
  static Future<void> getLearningPathStreaming(String domain, Function(String) onChunk) async {
    final prompt = '''
Create a complete learning roadmap for $domain for Indian students:
- Beginner level (with free course names and platforms)
- Intermediate topics
- Advanced specializations
- Best free resources (YouTube, Coursera, Udemy)
- Timeline for each level
- Top certifications

Format clearly for a DIET student. Use emojis.
''';
    return _generateContentStreaming(prompt, apiKey3, onChunk);
  }

  // 🎓 Get DIET Guide (uses apiKey4)
  static Future<void> getDIETGuideStreaming(Function(String) onChunk) async {
    final prompt = '''
Provide comprehensive career guidance for DIET (Diploma in Engineering & Information Technology) students:
- Best career paths after DIET
- Further education options (BE, B.Tech lateral entry)
- Job opportunities for diploma holders
- Salary expectations
- Skill development tips
- Certifications that add value

Format with clear sections and emojis.
''';
    return _generateContentStreaming(prompt, apiKey4, onChunk);
  }

  // 🎯 Get Interview Prep (uses apiKey5)
  static Future<void> getInterviewPrepStreaming(String role, Function(String) onChunk) async {
    final prompt = '''
Provide comprehensive interview preparation guide for $role:
- Top 10 technical questions with brief answers
- Top 5 behavioral questions
- Coding challenges to practice (with platforms)
- Best resources for preparation
- Common mistakes to avoid
- Tips to crack the interview in Indian companies

Format with clear sections and emojis.
''';
    return _generateContentStreaming(prompt, apiKey5, onChunk);
  }

  // 💼 Get Live Jobs (uses apiKey6)
  static Future<void> getLiveJobsStreaming(String role, String location, Function(String) onChunk) async {
    final prompt = '''
Provide job search guide for $role in $location, India:
- Top companies currently hiring
- Best job portals to check (Naukri, LinkedIn, etc.)
- Expected salary range
- Required qualifications
- How to apply effectively
- Interview process overview
- Tips for freshers

Use emojis and clear formatting.
''';
    return _generateContentStreaming(prompt, apiKey6, onChunk);
  }

  // 💬 Chat (uses apiKey1)
  static Future<void> chatStreaming(String userMessage, Function(String) onChunk) async {
    final prompt = '''
You are an expert career guidance counselor for DIET college students in India.
Student question: $userMessage

Provide helpful, practical, and specific advice tailored to:
- Indian tech industry
- DIET curriculum and diploma holders
- Current job market (2025)
- Affordable learning resources

Be friendly, encouraging, and use emojis. Give actionable advice.
''';
    return _generateContentStreaming(prompt, apiKey1, onChunk);
  }
}
