import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'gemini_service.dart';

class InterviewDashboard extends StatefulWidget {
  const InterviewDashboard({super.key});

  @override
  State<InterviewDashboard> createState() => _InterviewDashboardState();
}

class _InterviewDashboardState extends State<InterviewDashboard> with SingleTickerProviderStateMixin {
  final TextEditingController _roleController = TextEditingController();
  bool _isLoading = false;
  String? _selectedRole;
  String? _uploadedFileName;
  bool _hasResume = false;
  String _currentStep = 'select_role';
  String? _selectedDifficulty;
  int _currentQuestionIndex = 0;
  List<Map<String, dynamic>> _mockQuestions = [];
  Map<int, String> _userAnswers = {};
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Response sections
  String _overviewSection = '';
  String _mcqSection = '';
  String _resourcesSection = '';

  final List<String> _popularRoles = [
    'Software Engineer',
    'Frontend Developer',
    'Backend Developer',
    'Full Stack Developer',
    'Data Analyst',
    'DevOps Engineer',
    'QA Engineer',
    'Product Manager',
  ];

  final List<Map<String, dynamic>> _resumeBuilders = [
    {
      'name': 'Canva Resume',
      'url': 'https://www.canva.com/resumes/templates/',
      'icon': '🎨',
      'color': Color(0xFF00C4CC),
    },
    {
      'name': 'Resume.io',
      'url': 'https://resume.io/',
      'icon': '📄',
      'color': Color(0xFF4A90E2),
    },
    {
      'name': 'Zety Resume',
      'url': 'https://zety.com/resume-builder',
      'icon': '✍️',
      'color': Color(0xFFFF6B6B),
    },
    {
      'name': 'Novoresume',
      'url': 'https://novoresume.com/',
      'icon': '💼',
      'color': Color(0xFF51CF66),
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _roleController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickResume() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );
      if (result != null) {
        setState(() {
          _uploadedFileName = result.files.single.name;
          _hasResume = true;
        });
        _analyzeResume();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ OPTIMIZED: Single API call instead of 3
  Future<void> _analyzeResume() async {
    final role = _selectedRole ?? _roleController.text.trim();

    setState(() {
      _isLoading = true;
      _currentStep = 'analysis';
      _overviewSection = '';
      _mcqSection = '';
      _resourcesSection = '';
    });

    await GeminiService.getInterviewAnalysisStreaming(role, (sections) {
      if (mounted) setState(() {
        _overviewSection = sections['overview'] ?? '';
        _mcqSection = sections['mcq'] ?? '';
        _resourcesSection = sections['resources'] ?? '';
        _isLoading = false;
      });
    });
  }

  // ✅ OPTIMIZED: Single API call instead of 3
  Future<void> _analyzeWithoutResume() async {
    final role = _selectedRole ?? _roleController.text.trim();

    setState(() {
      _isLoading = true;
      _currentStep = 'analysis';
      _hasResume = false;
      _overviewSection = '';
      _mcqSection = '';
      _resourcesSection = '';
    });

    await GeminiService.getInterviewAnalysisStreaming(role, (sections) {
      if (mounted) setState(() {
        _overviewSection = sections['overview'] ?? '';
        _mcqSection = sections['mcq'] ?? '';
        _resourcesSection = sections['resources'] ?? '';
        _isLoading = false;
      });
    });
  }

  Future<void> _startMockInterview(String difficulty) async {
    final role = _selectedRole ?? _roleController.text.trim();

    setState(() {
      _isLoading = true;
      _selectedDifficulty = difficulty;
      _currentStep = 'mock_test';
      _currentQuestionIndex = 0;
      _userAnswers.clear();
      _mockQuestions.clear();
    });

    String questionsText = '';

    await GeminiService.getInterviewMCQByDifficulty(role, difficulty, (text) {
      questionsText = text;
    });

    _mockQuestions = _parseMCQQuestions(questionsText);

    setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> _parseMCQQuestions(String text) {
    List<Map<String, dynamic>> questions = [];

    final questionBlocks = text.split(RegExp(r'Q\d+:'));

    for (var block in questionBlocks) {
      if (block.trim().isEmpty) continue;

      final lines = block.split('\n').where((l) => l.trim().isNotEmpty).toList();
      if (lines.isEmpty) continue;

      String question = lines[0].trim();
      List<String> options = [];
      String correctAnswer = '';

      for (var line in lines.skip(1)) {
        if (line.trim().startsWith(RegExp(r'[A-D]\)'))) {
          options.add(line.trim());
        } else if (line.toLowerCase().contains('correct:')) {
          correctAnswer = line.replaceAll(RegExp(r'correct:', caseSensitive: false), '').trim();
        }
      }

      if (question.isNotEmpty && options.length == 4) {
        questions.add({
          'question': question,
          'options': options,
          'correctAnswer': correctAnswer.toUpperCase(),
          'type': 'mcq',
        });
      }
    }

    if (questions.isEmpty) {
      questions = [
        {
          'question': 'What is your primary strength for this role?',
          'options': ['A) Technical skills', 'B) Communication', 'C) Problem-solving', 'D) Leadership'],
          'correctAnswer': 'A',
          'type': 'mcq',
        },
        {
          'question': 'How do you handle tight deadlines?',
          'options': ['A) Prioritize tasks', 'B) Work overtime', 'C) Ask for extension', 'D) Delegate work'],
          'correctAnswer': 'A',
          'type': 'mcq',
        },
        {
          'question': 'What motivates you most at work?',
          'options': ['A) Learning new skills', 'B) Salary', 'C) Recognition', 'D) Work-life balance'],
          'correctAnswer': 'A',
          'type': 'mcq',
        },
        {
          'question': 'How do you approach a new project?',
          'options': ['A) Research thoroughly', 'B) Start immediately', 'C) Ask team', 'D) Follow template'],
          'correctAnswer': 'A',
          'type': 'mcq',
        },
        {
          'question': 'Your biggest career goal?',
          'options': ['A) Senior position', 'B) Start business', 'C) Expertise', 'D) Work abroad'],
          'correctAnswer': 'C',
          'type': 'mcq',
        },
      ];
    }

    return questions;
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
  }

  void _resetFlow() {
    setState(() {
      _currentStep = 'select_role';
      _selectedRole = null;
      _roleController.clear();
      _uploadedFileName = null;
      _hasResume = false;
      _overviewSection = '';
      _mcqSection = '';
      _resourcesSection = '';
      _selectedDifficulty = null;
      _currentQuestionIndex = 0;
      _mockQuestions.clear();
      _userAnswers.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: _buildCurrentStep(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
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
            child: const Icon(Icons.psychology, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Interview Preparation',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _getStepDescription(),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          if (_currentStep != 'select_role')
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _resetFlow,
              tooltip: 'Start Over',
            ),
        ],
      ),
    );
  }

  String _getStepDescription() {
    switch (_currentStep) {
      case 'select_role':
        return 'Select your target job role';
      case 'resume_choice':
        return 'Upload resume or build one';
      case 'analysis':
        return 'AI-powered analysis & insights';
      case 'mock_test':
        return 'Mock interview in progress';
      default:
        return 'Ace your next interview';
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 'select_role':
        return _buildRoleSelection();
      case 'resume_choice':
        return _buildResumeChoice();
      case 'analysis':
        return _buildAnalysisResults();
      case 'mock_test':
        return _buildMockTest();
      default:
        return _buildRoleSelection();
    }
  }

  Widget _buildRoleSelection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.4)),
            ),
            child: TextField(
              controller: _roleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Enter job role (e.g., Frontend Developer)',
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.search, color: Color(0xFF6366F1)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
              onChanged: (value) => setState(() => _selectedRole = null),
            ),
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Popular Roles:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popularRoles.map((role) {
              final isSelected = _selectedRole == role;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedRole = role;
                    _roleController.text = role;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade700,
                    ),
                  ),
                  child: Text(
                    role,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade300,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () {
                final role = _selectedRole ?? _roleController.text.trim();
                if (role.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select or enter a job role')),
                  );
                  return;
                }
                setState(() => _currentStep = 'resume_choice');
              },
              icon: const Icon(Icons.arrow_forward, size: 22),
              label: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumeChoice() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.description, size: 60, color: Color(0xFF6366F1)),
                const SizedBox(height: 16),
                const Text(
                  'Do you have a resume?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload your resume for personalized analysis',
                  style: TextStyle(color: Colors.grey.shade400),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            height: 70,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _pickResume,
              icon: const Icon(Icons.upload_file, size: 28),
              label: Text(
                _uploadedFileName ?? '📄 Upload Resume',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(child: Divider(color: Colors.grey)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('OR', style: TextStyle(color: Colors.grey)),
              ),
              Expanded(child: Divider(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton.icon(
              onPressed: _analyzeWithoutResume,
              icon: const Icon(Icons.arrow_forward),
              label: const Text(
                'Continue Without Resume',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6366F1),
                side: const BorderSide(color: Color(0xFF6366F1), width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '✨ Build Your Resume:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            itemCount: _resumeBuilders.length,
            itemBuilder: (context, index) {
              final builder = _resumeBuilders[index];
              return GestureDetector(
                onTap: () => _launchURL(builder['url']),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (builder['color'] as Color).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        builder['icon'],
                        style: const TextStyle(fontSize: 40),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        builder['name'],
                        style: TextStyle(
                          color: builder['color'],
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      const Icon(
                        Icons.open_in_new,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResults() {
    return Column(
      children: [
        if (_isLoading)
          Container(
            padding: const EdgeInsets.all(24),
            child: const Column(
              children: [
                CircularProgressIndicator(color: Color(0xFF6366F1)),
                SizedBox(height: 16),
                Text(
                  'Analyzing your profile...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          )
        else ...[
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.analytics, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Analysis Report',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade700),
                const SizedBox(height: 16),

                if (_overviewSection.isNotEmpty) ...[
                  SelectableText(
                    _overviewSection,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                if (_mcqSection.isNotEmpty) ...[
                  SelectableText(
                    _mcqSection,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                if (_resourcesSection.isNotEmpty) ...[
                  SelectableText(
                    _resourcesSection,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  '🎯 Take Mock Interview',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Test your preparation with AI-powered MCQ interviews',
                  style: TextStyle(color: Colors.grey.shade400),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildDifficultyButton('Easy', '🟢', Colors.green),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDifficultyButton('Medium', '🟡', Colors.orange),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDifficultyButton('Hard', '🔴', Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDifficultyButton(String level, String emoji, Color color) {
    return ElevatedButton(
      onPressed: () => _startMockInterview(level),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.15),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color, width: 2),
        ),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            level,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMockTest() {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF6366F1)),
              const SizedBox(height: 16),
              Text(
                'Preparing $_selectedDifficulty questions...',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentQuestionIndex >= _mockQuestions.length) {
      return _buildMCQResults();
    }

    final question = _mockQuestions[_currentQuestionIndex];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _mockQuestions.length,
            backgroundColor: Colors.grey.shade800,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1} of ${_mockQuestions.length}',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _selectedDifficulty == 'Easy'
                      ? Colors.green.withOpacity(0.2)
                      : _selectedDifficulty == 'Medium'
                      ? Colors.orange.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedDifficulty == 'Easy'
                        ? Colors.green
                        : _selectedDifficulty == 'Medium'
                        ? Colors.orange
                        : Colors.red,
                  ),
                ),
                child: Text(
                  _selectedDifficulty!,
                  style: TextStyle(
                    color: _selectedDifficulty == 'Easy'
                        ? Colors.green
                        : _selectedDifficulty == 'Medium'
                        ? Colors.orange
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withOpacity(0.2),
                  const Color(0xFF6366F1).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
            ),
            child: Text(
              question['question'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),

          ...List.generate(question['options'].length, (index) {
            final option = question['options'][index];
            final optionLetter = option.substring(0, 2).trim();
            final isSelected = _userAnswers[_currentQuestionIndex] == optionLetter;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _userAnswers[_currentQuestionIndex] = optionLetter;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF6366F1).withOpacity(0.2)
                      : const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF6366F1)
                        : Colors.grey.shade700,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? const Color(0xFF6366F1)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF6366F1)
                              : Colors.grey,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade300,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          Row(
            children: [
              if (_currentQuestionIndex > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _currentQuestionIndex--);
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6366F1),
                      side: const BorderSide(color: Color(0xFF6366F1)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              if (_currentQuestionIndex > 0) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_userAnswers[_currentQuestionIndex] == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select an answer')),
                      );
                      return;
                    }
                    setState(() => _currentQuestionIndex++);
                  },
                  icon: Icon(
                    _currentQuestionIndex == _mockQuestions.length - 1
                        ? Icons.check
                        : Icons.arrow_forward,
                  ),
                  label: Text(
                    _currentQuestionIndex == _mockQuestions.length - 1
                        ? 'Finish'
                        : 'Next',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMCQResults() {
    int correctCount = 0;

    for (int i = 0; i < _mockQuestions.length; i++) {
      final question = _mockQuestions[i];
      final userAnswer = _userAnswers[i];
      final correctAnswer = question['correctAnswer'];

      if (userAnswer != null && userAnswer.startsWith(correctAnswer)) {
        correctCount++;
      }
    }

    final percentage = (correctCount / _mockQuestions.length * 100).round();

    String level;
    String feedback;
    Color levelColor;

    if (percentage >= 80) {
      level = 'Expert Level';
      feedback = '🎉 Excellent! You\'re ready for senior-level interviews.';
      levelColor = Colors.green;
    } else if (percentage >= 60) {
      level = 'Intermediate Level';
      feedback = '👍 Good job! You\'re ready for mid-level positions. Keep practicing!';
      levelColor = Colors.orange;
    } else if (percentage >= 40) {
      level = 'Entry Level';
      feedback = '📚 You have the basics. Focus on core concepts for entry-level roles.';
      levelColor = Colors.blue;
    } else {
      level = 'Needs Improvement';
      feedback = '💪 Keep learning! Review fundamentals before applying.';
      levelColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [levelColor.withOpacity(0.3), levelColor.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: levelColor, width: 2),
            ),
            child: Column(
              children: [
                Icon(Icons.emoji_events, size: 60, color: levelColor),
                const SizedBox(height: 16),
                Text(
                  'Score: $correctCount/${_mockQuestions.length}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 24,
                    color: levelColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: levelColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: levelColor),
                  ),
                  child: Text(
                    level,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: levelColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  feedback,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _resetFlow,
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Try Another Level',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
