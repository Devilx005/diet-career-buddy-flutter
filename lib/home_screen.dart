import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'tech_dashboard.dart';
import 'salary_dashboard.dart';
import 'learning_dashboard.dart';
import 'diet_guide.dart';
import 'interview_prep.dart';
import 'jobs_dashboard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoggedIn = false;
  String username = '';
  String currentPage = 'home';
  final TextEditingController _questionController = TextEditingController();

  void _login(String user) {
    setState(() {
      isLoggedIn = true;
      username = user;
    });
  }

  void _logout() {
    setState(() {
      isLoggedIn = false;
      username = '';
    });
  }

  void _navigateToDashboard(String page) {
    setState(() {
      currentPage = page;
    });
  }

  void _backToHome() {
    setState(() {
      currentPage = 'home';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.menu, color: Colors.grey),
        title: const Text(
          '🎓 DIET Career Buddy',
          style: TextStyle(
            color: Color(0xFF10A37F),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          if (isLoggedIn)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                children: [
                  Text('👋 $username', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _logout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF6B6B),
                      side: const BorderSide(color: Color(0xFFFF6B6B)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                  if (result != null) {
                    _login(result);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10A37F).withOpacity(0.8),
                  foregroundColor: Colors.white,
                ),
                child: const Text('🔐 Login'),
              ),
            ),
        ],
      ),
      body: currentPage == 'home' ? _buildHomePage() : _buildDashboardPage(),
    );
  }

  Widget _buildHomePage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome
            Text(
              isLoggedIn
                  ? '🎓 Welcome back, $username!'
                  : '🎓 Welcome to DIET Career Buddy!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your AI-Powered Career Assistant with Real-Time Data',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),

            // Info card
            if (!isLoggedIn)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '💡 All features are accessible! Login is optional for a personalized experience.',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Dashboard buttons
            Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildDashboardButton('💻\nTech\nCareers', 'tech')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDashboardButton('💰\nLive\nSalary', 'salary')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDashboardButton('📚\nLearning\nPaths', 'learn')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildDashboardButton('🎓\nDIET\nGuide', 'diet')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDashboardButton('🎯\nInterview\nPrep', 'interview')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDashboardButton('📊\nLive\nJobs', 'jobs')),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // What Makes Us Special
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10A37F).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🚀 What Makes Us Special:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildFeature('Real-Time APIs:', 'Live job market data from GitHub & CoinGecko'),
                  _buildFeature('DIET-Specific Guidance:', 'Tailored advice for engineering students'),
                  _buildFeature('Interactive Dashboards:', '6 comprehensive career analysis tools'),
                  _buildFeature('Professional Design:', 'Clean, modern interface'),
                  _buildFeature('Market Intelligence:', 'AI-powered career insights'),
                  const SizedBox(height: 12),
                  const Text(
                    '✨ All features unlocked for everyone!',
                    style: TextStyle(color: Color(0xFF10A37F), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Ask Questions
            const Text(
              '💬 Ask Your Career Questions!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: TextField(
                    controller: _questionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: isLoggedIn
                          ? 'Hi $username, what would you like to know?\ne.g., What skills do I need for data science?'
                          : 'What would you like to know about careers?\ne.g., What skills do I need for data science?',
                      filled: true,
                      fillColor: const Color(0xFF2D2D2D),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 90,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_questionController.text.trim().isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isLoggedIn
                                  ? 'Great question, $username! 🎓 Explore our dashboards above for detailed insights!'
                                  : 'Great question! 🎓 Explore our dashboards above for detailed insights!'),
                              backgroundColor: const Color(0xFF10A37F),
                            ),
                          );
                          _questionController.clear();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10A37F),
                      ),
                      child: const Text('🚀\nSend', textAlign: TextAlign.center),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardPage() {
    Widget dashboard;
    switch (currentPage) {
      case 'tech':
        dashboard = TechDashboard();
        break;
      case 'salary':
        dashboard = SalaryDashboard();
        break;
      case 'learn':
        dashboard = LearningDashboard();
        break;
      case 'diet':
        dashboard = DIETGuide();
        break;
      case 'interview':
        dashboard = InterviewPrep();
        break;
      case 'jobs':
        dashboard = JobsDashboard();  // ✅ FIXED - was LiveJobs()
        break;
      default:
        dashboard = const SizedBox();
    }

    return Column(
      children: [
        Expanded(child: dashboard),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _backToHome,
            icon: const Icon(Icons.home),
            label: const Text('Back to Home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10A37F),
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardButton(String text, String page) {
    return SizedBox(
      height: 80,
      child: ElevatedButton(
        onPressed: () => _navigateToDashboard(page),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2D2D2D),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildFeature(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14),
          children: [
            const TextSpan(text: '• '),
            TextSpan(
              text: '$title ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: description),
          ],
        ),
      ),
    );
  }
}
