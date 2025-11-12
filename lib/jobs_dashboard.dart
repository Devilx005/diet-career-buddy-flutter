import 'package:flutter/material.dart';
import 'gemini_service.dart';

class JobsDashboard extends StatefulWidget {
  @override
  _JobsDashboardState createState() => _JobsDashboardState();
}

class _JobsDashboardState extends State<JobsDashboard> {
  String _content = '';
  bool _isLoading = false;
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  Future<void> _generateContent() async {
    if (_roleController.text.trim().isEmpty || _cityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter both job role and city')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _content = '';
    });

    await GeminiService.getLiveJobsStreaming(
        _roleController.text.trim(),
        _cityController.text.trim(),
            (chunk) {
          setState(() {
            _content = chunk;
          });
        }
    );

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _roleController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('💼 Live Jobs'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Job Role Search Field
            TextField(
              controller: _roleController,
              decoration: InputDecoration(
                hintText: 'Enter job role (e.g., Software Developer)',
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.work, color: Colors.teal),
                filled: true,
                fillColor: Color(0xFF2D2D2D),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.teal, width: 2),
                ),
              ),
            ),
            SizedBox(height: 12),

            // City Search Field
            TextField(
              controller: _cityController,
              decoration: InputDecoration(
                hintText: 'Enter city (e.g., Bangalore, Mumbai)',
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.location_city, color: Colors.teal),
                filled: true,
                fillColor: Color(0xFF2D2D2D),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.teal, width: 2),
                ),
              ),
            ),
            SizedBox(height: 10),

            // Suggested roles chips
            Text('Popular Roles:', style: TextStyle(fontSize: 12, color: Colors.grey)),
            SizedBox(height: 5),
            Wrap(
              spacing: 8,
              children: [
                'Software Developer',
                'Data Analyst',
                'Frontend Developer',
                'Full Stack Developer',
                'DevOps Engineer',
              ].map((role) => ActionChip(
                label: Text(role, style: TextStyle(fontSize: 11)),
                backgroundColor: Color(0xFF2D2D2D),
                onPressed: () {
                  setState(() {
                    _roleController.text = role;
                  });
                },
              )).toList(),
            ),
            SizedBox(height: 10),

            // Suggested cities chips
            Text('Popular Cities:', style: TextStyle(fontSize: 12, color: Colors.grey)),
            SizedBox(height: 5),
            Wrap(
              spacing: 8,
              children: [
                'Bangalore',
                'Mumbai',
                'Pune',
                'Hyderabad',
                'Delhi',
                'Chennai',
                'Kolkata',
              ].map((city) => ActionChip(
                label: Text(city, style: TextStyle(fontSize: 11)),
                backgroundColor: Color(0xFF2D2D2D),
                onPressed: () {
                  setState(() {
                    _cityController.text = city;
                  });
                },
              )).toList(),
            ),
            SizedBox(height: 10),

            ElevatedButton(
              onPressed: _isLoading ? null : _generateContent,
              child: Text(_isLoading ? '⏳ Searching...' : '🔍 Search Jobs'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
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
