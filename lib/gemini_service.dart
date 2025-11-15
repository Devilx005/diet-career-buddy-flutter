import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  // 🔑 Get API keys from .env
  static String get apiKey1 => dotenv.env['API_KEY_1'] ?? '';
  static String get apiKey2 => dotenv.env['API_KEY_2'] ?? '';
  static String get apiKey3 => dotenv.env['API_KEY_3'] ?? '';
  static String get apiKey4 => dotenv.env['API_KEY_4'] ?? '';
  static String get apiKey5 => dotenv.env['API_KEY_5'] ?? '';
  static String get apiKey6 => dotenv.env['API_KEY_6'] ?? '';
  static String get geminiapi => dotenv.env['GEMINI_API'] ?? '';

  // ✅ Generate content with simulated streaming
  static Future<void> _generateContentStreaming(
      String prompt,
      String apiKey,
      Function(String) onChunk,
      ) async {
    try {
      // ✅ FIXED: Use stable model instead of experimental
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey'
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

        if (data != null &&
            data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {

          final fullText = data['candidates'][0]['content']['parts'][0]['text'] ?? 'No response';
          await _streamText(fullText, onChunk);
        } else {
          onChunk('⚠️ No response generated. Please try again.');
        }
      } else if (response.statusCode == 429) {
        onChunk('⚠️ Rate limit reached. Please wait a moment and try again.');
      } else if (response.statusCode == 503) {
        onChunk('⚠️ Service temporarily unavailable. Please try again.');
      } else {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData['error']?['message'] ?? 'Unknown error';
        onChunk('Error ${response.statusCode}: $errorMsg');
      }
    } catch (e) {
      onChunk('Error: ${e.toString()}');
      print('❌ Gemini API Error: $e');
    }
  }

  static Future<void> _streamText(String text, Function(String) onChunk) async {
    final words = text.split(' ');
    String currentText = '';

    for (int i = 0; i < words.length; i++) {
      currentText += words[i] + ' ';
      onChunk(currentText);
      await Future.delayed(Duration(milliseconds: 30));
    }
  }

  // 💼 Tech Careers - uses apiKey1
  static Future<void> getTechCareersStreaming(Function(String) onChunk) async {
    final prompt = '''List 10 trending tech careers for  college students in India in 2025.
For each career, include: Job title, Average salary in India (LPA), Required skills, Career growth potential.
Format as a clear, structured response with emojis.''';
    return _generateContentStreaming(prompt, apiKey1, onChunk);
  }

  // 💰 Salary Info - uses apiKey2
  static Future<void> getSalaryInfoStreaming(String role, Function(String) onChunk) async {
    final prompt = '''Provide detailed salary information for $role in India (2025):
Fresher salary (0-1 years), Mid-level (3-5 years), Senior-level (8+ years), Top companies, Location-wise breakdown.
Show in INR (LPA). Use emojis.''';
    return _generateContentStreaming(prompt, apiKey2, onChunk);
  }

  // 📚 Learning Paths - uses apiKey3
  static Future<void> getLearningPathStreaming(String domain, Function(String) onChunk) async {
    final prompt = '''Create a complete learning roadmap for $domain for Indian students:
Beginner level (free courses), Intermediate topics, Advanced specializations, Best free resources, Timeline, Top certifications.
Format clearly. Use emojis.''';
    return _generateContentStreaming(prompt, apiKey3, onChunk);
  }

  // 🎓 DIET Guide - uses apiKey4
  static Future<void> getDIETGuideStreaming(Function(String) onChunk) async {
    final prompt = '''Provide comprehensive career guidance for DIET students:
Best career paths, Further education options, Job opportunities, Salary expectations, Skill development tips, Certifications.
Format with clear sections and emojis.''';
    return _generateContentStreaming(prompt, apiKey4, onChunk);
  }

  // 🎯 Interview Prep - uses apiKey5
  static Future<void> getInterviewPrepStreaming(String role, Function(String) onChunk) async {
    final prompt = '''Provide interview preparation guide for $role:
Top 10 technical questions, Top 5 behavioral questions, Coding challenges, Best resources, Common mistakes, Tips for Indian companies.
Format with sections and emojis.''';
    return _generateContentStreaming(prompt, apiKey5, onChunk);
  }

  // 💼 Jobs - uses apiKey6
  static Future<void> getLiveJobsStreaming(String role, String location, Function(String) onChunk) async {
    final prompt = '''Provide job search guide for $role in $location, India:
Top companies hiring, Best job portals, Expected salary, Required qualifications, How to apply, Interview process, Tips for freshers.
Use emojis.''';
    return _generateContentStreaming(prompt, apiKey6, onChunk);
  }

  // 💬 Chat - uses geminiapi
  static Future<void> chatStreaming(String userMessage, Function(String) onChunk) async {
    final prompt = '''You are an expert career guidance counselor for  college students in India.
Student question: $userMessage

Provide helpful, practical advice tailored to: all industries in short overview, Current job market (2025), Affordable resources, and tell them for more ifo visit our dashboards.
Be friendly and use emojis.''';
    return _generateContentStreaming(prompt, geminiapi, onChunk);
  }
}
