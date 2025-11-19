import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'gemini_service.dart';

class SalaryDashboard extends StatefulWidget {
  const SalaryDashboard({Key? key}) : super(key: key);

  @override
  State<SalaryDashboard> createState() => _SalaryDashboardState();
}

class _SalaryDashboardState extends State<SalaryDashboard> {
  String _content = '';
  bool _isLoading = false;
  DateTime? _lastRequestTime;
  final TextEditingController _roleController = TextEditingController();

  static const int COOLDOWN_SECONDS = 3;

  Future<void> _generateContent() async {
    // Input validation
    if (_roleController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Please enter a job role'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Loading check
    if (_isLoading) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⏳ Please wait for current request to complete'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Cooldown check
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest.inSeconds < COOLDOWN_SECONDS) {
        final waitTime = COOLDOWN_SECONDS - timeSinceLastRequest.inSeconds;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⏰ Please wait $waitTime more seconds'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _content = 'Loading...';
      _lastRequestTime = DateTime.now();
    });

    try {
      print('🚀 Starting salary info request for: ${_roleController.text.trim()}');

      await GeminiService.getSalaryInfoStreaming(
        _roleController.text.trim(),
            (chunk) {
          if (mounted) {
            setState(() {
              _content = chunk;
            });
          }
        },
      );

      print('✅ Salary info request completed');
    } catch (e, stackTrace) {
      print('❌ Salary Dashboard Error: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _content = '❌ Error loading salary information.\n\n'
              'Please try again or select a different role.\n\n'
              'Error details: ${e.toString()}';
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
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.attach_money, color: Colors.white, size: 32),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '💰 Salary Information',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Rate limit warning
            if (_lastRequestTime != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, color: Colors.blue, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ℹ️ Wait 3 seconds between requests to avoid rate limits',
                        style: TextStyle(color: Colors.blue, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            // Text field
            TextField(
              controller: _roleController,
              decoration: InputDecoration(
                hintText: 'Enter job role (e.g., Software Developer)',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.green),
                filled: true,
                fillColor: const Color(0xFF2D2D2D),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.green, width: 2),
                ),
              ),
              enabled: !_isLoading,
              onSubmitted: (_) => _generateContent(),
            ),
            const SizedBox(height: 12),

            // Quick select chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Software Developer',
                'Data Analyst',
                'Web Developer',
                'Mobile Developer',
                'DevOps Engineer',
                'Cloud Engineer',
                'UI/UX Designer',
              ].map((role) => ActionChip(
                label: Text(role, style: const TextStyle(fontSize: 12)),
                backgroundColor: const Color(0xFF2D2D2D),
                onPressed: _isLoading
                    ? null
                    : () {
                  if (mounted) {
                    setState(() {
                      _roleController.text = role;
                    });
                  }
                },
              )).toList(),
            ),
            const SizedBox(height: 16),

            // Generate button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _generateContent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLoading ? Colors.grey : Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: _isLoading ? 0 : 4,
                ),
                child: _isLoading
                    ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('⏳ Generating...', style: TextStyle(fontSize: 16)),
                  ],
                )
                    : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.monetization_on, size: 20),
                    SizedBox(width: 8),
                    Text('🚀 Get Salary Info', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Response container
            Container(
              constraints: const BoxConstraints(minHeight: 300),
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: SelectableText(
                _content.isEmpty
                    ? '💰 Discover Salary Insights\n\n'
                    'Enter a job role to get:\n\n'
                    '✅ Fresher salary ranges\n'
                    '✅ Mid-level compensation\n'
                    '✅ Senior-level packages\n'
                    '✅ Top paying companies\n'
                    '✅ Location-wise breakdown'
                    : _content,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: _content.isEmpty ? Colors.grey : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
