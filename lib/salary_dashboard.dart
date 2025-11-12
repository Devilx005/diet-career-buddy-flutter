import 'package:flutter/material.dart';
import 'gemini_service.dart';

class SalaryDashboard extends StatefulWidget {
  @override
  _SalaryDashboardState createState() => _SalaryDashboardState();
}

class _SalaryDashboardState extends State<SalaryDashboard> {
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

    await GeminiService.getSalaryInfoStreaming(_roleController.text.trim(), (chunk) {
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
        title: Text('💰 Salary Information'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search TextField
            TextField(
              controller: _roleController,
              decoration: InputDecoration(
                hintText: 'Enter job role (e.g., Software Developer)',
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.search, color: Colors.green),
                filled: true,
                fillColor: Color(0xFF2D2D2D),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.green, width: 2),
                ),
              ),
              onSubmitted: (_) => _generateContent(),
            ),
            SizedBox(height: 10),

            // Suggested roles chips
            Wrap(
              spacing: 8,
              children: [
                'Software Developer',
                'Data Analyst',
                'Web Developer',
                'Mobile Developer',
                'DevOps Engineer',
                'Cloud Engineer',
                'UI/UX Designer',
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
              child: Text(_isLoading ? '⏳ Generating...' : '🚀 Get Salary Info'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
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
