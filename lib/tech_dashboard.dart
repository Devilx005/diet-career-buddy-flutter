import 'package:flutter/material.dart';
import 'gemini_service.dart';

class TechDashboard extends StatefulWidget {
  @override
  _TechDashboardState createState() => _TechDashboardState();
}

class _TechDashboardState extends State<TechDashboard> {
  String _content = '';
  bool _isLoading = false;
  DateTime? _lastRequestTime;

  static const int COOLDOWN_SECONDS = 3;

  Future<void> _generateContent() async {
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
      await GeminiService.getTechCareersStreaming((chunk) {
        if (mounted) {
          setState(() {
            _content = chunk;
          });
        }
      });
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('💼 Tech Careers'),
        backgroundColor: Colors.blue,
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
                    Text('⏳ Generating...'),
                  ],
                )
                    : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.rocket_launch, size: 20),
                    SizedBox(width: 8),
                    Text('🚀 Generate Career Guide'),
                  ],
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLoading ? Colors.grey : Colors.blue,
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
                    color: Colors.blue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: SelectableText(
                  _content.isEmpty
                      ? '💼 Explore Tech Careers\n\n'
                      'Click the button above to discover:\n\n'
                      '✅ Top 10 trending tech roles\n'
                      '✅ Average salaries in India\n'
                      '✅ Required skills for each\n'
                      '✅ Career growth potential\n'
                      '✅ Best companies hiring'
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
