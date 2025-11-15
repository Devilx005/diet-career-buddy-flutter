import 'package:flutter/material.dart';
import 'gemini_service.dart';

class JobsDashboard extends StatefulWidget {
  @override
  _JobsDashboardState createState() => _JobsDashboardState();
}

class _JobsDashboardState extends State<JobsDashboard> {
  String _content = '';
  bool _isLoading = false;
  DateTime? _lastRequestTime;
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  static const int COOLDOWN_SECONDS = 3;

  Future<void> _generateContent() async {
    if (_roleController.text.trim().isEmpty || _cityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Please enter both job role and city'),
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
      await GeminiService.getLiveJobsStreaming(
        _roleController.text.trim(),
        _cityController.text.trim(),
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
                enabled: !_isLoading,
              ),
              SizedBox(height: 12),

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
                enabled: !_isLoading,
              ),
              SizedBox(height: 10),

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
                  onPressed: _isLoading
                      ? null
                      : () {
                    setState(() {
                      _cityController.text = city;
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
                    Text('⏳ Searching...'),
                  ],
                )
                    : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search, size: 20),
                    SizedBox(width: 8),
                    Text('🔍 Search Jobs'),
                  ],
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLoading ? Colors.grey : Colors.teal,
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
                    color: Colors.teal.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: SelectableText(
                  _content.isEmpty
                      ? '💼 Find Your Next Job\n\n'
                      'Enter a role and city to get:\n\n'
                      '✅ Top companies hiring\n'
                      '✅ Best job portals\n'
                      '✅ Salary ranges\n'
                      '✅ Required qualifications\n'
                      '✅ Application tips'
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
