import 'package:flutter/material.dart';
import 'gemini_service.dart';

class TechDashboard extends StatefulWidget {
  @override
  _TechDashboardState createState() => _TechDashboardState();
}

class _TechDashboardState extends State<TechDashboard> {
  String _content = '';
  bool _isLoading = false;

  Future<void> _generateContent() async {
    setState(() {
      _isLoading = true;
      _content = '';
    });

    await GeminiService.getTechCareersStreaming((chunk) {
      setState(() {
        _content = chunk;
      });
    });

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('💼 Tech Careers'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _generateContent,
              child: Text(_isLoading ? '⏳ Generating...' : '🚀 Generate Career Guide'),
              style: ElevatedButton.styleFrom(
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
