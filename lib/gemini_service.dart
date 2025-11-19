import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class GeminiService {
  // Your existing API key getters...
  static String get apiKey1 => dotenv.env['API_KEY_1'] ?? '';
  static String get apiKey2 => dotenv.env['API_KEY_2'] ?? '';
  static String get apiKey3 => dotenv.env['API_KEY_3'] ?? '';
  static String get apiKey4 => dotenv.env['API_KEY_4'] ?? '';
  static String get apiKey5 => dotenv.env['API_KEY_5'] ?? '';
  static String get apiKey6 => dotenv.env['API_KEY_6'] ?? '';
  static String get geminiapi => dotenv.env['GEMINI_API'] ?? '';

  static String _sanitizeForWeb(String text) {
    if (!kIsWeb) return text;

    String sanitized = text
        .replaceAll('\u0000', '')
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '')
        .replaceAll(RegExp(r'\r\n|\r'), '\n')
        .trim();

    return sanitized;
  }

  static Future<void> _generateContentStreaming(
      String prompt,
      String apiKey,
      Function(String) onChunk,
      ) async {
    if (apiKey.isEmpty) {
      onChunk('⚠️ API key not configured. Please check your .env file.');
      return;
    }

    try {
      final String baseUrl;
      if (kIsWeb) {
        final encodedUrl = Uri.encodeComponent(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey'
        );
        baseUrl = 'https://api.allorigins.win/raw?url=$encodedUrl';
        print('🌐 Using CORS proxy for web');
      } else {
        baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey';
        print('📱 Direct API call for mobile');
      }

      final url = Uri.parse(baseUrl);
      print('🚀 Making request...');

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
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout after 30 seconds');
        },
      );

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data != null &&
            data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {

          final rawText = data['candidates'][0]['content']['parts'][0]['text'] ?? 'No response';

          print('✅ Response received: ${rawText.length} characters');

          final fullText = _sanitizeForWeb(rawText);

          if (fullText.isEmpty) {
            onChunk('⚠️ Empty response received. Please try again.');
            return;
          }

          await _streamText(fullText, onChunk);
        } else {
          onChunk('⚠️ No response generated. Please try again.');
        }
      } else if (response.statusCode == 429) {
        onChunk('⚠️ Rate limit reached. Please wait a moment and try again.');
      } else if (response.statusCode == 503) {
        onChunk('⚠️ Service temporarily unavailable. Please try again.');
      } else {
        try {
          final errorData = jsonDecode(response.body);
          final errorMsg = errorData['error']?['message'] ?? 'Unknown error';
          onChunk('❌ Error ${response.statusCode}: $errorMsg');
          print('❌ Error response: ${response.body}');
        } catch (e) {
          onChunk('❌ Error ${response.statusCode}: ${response.body}');
          print('❌ Raw error: ${response.body}');
        }
      }
    } catch (e, stackTrace) {
      final errorMsg = e.toString();
      onChunk('❌ Error: $errorMsg');
      print('❌ Exception: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // ✅ ADD THIS METHOD
  static Future<void> _streamText(String text, Function(String) onChunk) async {
    if (text.isEmpty) {
      onChunk('No content available');
      return;
    }

    try {
      if (kIsWeb) {
        final chunkSize = 100;

        for (int i = 0; i < text.length; i += chunkSize) {
          final end = (i + chunkSize < text.length) ? i + chunkSize : text.length;
          onChunk(text.substring(0, end));
          await Future.delayed(const Duration(milliseconds: 30));
        }

        onChunk(text);
      } else {
        final words = text.split(' ');
        String currentText = '';

        for (int i = 0; i < words.length; i++) {
          currentText += words[i] + ' ';
          onChunk(currentText);
          await Future.delayed(const Duration(milliseconds: 30));
        }
      }
    } catch (e) {
      print('❌ Streaming error: $e');
      onChunk(text);
    }
  }

  // Keep all your existing method signatures...
  static Future<void> getTechCareersStreaming(Function(String) onChunk) async {
    final prompt = '''List 10 trending tech careers for college students in India in 2025.
For each career, include:
- Job title
- Average salary in India (LPA)
- Required skills
- Career growth potential

Format as a clear, structured response with emojis.''';
    return _generateContentStreaming(prompt, apiKey1, onChunk);
  }

  static Future<void> getSalaryInfoStreaming(String role, Function(String) onChunk) async {
    final prompt = '''Provide detailed salary information for $role in India (2025):
- Fresher salary (0-1 years)
- Mid-level (3-5 years)
- Senior-level (8+ years)
- Top companies
- Location-wise breakdown

Show in INR (LPA). Use emojis.''';
    return _generateContentStreaming(prompt, apiKey2, onChunk);
  }

  static Future<void> getLearningPathStreaming(String domain, Function(String) onChunk) async {
    final prompt = '''Create a complete learning roadmap for $domain for Indian students:
- Beginner level (free courses)
- Intermediate topics
- Advanced specializations
- Best free resources
- Timeline
- Top certifications

Format clearly. Use emojis.''';
    return _generateContentStreaming(prompt, apiKey3, onChunk);
  }

  static Future<void> getDIETGuideStreaming(Function(String) onChunk) async {
    final prompt = '''Provide comprehensive career guidance for college students:
- Best career paths
- Further education options
- Job opportunities
- Salary expectations
- Skill development tips
- Certifications

Format with clear sections and emojis.''';
    return _generateContentStreaming(prompt, apiKey4, onChunk);
  }

  static Future<void> getInterviewPrepStreaming(String role, Function(String) onChunk) async {
    final prompt = '''Provide interview preparation guide for $role:
- Top 10 technical questions
- Top 5 behavioral questions
- Coding challenges
- Best resources
- Common mistakes
- Tips for Indian companies

Format with sections and emojis.''';
    return _generateContentStreaming(prompt, apiKey5, onChunk);
  }

  static Future<void> getLiveJobsStreaming(String role, String location, Function(String) onChunk) async {
    final prompt = '''Provide job search guide for $role in $location, India:
- Top companies hiring
- Best job portals
- Expected salary
- Required qualifications
- How to apply
- Interview process
- Tips for freshers

Use emojis.''';
    return _generateContentStreaming(prompt, apiKey6, onChunk);
  }

  static Future<void> chatStreaming(String userMessage, Function(String) onChunk) async {
    final prompt = '''You are an expert career guidance counselor for college students in India.

Student question: $userMessage

Provide helpful, practical advice tailored to:
- All industries (short overview)
- Current job market (2025)
- Affordable resources
- Tell them for more info visit our dashboards

Be friendly and use emojis.''';
    return _generateContentStreaming(prompt, geminiapi, onChunk);
  }
}
