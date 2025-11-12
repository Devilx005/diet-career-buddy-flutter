import 'package:flutter/material.dart';
import 'gemini_service.dart';

class LearningDashboard extends StatefulWidget {
  @override
  _LearningDashboardState createState() => _LearningDashboardState();
}

class _LearningDashboardState extends State<LearningDashboard> {
  String _content = '';
  bool _isLoading = false;
  final TextEditingController _domainController = TextEditingController();

  Future<void> _generateContent() async {
    if (_domainController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a domain or technology')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _content = '';
    });

    await GeminiService.getLearningPathStreaming(_domainController.text.trim(), (chunk) {
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
    _domainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📚 Learning Paths'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search TextField
            TextField(
              controller: _domainController,
              decoration: InputDecoration(
                hintText: 'Enter domain/technology (e.g., Flutter, Python)',
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.search, color: Colors.orange),
                filled: true,
                fillColor: Color(0xFF2D2D2D),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.orange, width: 2),
                ),
              ),
              onSubmitted: (_) => _generateContent(),
            ),
            SizedBox(height: 10),

            // Suggested domains chips
            Wrap(
              spacing: 8,
              children: [
                'Full Stack Development',
                'Data Science',
                'Machine Learning',
                'Flutter',
                'React.js',
                'Python',
                'Cybersecurity',
                'Cloud Computing',
                'DevOps',
                'Blockchain',
              ].map((domain) => ActionChip(
                label: Text(domain, style: TextStyle(fontSize: 12)),
                backgroundColor: Color(0xFF2D2D2D),
                onPressed: () {
                  setState(() {
                    _domainController.text = domain;
                  });
                },
              )).toList(),
            ),
            SizedBox(height: 10),

            ElevatedButton(
              onPressed: _isLoading ? null : _generateContent,
              child: Text(_isLoading ? '⏳ Generating...' : '🚀 Get Learning Path'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
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
