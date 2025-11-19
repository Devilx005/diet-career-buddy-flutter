import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'login_screen.dart';
import 'gemini_service.dart';

import 'tech_dashboard.dart';
import 'salary_dashboard.dart';
import 'learning_dashboard.dart';
import 'diet_guide.dart';
import 'interview_prep.dart';
import 'jobs_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: ".env");
      print("✅ .env file loaded successfully");
    } catch (e) {
      print("⚠️ .env file not found, using environment variables: $e");
    }
  } else {
    print("🌐 Running on web - using Vercel environment variables");
  }

  runApp(const DIETCareerBuddyApp());
}

class DIETCareerBuddyApp extends StatelessWidget {
  const DIETCareerBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pathify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF10A37F),
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF212121),
          elevation: 1,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final username = prefs.getString('username') ?? 'Guest';

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(isLoggedIn: true, username: username),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 80, color: Color(0xFF10A37F)),
            SizedBox(height: 16),
            Text('Pathify', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Color(0xFF10A37F)),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLoginDialog();
    });
  }

  void _showLoginDialog() async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const LoginDialog(),
    );

    if (result != null && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', result != 'Guest');
      await prefs.setString('username', result);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            isLoggedIn: result != 'Guest',
            username: result,
          ),
        ),
      );
    } else if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(
            isLoggedIn: false,
            username: 'Guest',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF10A37F)),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final bool isLoggedIn;
  final String username;

  const HomeScreen({super.key, required this.isLoggedIn, required this.username});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late bool isLoggedIn;
  late String username;
  String currentDashboard = 'home';
  final TextEditingController _questionController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    isLoggedIn = widget.isLoggedIn;
    username = widget.username;

    _questionController.addListener(() {
      setState(() {});
    });
  }

  void _login(String user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('username', user);

    setState(() {
      isLoggedIn = true;
      username = user;
    });
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _showDashboard(String dashboard) {
    setState(() {
      currentDashboard = dashboard;
    });
  }

  void _backToHome() {
    setState(() {
      currentDashboard = 'home';
    });
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D2D2D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(Icons.school, color: Color(0xFF10A37F), size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'About Pathify',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your AI-Powered Career Assistant',
                  style: TextStyle(
                    color: Color(0xFF10A37F),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pathify is an intelligent career guidance platform designed specifically for DIET (Diploma in Information and Educational Technology) students.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFeatureRow('🎯', 'Personalized career paths'),
                _buildFeatureRow('💼', 'Live job opportunities'),
                _buildFeatureRow('💰', 'Real-time salary insights'),
                _buildFeatureRow('📚', 'Learning resources'),
                _buildFeatureRow('🤖', 'AI-powered guidance'),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Version', style: TextStyle(color: Colors.white60, fontSize: 12)),
                    Text('1.0.0', style: TextStyle(color: Color(0xFF10A37F), fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10A37F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF10A37F),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.favorite, color: Color(0xFF10A37F), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Created for all students seeking careers',
                          style: TextStyle(
                            color: Color(0xFF10A37F),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Created by TY BTech DIET Students',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                _buildTeamMember('Vinayak Kharade', '23067971242029'),
                const SizedBox(height: 8),
                _buildTeamMember('Prathmesh Sandim', '23067971242030'),
                const SizedBox(height: 8),
                _buildTeamMember('Satwik Tambewagh', '23067971242033'),
                const SizedBox(height: 8),
                _buildTeamMember('Rohan Sawant', '23067971242077'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF10A37F),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeatureRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildTeamMember(String name, String prn) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF10A37F).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: Color(0xFF10A37F), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'PRN: $prn',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_questionController.text.trim().isEmpty) return;

    final userMessage = _questionController.text.trim();
    setState(() {
      _messages.add({'role': 'user', 'content': userMessage});
      _isLoading = true;
    });
    _questionController.clear();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    await GeminiService.chatStreaming(userMessage, (text) {
      setState(() {
        if (_messages.isNotEmpty && _messages.last['role'] == 'assistant') {
          _messages[_messages.length - 1]['content'] = text;
        } else {
          _messages.add({'role': 'assistant', 'content': text});
        }
      });
    });

    setState(() => _isLoading = false);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: isLoggedIn ? Drawer(
        backgroundColor: const Color(0xFF212121),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF10A37F),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.school, size: 50, color: Colors.white),
                  const SizedBox(height: 8),
                  const Text('Career Me', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('👋 $username', style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            _drawerItem(Icons.computer, 'Tech Careers', () => _showDashboard('tech')),
            _drawerItem(Icons.attach_money, 'Live Salary', () => _showDashboard('salary')),
            _drawerItem(Icons.school, 'Learning Paths', () => _showDashboard('learning')),
            _drawerItem(Icons.book, 'DIET Guide', () => _showDashboard('diet')),
            _drawerItem(Icons.work, 'Interview Prep', () => _showDashboard('interview')),
            _drawerItem(Icons.business_center, 'Live Jobs', () => _showDashboard('jobs')),
            const Divider(),
            _drawerItem(Icons.logout, 'Logout', _logout, color: Colors.red),
            _drawerItem(Icons.info_outline, 'About', _showAboutDialog, color: const Color(0xFF10A37F)),
          ],
        ),
      ) : null,

      appBar: AppBar(
        leading: isLoggedIn ? null : const SizedBox(),
        title: const Text('🎓 Pathify', style: TextStyle(color: Color(0xFF10A37F), fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        actions: [
          // ✅ CHANGE 1: Show back button when in dashboard, logout when on home
          if (currentDashboard != 'home')
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF10A37F)),
              onPressed: _backToHome,
              tooltip: 'Back to Home',
            ),
        ],
      ),
      body: currentDashboard == 'home' ? _buildHomePage() : _buildDashboardPage(),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? const Color(0xFF10A37F)),
      title: Text(title, style: TextStyle(color: color ?? Colors.white)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  Widget _buildHomePage() {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty && isLoggedIn
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '🎓 Welcome back, $username!',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  '✨ Your AI Career Assistant',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
              : SingleChildScrollView(
            controller: _scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isLoggedIn)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 150),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Login to use all features ', style: TextStyle(color: Colors.grey, fontSize: 16)),
                            GestureDetector(
                              onTap: () async {
                                final result = await showDialog<String>(
                                  context: context,
                                  builder: (context) => const LoginDialog(),
                                );
                                if (result != null) _login(result);
                              },
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  color: Color(0xFF10A37F),
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_messages.isNotEmpty) ...[
                    const Text('💬 Conversation:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ..._messages.map((message) => _buildMessageBubble(message)),
                  ],
                  if (_isLoading)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFF2D2D2D), borderRadius: BorderRadius.circular(12)),
                      child: const Row(
                        children: [
                          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 12),
                          Text('Thinking...'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.grey),
                        onPressed: () {},
                        padding: const EdgeInsets.all(8),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _questionController,
                          enabled: !_isLoading,
                          maxLines: 3,
                          minLines: 1,
                          decoration: const InputDecoration(
                            hintText: 'Ask anything',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.mic, color: Colors.grey),
                        onPressed: () {},
                        padding: const EdgeInsets.all(8),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                mini: true,
                onPressed: _isLoading ? null : _sendMessage,
                backgroundColor: _isLoading ? Colors.grey : const Color(0xFF10A37F),
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(Map<String, String> message) {
    final isUser = message['role'] == 'user';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF10A37F) : const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(message['content'] ?? '', style: const TextStyle(fontSize: 14)),
      ),
    );
  }

  Widget _buildDashboardPage() {
    Widget content;
    switch (currentDashboard) {
      case 'tech': content = TechDashboard(); break;
      case 'salary': content = SalaryDashboard(); break;
      case 'learning': content = LearningDashboard(); break;
      case 'diet': content = DIETGuide(); break;
      case 'interview': content = InterviewPrep(); break;
      case 'jobs': content = JobsDashboard(); break;
      default: content = Center(child: Text('${currentDashboard.toUpperCase()}\nComing Soon!', textAlign: TextAlign.center, style: const TextStyle(fontSize: 20)));
    }

    // ✅ CHANGE 2: Removed "Back to Home" button - now it's in AppBar
    return content;
  }
}
