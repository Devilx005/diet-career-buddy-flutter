import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'gemini_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _roleController = TextEditingController();

  String _overviewSection = '';
  String _mcqSection = '';
  String _resourcesSection = '';
  bool _loadingOverview = false;
  bool _loadingMCQ = false;
  bool _loadingResources = false;
  bool _isLoading = false;
  String? _selectedRole;

  @override
  void dispose() {
    _roleController.dispose();
    super.dispose();
  }

  void _downloadAndroidApk() {
    if (kIsWeb) {
      html.window.open('/assets/PathifyAi.apk', '_blank');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('APK download is available on the web version only.'),
        ),
      );
    }
  }

  void _startAnalysis() {
    final role = _selectedRole ?? _roleController.text.trim();
    if (role.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or select a job role')),
      );
      return;
    }

    setState(() {
      _loadingOverview = true;
      _loadingMCQ = true;
      _loadingResources = true;
      _overviewSection = '';
      _mcqSection = '';
      _resourcesSection = '';
      _isLoading = true;
    });

    // Overview/skills analysis (API 1)
    GeminiService.getInterviewOverviewStreaming(role, (text) {
      if (mounted) {
        setState(() {
          _overviewSection = text;
          _loadingOverview = false;
          _isLoading = _loadingOverview || _loadingMCQ || _loadingResources;
        });
      }
    });

    // MCQs (API 7)
    GeminiService.getInterviewMCQStreaming(role, (text) {
      if (mounted) {
        setState(() {
          _mcqSection = text;
          _loadingMCQ = false;
          _isLoading = _loadingOverview || _loadingMCQ || _loadingResources;
        });
      }
    });

    // Resources (API 8)
    GeminiService.getInterviewResourcesStreaming(role, (text) {
      if (mounted) {
        setState(() {
          _resourcesSection = text;
          _loadingResources = false;
          _isLoading = _loadingOverview || _loadingMCQ || _loadingResources;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Pathify AI Home'),
        backgroundColor: const Color(0xFF6366F1),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Web-only: Download Android App button
            if (kIsWeb)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _downloadAndroidApk,
                    icon: const Icon(Icons.android),
                    label: const Text(
                      'Download Android App (APK)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),

            // Role input section
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Enter Job Role:',
                      style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _roleController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Frontend Developer',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => setState(() => _selectedRole = null),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isLoading ? null : _startAnalysis,
                        child: _isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                            : const Text(
                          'Start Interview Analysis',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            if (_loadingOverview || _loadingMCQ || _loadingResources)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),

            if (_overviewSection.isNotEmpty ||
                _mcqSection.isNotEmpty ||
                _resourcesSection.isNotEmpty)
              Card(
                margin: const EdgeInsets.only(top: 16),
                color: const Color(0xFF2D2D2D),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Overview block
                      Text(
                        'Overview & Skills',
                        style: TextStyle(
                          color: Colors.indigo[100],
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _loadingOverview
                          ? const Text(
                        "Loading overview/skills...",
                        style: TextStyle(color: Colors.white70),
                      )
                          : SelectableText(
                        _overviewSection,
                        style: const TextStyle(color: Colors.white),
                      ),

                      const SizedBox(height: 20),

                      // MCQ block
                      Text(
                        'Sample MCQs',
                        style: TextStyle(
                          color: Colors.amber[200],
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _loadingMCQ
                          ? const Text(
                        "Loading MCQs...",
                        style: TextStyle(color: Colors.white70),
                      )
                          : SelectableText(
                        _mcqSection,
                        style: const TextStyle(color: Colors.white),
                      ),

                      const SizedBox(height: 20),

                      // Resources block
                      Text(
                        'Resources & Tips',
                        style: TextStyle(
                          color: Colors.lightGreen[200],
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _loadingResources
                          ? const Text(
                        "Loading resources...",
                        style: TextStyle(color: Colors.white70),
                      )
                          : SelectableText(
                        _resourcesSection,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
