import 'package:flutter/material.dart';
import 'gemini_service.dart';

class TechDashboard extends StatefulWidget {
  const TechDashboard({super.key});

  @override
  State<TechDashboard> createState() => _TechDashboardState();
}

class _TechDashboardState extends State<TechDashboard> {
  String _displayText = '';
  bool _isLoading = false;
  String? _activeSection;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultsKey = GlobalKey();

  void _scrollToResults() {
    Future.delayed(const Duration(milliseconds: 400), () {
      if (_resultsKey.currentContext != null) {
        Scrollable.ensureVisible(
          _resultsKey.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  Future<void> _fetchFullCareerGuide() async {
    setState(() {
      _isLoading = true;
      _activeSection = 'full';
      _displayText = '';
    });

    await GeminiService.getTechCareersStreaming((text) {
      if (mounted) {
        setState(() {
          _displayText = text;
        });
      }
    });

    setState(() => _isLoading = false);
    _scrollToResults();
  }

  Future<void> _fetchTopTechRoles() async {
    setState(() {
      _isLoading = true;
      _activeSection = 'roles';
      _displayText = '';
    });

    final prompt = '''List top 10 trending tech roles for college students in India in 2025.
For each role, include:
- Job title
- Brief description (1 line)
- Average starting salary in India (LPA)

Format clearly with emojis.''';

    await GeminiService.chatStreamingWithModel(prompt, 'Llama 3.1 70B', (text) {
      if (mounted) {
        setState(() {
          _displayText = text;
        });
      }
    });

    setState(() => _isLoading = false);
    _scrollToResults();
  }

  Future<void> _fetchSalaries() async {
    setState(() {
      _isLoading = true;
      _activeSection = 'salaries';
      _displayText = '';
    });

    final prompt = '''List average salaries in India (2025) for 10 popular tech roles:
- Role name
- Fresher salary (0-1 years) in LPA
- Mid-level (3-5 years) in LPA
- Senior (8+ years) in LPA

Show in INR. Use emojis.''';

    await GeminiService.chatStreamingWithModel(prompt, 'Llama 3.1 70B', (text) {
      if (mounted) {
        setState(() {
          _displayText = text;
        });
      }
    });

    setState(() => _isLoading = false);
    _scrollToResults();
  }

  Future<void> _fetchSkills() async {
    setState(() {
      _isLoading = true;
      _activeSection = 'skills';
      _displayText = '';
    });

    final prompt = '''List required skills for 10 trending tech careers in India (2025):
- Role name
- Top 5 essential skills
- Recommended certifications

Format clearly with emojis.''';

    await GeminiService.chatStreamingWithModel(prompt, 'Gemma 2 9B', (text) {
      if (mounted) {
        setState(() {
          _displayText = text;
        });
      }
    });

    setState(() => _isLoading = false);
    _scrollToResults();
  }

  Future<void> _fetchGrowthPotential() async {
    setState(() {
      _isLoading = true;
      _activeSection = 'growth';
      _displayText = '';
    });

    final prompt = '''Analyze career growth potential for 8 top tech roles in India (2025):
- Role name
- Growth rate (% per year)
- Future demand (High/Medium/Low)
- Promotion timeline
- Long-term prospects

Use emojis.''';

    await GeminiService.chatStreamingWithModel(prompt, 'Command-R', (text) {
      if (mounted) {
        setState(() {
          _displayText = text;
        });
      }
    });

    setState(() => _isLoading = false);
    _scrollToResults();
  }

  Future<void> _fetchTopCompanies() async {
    setState(() {
      _isLoading = true;
      _activeSection = 'companies';
      _displayText = '';
    });

    final prompt = '''List best companies hiring for tech roles in India (2025):
- Company name
- Popular tech roles they hire
- Approximate salary range (LPA)
- Work culture highlights

Include 10-12 companies. Use emojis.''';

    await GeminiService.chatStreamingWithModel(prompt, 'Mixtral 8x7B', (text) {
      if (mounted) {
        setState(() {
          _displayText = text;
        });
      }
    });

    setState(() => _isLoading = false);
    _scrollToResults();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Blue gradient header with back button and white button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button - only show if can pop
                    if (canPop)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),

                    // Tech Careers title with icon
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.computer,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tech Careers',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Explore trending roles in 2025',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // White Generate Career Guide Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _fetchFullCareerGuide,
                        icon: const Icon(Icons.auto_awesome, size: 24),
                        label: const Text(
                          'Generate Career Guide',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1565C0),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Explore Tech Careers Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Explore Tech Careers',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Click any option below to discover',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Clean minimal option cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildMinimalOptionCard(
                      icon: Icons.workspace_premium,
                      title: 'Top 10 trending tech roles',
                      color: const Color(0xFF6366F1),
                      onTap: _fetchTopTechRoles,
                      isActive: _activeSection == 'roles',
                    ),
                    const SizedBox(height: 14),
                    _buildMinimalOptionCard(
                      icon: Icons.attach_money,
                      title: 'Average salaries in India',
                      color: const Color(0xFFEF4444),
                      onTap: _fetchSalaries,
                      isActive: _activeSection == 'salaries',
                    ),
                    const SizedBox(height: 14),
                    _buildMinimalOptionCard(
                      icon: Icons.verified,
                      title: 'Required skills for each',
                      color: const Color(0xFF10B981),
                      onTap: _fetchSkills,
                      isActive: _activeSection == 'skills',
                    ),
                    const SizedBox(height: 14),
                    _buildMinimalOptionCard(
                      icon: Icons.trending_up,
                      title: 'Career growth potential',
                      color: const Color(0xFFF59E0B),
                      onTap: _fetchGrowthPotential,
                      isActive: _activeSection == 'growth',
                    ),
                    const SizedBox(height: 14),
                    _buildMinimalOptionCard(
                      icon: Icons.business,
                      title: 'Best companies hiring',
                      color: const Color(0xFF8B5CF6),
                      onTap: _fetchTopCompanies,
                      isActive: _activeSection == 'companies',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Results Display Area
              if (_isLoading || _displayText.isNotEmpty)
                Container(
                  key: _resultsKey,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF3D3D3D),
                      width: 1.5,
                    ),
                  ),
                  child: _isLoading
                      ? Center(
                    child: Column(
                      children: [
                        const SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            color: Color(0xFF10A37F),
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Generating insights...',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                      : SelectableText(
                    _displayText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalOptionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: isActive
                ? color.withOpacity(0.1)
                : const Color(0xFF2D2D2D).withOpacity(0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isActive ? color : Colors.white,
                    fontSize: 16,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: isActive ? color : const Color(0x66FFFFFF),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
