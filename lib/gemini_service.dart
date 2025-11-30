import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class GeminiService {
  static String get apiKey1 => dotenv.env['API_KEY_1'] ?? '';
  static String get apiKey2 => dotenv.env['API_KEY_2'] ?? '';
  static String get apiKey3 => dotenv.env['API_KEY_3'] ?? '';
  static String get apiKey4 => dotenv.env['API_KEY_4'] ?? '';
  static String get apiKey5 => dotenv.env['API_KEY_5'] ?? '';
  static String get apiKey6 => dotenv.env['API_KEY_6'] ?? '';
  static String get geminiapi => dotenv.env['GEMINI_API'] ?? '';
  static String get groqapi => dotenv.env['GROQ_API_KEY'] ?? '';
  static String get cohereapi => dotenv.env['COHERE_API_KEY'] ?? '';
  static String get linkedinjobapi => dotenv.env['LINKEDIN_JOB_API_KEY'] ?? '';
  static String get apiKey7 => dotenv.env['API_KEY_7'] ?? '';
  static String get apiKey8 => dotenv.env['API_KEY_8'] ?? '';

  // Cache storage
  static final Map<String, CachedData> _cache = {};

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

      // Updated to latest stable Gemini Flash model
      const modelPath =
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

      if (kIsWeb) {
        final encodedUrl =
        Uri.encodeComponent('$modelPath?key=$apiKey');
        baseUrl = 'https://api.allorigins.win/raw?url=$encodedUrl';
      } else {
        baseUrl = '$modelPath?key=$apiKey';
      }

      final url = Uri.parse(baseUrl);
      final response = await http
          .post(
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
      )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null &&
            data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          final rawText =
              data['candidates'][0]['content']['parts'][0]['text'] ??
                  'No response';
          final fullText = _sanitizeForWeb(rawText);
          if (fullText.isNotEmpty) {
            await _streamText(fullText, onChunk);
          }
        }
      } else if (response.statusCode == 429) {
        onChunk('⚠️ Rate limit reached.');
      } else {
        onChunk('❌ Gemini Error: ${response.statusCode}');
      }
    } catch (e) {
      onChunk('❌ Error: $e');
    }
  }

  static Future<void> _groqChatStreaming(
      String prompt,
      String modelId,
      Function(String) onChunk,
      ) async {
    final apiKey = groqapi;

    if (apiKey.isEmpty) {
      onChunk('⚠️ Groq API key not configured.');
      return;
    }

    try {
      final url =
      Uri.parse('https://api.groq.com/openai/v1/chat/completions');

      final response = await http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': modelId,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
          'max_tokens': 2048,
        }),
      )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          final text =
              data['choices'][0]['message']['content'] ?? 'No response';
          final fullText = _sanitizeForWeb(text);
          if (fullText.isNotEmpty) {
            await _streamText(fullText, onChunk);
          }
        }
      } else if (response.statusCode == 401) {
        onChunk(
            '❌ Groq API key is invalid. Please check your key.');
      } else if (response.statusCode == 429) {
        onChunk(
            '⚠️ Groq rate limit reached. Try again later.');
      } else {
        onChunk('❌ Groq Error: ${response.statusCode}');
      }
    } catch (e) {
      onChunk('❌ Groq Error: $e');
    }
  }

  static Future<void> _cohereChatStreaming(
      String prompt,
      Function(String) onChunk,
      ) async {
    final apiKey = cohereapi;

    if (apiKey.isEmpty) {
      onChunk('⚠️ Cohere API key not configured.');
      return;
    }

    try {
      final url = Uri.parse('https://api.cohere.ai/v1/chat');

      final response = await http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'message': prompt,
          'model': 'command-r-08-2024',
          'temperature': 0.7,
        }),
      )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['text'] != null) {
          final text = data['text'] ?? 'No response';
          final fullText = _sanitizeForWeb(text);
          if (fullText.isNotEmpty) {
            await _streamText(fullText, onChunk);
          }
        }
      } else if (response.statusCode == 401) {
        onChunk(
            '❌ Cohere API key is invalid. Please check your key.');
      } else {
        onChunk('❌ Cohere Error: ${response.statusCode}');
      }
    } catch (e) {
      onChunk('❌ Cohere Error: $e');
    }
  }

  static Future<void> _streamText(
      String text, Function(String) onChunk) async {
    if (text.isEmpty) return;

    try {
      if (kIsWeb) {
        const chunkSize = 100;
        for (int i = 0; i < text.length; i += chunkSize) {
          final end =
          (i + chunkSize < text.length) ? i + chunkSize : text.length;
          onChunk(text.substring(0, end));
          await Future.delayed(const Duration(milliseconds: 30));
        }
        onChunk(text);
      } else {
        final words = text.split(' ');
        String currentText = '';
        for (int i = 0; i < words.length; i++) {
          currentText += '${words[i]} ';
          onChunk(currentText);
          await Future.delayed(const Duration(milliseconds: 30));
        }
      }
    } catch (_) {
      onChunk(text);
    }
  }

  static Future<void> chatStreamingWithModel(
      String userMessage,
      String model,
      Function(String) onChunk,
      ) async {
    final prompt = '''You are an expert career guidance counselor for college students in India.

Student question: $userMessage

Provide helpful, practical advice tailored to:
- All industries (short overview)
- Current job market (2025)
- Affordable resources
- Tell them for more info visit our dashboards

Be friendly and use emojis.''';

    switch (model) {
      case 'Llama 3.1 70B':
        await _groqChatStreaming(
            prompt, 'llama-3.3-70b-versatile', onChunk);
        break;
      case 'Mixtral 8x7B':
        await _groqChatStreaming(
            prompt, 'mixtral-8x7b-32768', onChunk);
        break;
      case 'Gemma 2 9B':
        await _groqChatStreaming(
            prompt, 'gemma2-9b-it', onChunk);
        break;
      case 'Command-R':
        await _cohereChatStreaming(prompt, onChunk);
        break;
      case 'Gemini 1.5 Flash':
      default:
        await _generateContentStreaming(prompt, geminiapi, onChunk);
    }
  }

  static Future<void> getTechCareersStreaming(
      Function(String) onChunk) async {
    const cacheKey = 'tech_careers_2025';

    if (_cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey]!;
      if (DateTime.now()
          .difference(cached.timestamp) <
          const Duration(hours: 24)) {
        await _streamText(cached.data, onChunk);
        return;
      }
    }

    final prompt = '''List 10 trending tech careers for college students in India in 2025.
For each career, include:
- Job title
- Average salary in India (LPA)
- Required skills
- Career growth potential

Format as a clear, structured response with emojis.''';

    String fullResponse = '';
    await _groqChatStreaming(
        prompt, 'llama-3.3-70b-versatile', (text) {
      fullResponse = text;
      onChunk(text);
    });

    _cache[cacheKey] =
        CachedData(fullResponse, DateTime.now());
  }

  static Future<void> getSalaryInfoStreaming(
      String role, Function(String) onChunk) async {
    final prompt = '''Provide detailed salary information for $role in India (2025):
- Fresher salary (0-1 years)
- Mid-level (3-5 years)
- Senior-level (8+ years)
- Top companies
- Location-wise breakdown

Show in INR (LPA). Use emojis.''';

    return _groqChatStreaming(
        prompt, 'llama-3.3-70b-versatile', onChunk);
  }

  static Future<void> getLearningPathStreaming(
      String domain, Function(String) onChunk) async {
    final prompt = '''Create a complete learning roadmap for $domain for Indian students:
- Beginner level (free courses)
- Intermediate topics
- Advanced specializations
- Best free resources
- Timeline
- Top certifications

Format clearly. Use emojis.''';
    return _cohereChatStreaming(prompt, onChunk);
  }

  static Future<void> getDIETGuideStreaming(
      Function(String) onChunk) async {
    const cacheKey = 'diet_guide_2025';

    if (_cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey]!;
      if (DateTime.now()
          .difference(cached.timestamp) <
          const Duration(days: 7)) {
        await _streamText(cached.data, onChunk);
        return;
      }
    }

    final prompt = '''Provide comprehensive career guidance for college students:
- Best career paths
- Further education options
- Job opportunities
- Salary expectations
- Skill development tips
- Certifications

Format with clear sections and emojis.''';

    String fullResponse = '';
    await _cohereChatStreaming(prompt, (text) {
      fullResponse = text;
      onChunk(text);
    });

    _cache[cacheKey] =
        CachedData(fullResponse, DateTime.now());
  }

  static Future<void> getInterviewAnalysisStreaming(
      String role,
      Function(Map<String, String>) onSections,
      ) async {
    final prompt = '''Analyze interview preparation for $role position in India. Provide response in these exact sections:

**OVERVIEW**
Give 4-line overview and list 5 essential skills. Use emojis.

**SAMPLE_MCQS**
Create 3 MCQ questions with 4 options (A-D) and correct answer.

**RESOURCES**
List 2 free online resources with links and 1 actionable tip.

Format clearly with section headers.''';

    String fullResponse = '';

    await _groqChatStreaming(
        prompt, 'llama-3.3-70b-versatile', (text) {
      fullResponse = text;
    });

    final sections = _parseInterviewSections(fullResponse);
    onSections(sections);
  }

  static Map<String, String> _parseInterviewSections(String text) {
    final sections = <String, String>{};

    final overviewMatch = RegExp(
        r'\*\*OVERVIEW\*\*(.*?)(?=\*\*SAMPLE_MCQS\*\*|$)',
        dotAll: true)
        .firstMatch(text);
    final mcqMatch = RegExp(
        r'\*\*SAMPLE_MCQS\*\*(.*?)(?=\*\*RESOURCES\*\*|$)',
        dotAll: true)
        .firstMatch(text);
    final resourcesMatch =
    RegExp(r'\*\*RESOURCES\*\*(.*?)$', dotAll: true)
        .firstMatch(text);

    sections['overview'] =
        overviewMatch?.group(1)?.trim() ?? '';
    sections['mcq'] = mcqMatch?.group(1)?.trim() ?? '';
    sections['resources'] =
        resourcesMatch?.group(1)?.trim() ?? '';

    return sections;
  }

  static Future<void> getInterviewOverviewStreaming(
      String role, Function(String) onChunk) async {
    final prompt =
    '''Give a 4-line overview and list 5 essential skills for a $role interview in India. Use emojis.''';
    return _generateContentStreaming(prompt, apiKey5, onChunk);
  }

  static Future<void> getInterviewMCQStreaming(
      String role, Function(String) onChunk) async {
    final prompt =
    '''Create 3 MCQ questions with 4 options and the correct answer (in options) for a $role interview.''';
    return _generateContentStreaming(prompt, apiKey7, onChunk);
  }

  static Future<void> getInterviewResourcesStreaming(
      String role, Function(String) onChunk) async {
    final prompt =
    '''List 2 free, high-quality online resources (with links) for $role interview preparation and 1 top actionable tip.''';
    return _generateContentStreaming(prompt, apiKey8, onChunk);
  }

  static Future<void> getInterviewMCQByDifficulty(
      String role,
      String difficulty,
      Function(String) onChunk,
      ) async {
    final prompt = '''Generate 5 $difficulty level MCQ interview questions for $role position in India.

For each question, provide:
- Question text
- 4 options (A, B, C, D)
- Correct answer (mention which option letter)

Format each question EXACTLY like this:
Q1: [Question text here]
A) [First option]
B) [Second option]
C) [Third option]
D) [Fourth option]
Correct: A

Q2: [Question text here]
A) [First option]
B) [Second option]
C) [Third option]
D) [Fourth option]
Correct: B

Continue for all 5 questions. Make sure difficulty matches the $difficulty level.''';

    return _generateContentStreaming(prompt, apiKey7, onChunk);
  }

  static Future<List<Map<String, dynamic>>> getLinkedInJobs(
      String role, String location) async {
    try {
      final apiKey = linkedinjobapi;
      if (apiKey.isEmpty) {
        print('❌ NO API KEY');
        return [];
      }

      final url = Uri.parse(
          'https://linkedin-job-search-api.p.rapidapi.com/active-jb-7d?'
              'limit=10&'
              'offset=0&'
              'title_filter=${Uri.encodeComponent(role)}&'
              'location_filter=${Uri.encodeComponent(location)}&'
              'description_type=text');

      final response = await http
          .get(
        url,
        headers: {
          'X-RapidAPI-Key': apiKey,
          'X-RapidAPI-Host':
          'linkedin-job-search-api.p.rapidapi.com',
        },
      )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List && data.isNotEmpty) {
          final jobs = <Map<String, dynamic>>[];
          for (var job in data) {
            final locations = job['locations_raw'] ?? [];
            String locationStr = location;
            if (locations.isNotEmpty && locations[0] is Map) {
              locationStr = locations[0]['address']
              ?['addressLocality'] ??
                  location;
            }

            final desc = job['description']?.toString() ??
                'No description available';

            jobs.add({
              'title': job['title'] ?? 'Unknown Position',
              'company':
              job['organization'] ?? 'Unknown Company',
              'location': locationStr,
              'salary': 'Not specified',
              'type': 'Full-time',
              'description': desc.length > 150
                  ? '${desc.substring(0, 150)}...'
                  : desc,
              'applyLink':
              job['organization_url'] ?? '',
              'posted':
              job['date_posted'] ?? 'Recently',
            });
          }

          return jobs;
        }
      }

      return [];
    } catch (e) {
      print('❌ EXCEPTION: $e');
      return [];
    }
  }

  static Future<void> chatStreaming(
      String userMessage, Function(String) onChunk) =>
      chatStreamingWithModel(
          userMessage, 'Gemini 1.5 Flash', onChunk);
}

class CachedData {
  final String data;
  final DateTime timestamp;
  CachedData(this.data, this.timestamp);
}
