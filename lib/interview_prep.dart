import 'package:flutter/material.dart';
import 'gemini_service.dart';

class InterviewPrep extends StatefulWidget {
  @override
  _InterviewPrepState createState() => _InterviewPrepState();
}

class _InterviewPrepState extends State<InterviewPrep> {
  String _content = '';
  bool _isLoading = false;
  DateTime? _lastRequestTime;
  final TextEditingController _roleController = TextEditingController();

  static const int COOLDOWN_SECONDS = 3;

  Future<void> _generateContent() async {
    if (_roleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Please enter a job role'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⏳ Please wait for current request to complete'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest.inSeconds < COOLDOWN_SECONDS) {
        final waitTime = COOLDOWN_SECONDS - timeSinceLastRequest.inSeconds;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⏰ Please wait $waitTime more seconds'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _content = '';
      _lastRequestTime = DateTime.now();
    });

    try {
      await GeminiService.getInterviewPrepStreaming(
        _roleController.text.trim(),
            (chunk) {
          if (mounted) {
            setState(() {
              _content = chunk;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _content = '❌ Error: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (_lastRequestTime != null)
                Container(
                  padding: EdgeInsets.all(8),
                  margin: EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ℹ️ Wait 3 seconds between requests to avoid rate limits',
                          style: TextStyle(color: Colors.blue, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),

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
                enabled: !_isLoading,
                onSubmitted: (_) => _generateContent(),
              ),
              SizedBox(height: 10),

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
                  onPressed: _isLoading
                      ? null
                      : () {
                    setState(() {
                      _roleController.text = role;
                    });
                  },
                )).toList(),
              ),
              SizedBox(height: 10),

              ElevatedButton(
                onPressed: _isLoading ? null : _generateContent,
                child: _isLoading
                    ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('⏳ Preparing...'),
                  ],
                )
                    : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.rocket_launch, size: 20),
                    SizedBox(width: 8),
                    Text('🚀 Get Interview Prep'),
                  ],
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLoading ? Colors.grey : Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: _isLoading ? 0 : 4,
                ),
              ),

              SizedBox(height: 20),

              Container(
                constraints: BoxConstraints(minHeight: 300),
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: SelectableText(
                  _content.isEmpty
                      ? '🎯 Interview Preparation\n\n'
                      'Enter a job role to get:\n\n'
                      '✅ Top technical questions\n'
                      '✅ Behavioral questions\n'
                      '✅ Coding challenges\n'
                      '✅ Preparation resources\n'
                      '✅ Common mistakes to avoid'
                      : _content,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: _content.isEmpty ? Colors.grey : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
