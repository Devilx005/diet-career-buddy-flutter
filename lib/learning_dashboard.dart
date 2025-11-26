import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'gemini_service.dart';

class LearningDashboard extends StatefulWidget {
  const LearningDashboard({super.key});

  @override
  State<LearningDashboard> createState() => _LearningDashboardState();
}

class _LearningDashboardState extends State<LearningDashboard> with SingleTickerProviderStateMixin {
  final TextEditingController _domainController = TextEditingController();
  bool _isLoading = false;
  String _response = '';
  final ScrollController _scrollController = ScrollController();
  String? _selectedDomain;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _popularDomains = [
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
  ];

  // ✅ TONED DOWN COLORS (Less bright)
  final Map<String, Map<String, dynamic>> _coursePlatforms = {
    'Coursera': {
      'url': 'https://www.coursera.org/search?query=',
      'color': const Color(0xFF0056D2),
      'icon': '🎓',
    },
    'Udemy': {
      'url': 'https://www.udemy.com/courses/search/?q=',
      'color': const Color(0xFFEC5252),
      'icon': '📚',
    },
    'freeCodeCamp': {
      'url': 'https://www.freecodecamp.org/learn/',
      'color': const Color(0xFF0A0A23),
      'icon': '💻',
    },
    'YouTube': {
      'url': 'https://www.youtube.com/results?search_query=',
      'color': const Color(0xFFFF0000),
      'icon': '📺',
    },
    'edX': {
      'url': 'https://www.edx.org/search?q=',
      'color': const Color(0xFF02262B),
      'icon': '🏛️',
    },
    'Udacity': {
      'url': 'https://www.udacity.com/courses/all?search=',
      'color': const Color(0xFF02B3E4),
      'icon': '🚀',
    },
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _domainController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _generateLearningPath() async {
    final domain = _selectedDomain ?? _domainController.text.trim();

    if (domain.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Please enter or select a domain'),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _response = '';
    });

    await GeminiService.getLearningPathStreaming(domain, (text) {
      setState(() {
        _response = text;
      });
    });

    setState(() => _isLoading = false);
  }

  Future<void> _launchCourseURL(String platform, String query) async {
    final platformData = _coursePlatforms[platform];
    final url = Uri.parse(platformData!['url'] + Uri.encodeComponent(query));

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open $platform'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      // ✅ FIXED: ENTIRE SCREEN SCROLLABLE
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _response.isEmpty
            ? Column(
          children: [
            _buildHeader(),
            _buildSearchSection(),
            _buildQuickSelect(),
            Expanded(child: _buildEmptyState()),
          ],
        )
            : SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchSection(),
              _buildQuickSelect(),
              _buildResponseWithLinks(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      // ✅ TONED DOWN - Less bright orange
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE67E22), // Softer orange
            Color(0xFFD35400), // Darker orange
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE67E22).withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.school, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learning Paths',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Your personalized roadmap to success',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade800),
        ),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              // ✅ TONED DOWN BORDER
              border: Border.all(color: const Color(0xFFE67E22).withOpacity(0.4)),
            ),
            child: TextField(
              controller: _domainController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Enter domain/technology (e.g., Flutter, Python)',
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.search, color: Color(0xFFE67E22)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              onChanged: (value) => setState(() => _selectedDomain = null),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _generateLearningPath,
              icon: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Icon(Icons.auto_awesome, size: 22),
              label: Text(
                _isLoading ? 'Generating...' : '🚀 Get Learning Path',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                // ✅ TONED DOWN BUTTON
                backgroundColor: const Color(0xFFE67E22),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSelect() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade800),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                // ✅ TONED DOWN ICON BACKGROUND
                decoration: BoxDecoration(
                  color: const Color(0xFFE67E22),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.whatshot, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'Popular Domains',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _popularDomains.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final domain = _popularDomains[index];
                final isSelected = _selectedDomain == domain;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDomain = domain;
                      _domainController.text = domain;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      // ✅ TONED DOWN SELECTION
                      color: isSelected
                          ? const Color(0xFFE67E22)
                          : const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFE67E22)
                            : Colors.grey.shade700,
                      ),
                    ),
                    child: Text(
                      domain,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade300,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            // ✅ TONED DOWN GRADIENT
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE67E22), Color(0xFFD35400)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE67E22).withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.explore, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text(
            'Start Your Journey',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Discover your personalized learning path',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          _buildFeatureCard('📚', 'Complete Roadmap', 'Step-by-step learning path from beginner to expert'),
          const SizedBox(height: 12),
          _buildFeatureCard('🎯', 'Curated Resources', 'Best free and paid courses handpicked for you'),
          const SizedBox(height: 12),
          _buildFeatureCard('⏱️', 'Time Estimates', 'Know exactly how long each phase will take'),
          const SizedBox(height: 12),
          _buildFeatureCard('🎓', 'Certifications', 'Get recommended certifications to boost your resume'),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String emoji, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
        // ✅ TONED DOWN BORDER
        border: Border.all(
          color: const Color(0xFFE67E22).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            // ✅ TONED DOWN ICON BACKGROUND
            decoration: BoxDecoration(
              color: const Color(0xFFE67E22).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseWithLinks() {
    final domain = _selectedDomain ?? _domainController.text.trim();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D),
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade800),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE67E22),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.link, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Find Courses On:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _coursePlatforms.entries.map((entry) {
                  return _buildCoursePlatformButton(
                    entry.key,
                    entry.value['icon'],
                    entry.value['color'],
                    domain,
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE67E22).withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE67E22),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Learning Roadmap',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          domain,
                          style: const TextStyle(
                            color: Color(0xFFE67E22),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFE67E22),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: Colors.grey.shade700),
              const SizedBox(height: 16),
              SelectableText(
                _response,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoursePlatformButton(String platform, String emoji, Color color, String query) {
    return ElevatedButton(
      onPressed: () => _launchCourseURL(platform, query),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            platform,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.open_in_new, size: 14),
        ],
      ),
    );
  }
}
