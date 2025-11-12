import 'package:flutter/material.dart';
import 'gemini_service.dart';

class InterviewPrep extends StatefulWidget {
  @override
  _InterviewPrepState createState() => _InterviewPrepState();
}

class _InterviewPrepState extends State<InterviewPrep> {
  String _content = '';
  bool _isLoading = false;
  final TextEditingController _roleController = TextEditingController();

  Future<void> _generateContent() async {
    if (_roleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a job role')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _content = '';
    });

    await GeminiService.getInterviewPrepStreaming(_roleController.text.trim(), (chunk) {
      setState(() {
        _content = chunk;
      });
    });

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _roleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🎯 Interview Preparation'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search TextField
            TextField(
              controller: _roleController,
              decoration: InputDecoration(
                hintText: 'Enter job role (e.g., Frontend Developer)',
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.search, color: Colors.red),
                filled: true,
                fillColor: Color(0xFF2D2D2D),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red, width: 2),
                ),
              ),
              onSubmitted: (_) => _generateContent(),
            ),
            SizedBox(height: 10),

            // Suggested roles chips
            Wrap(
              spacing: 8,
              children: [
                'Software Engineer',
                'Frontend Developer',
                'Backend Developer',
                'Full Stack Developer',
                'Data Analyst',
                'DevOps Engineer',
                'QA Engineer',
                'Product Manager',
              ].map((role) => ActionChip(
                label: Text(role, style: TextStyle(fontSize: 12)),
                backgroundColor: Color(0xFF2D2D2D),
                onPressed: () {
                  setState(() {
                    _roleController.text = role;
                  });
                },
              )).toList(),
            ),
            SizedBox(height: 10),

            ElevatedButton(
              onPressed: _isLoading ? null : _generateContent,
              child: Text(_isLoading ? '⏳ Preparing...' : '🚀 Get Interview Prep'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  _content,
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
