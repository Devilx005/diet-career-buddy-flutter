import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:google_sign_in/google_sign_in.dart';
import 'home_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration.zero, () {
      if (context.mounted) {
        _showLoginDialog(context);
      }
    });

    return const Scaffold(
      backgroundColor: Color(0xFF1A1A1A),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF10A37F)),
      ),
    );
  }

  Future<void> _showLoginDialog(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LoginDialog(),
    );

    if (result != null && context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(),
        ),
      );
    }
  }
}

class LoginDialog extends StatefulWidget {
  const LoginDialog({super.key});

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> with SingleTickerProviderStateMixin {
  bool _showEmailLogin = false;
  bool _isSignupMode = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

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
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isStrongPassword(String password) {
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    if (!kIsWeb && Platform.isWindows) {
      _showError('Google Sign-In is not supported on Windows desktop. Please use Guest mode.');
      return;
    }

    try {
      setState(() => _isLoading = true);
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      Navigator.pop(context, googleUser.displayName ?? googleUser.email?.split('@')[0] ?? 'GoogleUser');
    } catch (error) {
      _showError('Google Sign-In failed. Please try again.');
      setState(() => _isLoading = false);
    }
  }

  void _handleGuestLogin() {
    Navigator.pop(context, 'Guest');
  }

  Future<void> _handleEmailLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    if (!_isValidEmail(email)) {
      _showError('Please enter a valid email');
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));

    if (password.length >= 6) {
      final username = email.split('@')[0];
      Navigator.pop(context, username);
    } else {
      _showError('Invalid credentials');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    if (!_isValidEmail(email)) {
      _showError('Please enter a valid email');
      return;
    }

    if (!_isStrongPassword(password)) {
      _showError('Password must be 8+ chars with uppercase, lowercase, and number');
      return;
    }

    if (password != confirmPassword) {
      _showError('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));

    _showSuccess('Account created successfully!');
    setState(() {
      _isSignupMode = false;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 40,
            vertical: isMobile ? 24 : 40,
          ),
          child: Container(
            width: isMobile ? double.infinity : 460,
            constraints: BoxConstraints(
              maxHeight: screenHeight * (isMobile ? 0.9 : 0.85),
              maxWidth: isMobile ? screenWidth - 32 : 460,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E1E1E),
                  Color(0xFF121212),
                ],
              ),
              borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
              border: Border.all(
                color: const Color(0xFF10A37F).withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10A37F).withOpacity(0.2),
                  blurRadius: 40,
                  spreadRadius: 0,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF10A37F).withOpacity(0.12),
                            const Color(0xFF8B5CF6).withOpacity(0.08),
                            const Color(0xFF3B82F6).withOpacity(0.08),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.3, 0.6, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF8B5CF6).withOpacity(0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -80,
                    left: -80,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF3B82F6).withOpacity(0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 24 : 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: isMobile ? 70 : 80,
                          height: isMobile ? 70 : 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF10A37F),
                                Color(0xFF8B5CF6),
                                Color(0xFF3B82F6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(isMobile ? 18 : 22),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10A37F).withOpacity(0.5),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: const Color(0xFF8B5CF6).withOpacity(0.3),
                                blurRadius: 24,
                                offset: const Offset(8, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.auto_awesome,
                            size: isMobile ? 35 : 40,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: isMobile ? 20 : 24),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              Color(0xFF10A37F),
                              Color(0xFF8B5CF6),
                              Color(0xFF3B82F6),
                            ],
                          ).createShader(bounds),
                          child: Text(
                            'Pathify AI',
                            style: TextStyle(
                              fontSize: isMobile ? 30 : 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        SizedBox(height: isMobile ? 10 : 12),
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.9),
                              Colors.white.withOpacity(0.6),
                            ],
                          ).createShader(bounds),
                          child: Text(
                            _showEmailLogin
                                ? (_isSignupMode ? 'Create your account' : 'Welcome back')
                                : 'Your AI Career Companion',
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: isMobile ? 6 : 8),
                        if (!_showEmailLogin)
                          Text(
                            'Unlock personalized guidance\nand career insights',
                            style: TextStyle(
                              fontSize: isMobile ? 13 : 14,
                              color: Colors.grey.shade400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        SizedBox(height: isMobile ? 28 : 36),
                        _showEmailLogin ? _buildEmailForm(isMobile) : _buildSocialButtons(isMobile),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButtons(bool isMobile) {
    return Column(
      children: [
        _buildModernButton(
          icon: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(
              child: Text(
                'G',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4285F4),
                  fontFamily: 'Arial',
                ),
              ),
            ),
          ),
          text: 'Continue with Google',
          onPressed: _handleGoogleSignIn,
          gradient: LinearGradient(
            colors: [
              const Color(0xFF4285F4).withOpacity(0.15),
              const Color(0xFF4285F4).withOpacity(0.08),
            ],
          ),
          borderColor: const Color(0xFF4285F4).withOpacity(0.4),
          isMobile: isMobile,
        ),
        SizedBox(height: isMobile ? 16 : 20),
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade700, thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'OR',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                  fontSize: isMobile ? 12 : 13,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.shade700, thickness: 1)),
          ],
        ),
        SizedBox(height: isMobile ? 16 : 20),
        _buildModernButton(
          icon: const Icon(Icons.email_outlined, size: 22, color: Color(0xFF8B5CF6)),
          text: 'Continue with email',
          onPressed: () => setState(() => _showEmailLogin = true),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF8B5CF6).withOpacity(0.15),
              const Color(0xFF8B5CF6).withOpacity(0.08),
            ],
          ),
          borderColor: const Color(0xFF8B5CF6).withOpacity(0.4),
          textColor: const Color(0xFF8B5CF6),
          isMobile: isMobile,
        ),
        SizedBox(height: isMobile ? 12 : 16),
        _buildModernButton(
          icon: const Icon(Icons.person_outline, size: 22, color: Color(0xFF10A37F)),
          text: 'Continue as Guest',
          onPressed: _handleGuestLogin,
          gradient: LinearGradient(
            colors: [
              const Color(0xFF10A37F).withOpacity(0.2),
              const Color(0xFF10A37F).withOpacity(0.12),
            ],
          ),
          borderColor: const Color(0xFF10A37F).withOpacity(0.5),
          textColor: const Color(0xFF10A37F),
          isMobile: isMobile,
        ),
      ],
    );
  }

  Widget _buildModernButton({
    required Widget icon,
    required String text,
    required VoidCallback onPressed,
    required Gradient gradient,
    Color? borderColor,
    Color? textColor,
    required bool isMobile,
  }) {
    return Container(
      width: double.infinity,
      height: isMobile ? 52 : 56,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        border: borderColor != null
            ? Border.all(color: borderColor, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: borderColor?.withOpacity(0.2) ?? Colors.transparent,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 14),
                Flexible(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 15,
                      fontWeight: FontWeight.w600,
                      color: textColor ?? Colors.white,
                      letterSpacing: 0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm(bool isMobile) {
    if (_isSignupMode) {
      return _buildSignupForm(isMobile);
    }

    return Column(
      children: [
        _buildModernTextField(
          controller: _emailController,
          label: 'Email address',
          hint: 'your.email@example.com',
          icon: Icons.email_outlined,
          iconColor: const Color(0xFF8B5CF6),
          keyboardType: TextInputType.emailAddress,
          isMobile: isMobile,
        ),
        SizedBox(height: isMobile ? 14 : 18),
        _buildModernTextField(
          controller: _passwordController,
          label: 'Password',
          hint: '••••••••',
          icon: Icons.lock_outline,
          iconColor: const Color(0xFF3B82F6),
          isPassword: true,
          obscureText: _obscurePassword,
          onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
          onSubmitted: (_) => _handleEmailLogin(),
          isMobile: isMobile,
        ),
        SizedBox(height: isMobile ? 24 : 28),
        Container(
          width: double.infinity,
          height: isMobile ? 50 : 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF10A37F),
                Color(0xFF8B5CF6),
                Color(0xFF3B82F6),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10A37F).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleEmailLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isLoading
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
                : Text(
              'Continue',
              style: TextStyle(
                fontSize: isMobile ? 15 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        SizedBox(height: isMobile ? 16 : 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Don\'t have an account? ',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: isMobile ? 13 : 14,
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _isSignupMode = true),
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF10A37F), Color(0xFF8B5CF6)],
                ).createShader(bounds),
                child: Text(
                  'Sign up',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 13 : 14,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 8 : 12),
        TextButton.icon(
          onPressed: () => setState(() => _showEmailLogin = false),
          icon: Icon(Icons.arrow_back, size: 18, color: Colors.grey.shade500),
          label: Text(
            'Back to options',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: isMobile ? 13 : 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupForm(bool isMobile) {
    return Column(
      children: [
        _buildModernTextField(
          controller: _nameController,
          label: 'Full name',
          hint: 'John Doe',
          icon: Icons.person_outline,
          iconColor: const Color(0xFF10A37F),
          isMobile: isMobile,
        ),
        SizedBox(height: isMobile ? 14 : 18),
        _buildModernTextField(
          controller: _emailController,
          label: 'Email address',
          hint: 'your.email@example.com',
          icon: Icons.email_outlined,
          iconColor: const Color(0xFF8B5CF6),
          keyboardType: TextInputType.emailAddress,
          isMobile: isMobile,
        ),
        SizedBox(height: isMobile ? 14 : 18),
        _buildModernTextField(
          controller: _passwordController,
          label: 'Password',
          hint: 'Min. 8 characters',
          icon: Icons.lock_outline,
          iconColor: const Color(0xFF3B82F6),
          isPassword: true,
          obscureText: _obscurePassword,
          onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
          isMobile: isMobile,
        ),
        SizedBox(height: isMobile ? 14 : 18),
        _buildModernTextField(
          controller: _confirmPasswordController,
          label: 'Confirm password',
          hint: 'Re-enter password',
          icon: Icons.lock_outline,
          iconColor: const Color(0xFFEC4899),
          isPassword: true,
          obscureText: _obscureConfirmPassword,
          onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          onSubmitted: (_) => _handleSignup(),
          isMobile: isMobile,
        ),
        SizedBox(height: isMobile ? 24 : 28),
        Container(
          width: double.infinity,
          height: isMobile ? 50 : 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF10A37F),
                Color(0xFF8B5CF6),
                Color(0xFF3B82F6),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10A37F).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSignup,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isLoading
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
                : Text(
              'Create account',
              style: TextStyle(
                fontSize: isMobile ? 15 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        SizedBox(height: isMobile ? 16 : 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Already have an account? ',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: isMobile ? 13 : 14,
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _isSignupMode = false),
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF10A37F), Color(0xFF8B5CF6)],
                ).createShader(bounds),
                child: Text(
                  'Sign in',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 13 : 14,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 8 : 12),
        TextButton.icon(
          onPressed: () => setState(() => _showEmailLogin = false),
          icon: Icon(Icons.arrow_back, size: 18, color: Colors.grey.shade500),
          label: Text(
            'Back to options',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: isMobile ? 13 : 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required bool isMobile,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    Function(String)? onSubmitted,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: iconColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onSubmitted: onSubmitted,
        style: TextStyle(
          color: Colors.white,
          fontSize: isMobile ? 14 : 15,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: isMobile ? 13 : 14,
          ),
          hintStyle: TextStyle(
            color: Colors.grey.shade600,
            fontSize: isMobile ? 13 : 14,
          ),
          prefixIcon: Icon(icon, color: iconColor, size: 22),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: Colors.grey.shade500,
              size: 22,
            ),
            onPressed: onToggleVisibility,
          )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 20,
            vertical: isMobile ? 16 : 18,
          ),
        ),
      ),
    );
  }
}
