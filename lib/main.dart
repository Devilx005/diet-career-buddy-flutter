import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'login_screen.dart';
import 'gemini_service.dart';

import 'tech_dashboard.dart';
import 'salary_dashboard.dart';
import 'learning_dashboard.dart';
import 'diet_guide.dart';
import 'interview_prep.dart';
import 'jobs_dashboard.dart';
import 'recent_chats_screen.dart';
import 'conversation.dart';
import 'conversation_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
      title: 'Pathify AI',
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
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // Check Firebase Auth
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // User logged in via Firebase
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            isLoggedIn: true,
            username: user.displayName ?? user.email!.split('@')[0],
          ),
        ),
      );
    } else {
      // Check SharedPreferences for old sessions
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final username = prefs.getString('username') ?? 'Guest';

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
            Text('Pathify AI', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late bool isLoggedIn;
  late String username;
  String currentDashboard = 'home';
  final TextEditingController _questionController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String? _currentConversationId;
  bool _wasTemporaryButtonClicked = false;

  String _selectedModel = 'Llama 3.1 70B';
  final List<Map<String, String>> _availableModels = [
    {'name': 'Llama 3.1 70B', 'provider': 'Groq', 'icon': '⚡'},
    {'name': 'Mixtral 8x7B', 'provider': 'Groq', 'icon': '🚀'},
    {'name': 'Gemma 2 9B', 'provider': 'Groq', 'icon': '💎'},
    {'name': 'Command-R', 'provider': 'Cohere', 'icon': '🔮'},
    {'name': 'Gemini 1.5 Flash', 'provider': 'Google', 'icon': '🔷'},
  ];

  late AnimationController _aboutFadeController;
  late AnimationController _aboutSlideController;
  late Animation<double> _aboutFadeAnimation;
  late Animation<Offset> _aboutSlideAnimation;

  @override
  void initState() {
    super.initState();
    isLoggedIn = widget.isLoggedIn;
    username = widget.username;

    _questionController.addListener(() {
      setState(() {});
    });

    _aboutFadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _aboutSlideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _aboutFadeAnimation = CurvedAnimation(
      parent: _aboutFadeController,
      curve: Curves.easeIn,
    );

    _aboutSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _aboutSlideController,
      curve: Curves.easeOutCubic,
    ));
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
    // Sign out from Firebase
    await FirebaseAuth.instance.signOut();

    // Clear SharedPreferences
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

  void _startNewTemporaryChat() {
    setState(() {
      _messages.clear();
      _currentConversationId = null;
      _isLoading = false;
      _questionController.clear();
      _wasTemporaryButtonClicked = true;
    });
  }

  void _exitTemporaryMode() {
    setState(() {
      _wasTemporaryButtonClicked = false;
      _messages.clear();
      _currentConversationId = null;
      _isLoading = false;
      _questionController.clear();
    });
  }

  void _showAboutDialog() {
    _aboutFadeController.forward(from: 0.0);
    _aboutSlideController.forward(from: 0.0);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FadeTransition(
          opacity: _aboutFadeAnimation,
          child: SlideTransition(
            position: _aboutSlideAnimation,
            child: AlertDialog(
              backgroundColor: const Color(0xFF2D2D2D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: EdgeInsets.zero,
              content: SingleChildScrollView(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF10A37F), Color(0xFF0D8A6A)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF10A37F).withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.school, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'About Pathify AI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF10A37F), Color(0xFF0FD1A8)],
                        ).createShader(bounds),
                        child: const Text(
                          'Your AI-Powered Career Assistant',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ..._buildAnimatedFeatures(),
                      const SizedBox(height: 24),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 16),
                      _buildVersionCard(),
                      const SizedBox(height: 16),
                      const Text(
                        'Created by TY BTech DIET Students',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
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
                      const SizedBox(height: 24),
                      Center(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10A37F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 8,
                            shadowColor: Color(0xFF10A37F).withOpacity(0.5),
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildAnimatedFeatures() {
    final features = [
      {'icon': '🎯', 'text': 'Personalized career paths'},
      {'icon': '💼', 'text': 'Live job opportunities'},
      {'icon': '💰', 'text': 'Real-time salary insights'},
      {'icon': '📚', 'text': 'Learning resources'},
      {'icon': '🤖', 'text': 'AI-powered guidance'},
    ];

    return features.asMap().entries.map((entry) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 400 + (entry.key * 80)),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          final clampedValue = value.clamp(0.0, 1.0);

          return Transform.translate(
            offset: Offset(0, 15 * (1 - clampedValue)),
            child: Opacity(
              opacity: clampedValue,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Color(0xFF10A37F).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Text(entry.value['icon']!, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Text(
                      entry.value['text']!,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildVersionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF10A37F).withOpacity(0.15),
            Color(0xFF0D8A6A).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFF10A37F).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Version',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10A37F),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              '1.0.0',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMember(String name, String prn) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Color(0xFF10A37F).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10A37F), Color(0xFF0D8A6A)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'PRN: $prn',
                  style: const TextStyle(
                    color: Colors.white54,
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

    if (_currentConversationId == null && _messages.isEmpty && !_wasTemporaryButtonClicked) {
      _currentConversationId = DateTime.now().millisecondsSinceEpoch.toString();
    }

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

    String fullResponse = '';
    await GeminiService.chatStreamingWithModel(userMessage, _selectedModel, (text) {
      fullResponse = text;
      setState(() {
        if (_messages.isNotEmpty && _messages.last['role'] == 'assistant') {
          _messages[_messages.length - 1]['content'] = text;
        } else {
          _messages.add({'role': 'assistant', 'content': text});
        }
      });
    });

    setState(() => _isLoading = false);

    if (currentDashboard == 'home' && _currentConversationId != null && _messages.length >= 2) {
      final conversation = Conversation(
        id: _currentConversationId!,
        title: _messages.first['content']!.length > 50
            ? _messages.first['content']!.substring(0, 50) + '...'
            : _messages.first['content']!,
        createdAt: DateTime.now(),
        messages: _messages.map((m) => Message(
          text: m['content']!,
          isUser: m['role'] == 'user',
          timestamp: DateTime.now(),
        )).toList(),
      );
      await ConversationStorage.saveConversation(conversation);
    }

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
      backgroundColor: const Color(0xFF1E1E1E),
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
                  const Text('Pathify AI', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
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
            ListTile(
              leading: const Icon(Icons.history, color: Color(0xFF10A37F)),
              title: const Text('Recent Chats', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RecentChatsScreen()),
                );
              },
            ),
            const Divider(),
            _drawerItem(Icons.logout, 'Logout', _logout, color: Colors.red),
            _drawerItem(Icons.info_outline, 'About', _showAboutDialog, color: const Color(0xFF10A37F)),
          ],
        ),
      ) : null,

      appBar: AppBar(
        backgroundColor: const Color(0xFF212121),
        leading: isLoggedIn ? null : const SizedBox(),
        title: const Text('🎓 Pathify AI', style: TextStyle(color: Color(0xFF10A37F), fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        actions: [
          if (currentDashboard == 'home') ...[
            if (_wasTemporaryButtonClicked && _messages.isEmpty)
              IconButton(
                icon: const Icon(Icons.home, color: Colors.white70),
                tooltip: 'Back to Home',
                onPressed: _exitTemporaryMode,
              ),
            IconButton(
              icon: const Icon(Icons.edit_note, color: Colors.white70),
              tooltip: 'New Temporary Chat',
              onPressed: _startNewTemporaryChat,
            ),
          ],
          if (currentDashboard != 'home')
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF10A37F), size: 22),
                label: const Text(
                  'Back',
                  style: TextStyle(color: Color(0xFF10A37F), fontSize: 16, fontWeight: FontWeight.w600),
                ),
                onPressed: _backToHome,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  backgroundColor: Color(0xFF10A37F).withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
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
          child: _messages.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_wasTemporaryButtonClicked) ...[
                  const Text(
                    'Temporary Chat',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: const Text(
                      'This chat won\'t appear in history, use or update Pathify AI\'s memory, or be used to train our models. For safety purposes, we may keep a copy of this chat for up to 30 days.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextButton.icon(
                    onPressed: _exitTemporaryMode,
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF10A37F)),
                    label: const Text(
                      'Back to Home',
                      style: TextStyle(color: Color(0xFF10A37F), fontSize: 16),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      backgroundColor: Color(0xFF10A37F).withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                        side: BorderSide(color: Color(0xFF10A37F).withOpacity(0.3)),
                      ),
                    ),
                  ),
                ] else if (isLoggedIn) ...[
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
                ] else ...[
                  Row(
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
                ],
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
                  if (_messages.isNotEmpty) ...[
                    Row(
                      children: [
                        Text(
                          _currentConversationId == null ? '💬 Temporary Chat' : '💬 Conversation:',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (_currentConversationId == null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange, width: 1),
                            ),
                            child: const Text(
                              'Not saved',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
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
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: PopupMenuButton<String>(
                          icon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _availableModels.firstWhere((m) => m['name'] == _selectedModel)['icon']!,
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 20),
                            ],
                          ),
                          tooltip: 'Select AI Model',
                          offset: const Offset(0, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: const Color(0xFF2D2D2D),
                          itemBuilder: (context) => _availableModels.map((model) {
                            final isSelected = model['name'] == _selectedModel;
                            return PopupMenuItem<String>(
                              value: model['name'],
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                decoration: BoxDecoration(
                                  color: isSelected ? Color(0xFF10A37F).withOpacity(0.1) : null,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Text(model['icon']!, style: const TextStyle(fontSize: 20)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            model['name']!,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                            ),
                                          ),
                                          Text(
                                            model['provider']!,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(Icons.check_circle, color: Color(0xFF10A37F), size: 18),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          onSelected: (value) {
                            setState(() {
                              _selectedModel = value;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Text(_availableModels.firstWhere((m) => m['name'] == value)['icon']!),
                                    const SizedBox(width: 8),
                                    Text('Switched to $value'),
                                  ],
                                ),
                                duration: const Duration(seconds: 2),
                                backgroundColor: const Color(0xFF10A37F),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: TextField(
                            controller: _questionController,
                            enabled: !_isLoading,
                            maxLines: 3,
                            minLines: 1,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              hintText: 'Ask anything',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
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
    switch (currentDashboard) {
      case 'tech':
        return TechDashboard();
      case 'salary':
        return SalaryDashboard();
      case 'learning':
        return LearningDashboard();
      case 'diet':
        return DIETGuide();
      case 'interview':
        return InterviewDashboard(); // <-- use this
      case 'jobs':
        return JobsDashboard();
      default:
        return const Center(
          child: Text(
            'Dashboard not found',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20),
          ),
        );
    }
  }


  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    _aboutFadeController.dispose();
    _aboutSlideController.dispose();
    super.dispose();
  }
}
