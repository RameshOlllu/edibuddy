import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/profilesetup/splash_screen_with_tabs.dart';
import '../screens/profilesetup/profile_setup_manager.dart';
import '../service/auth_service.dart';
import 'email_verification_page.dart';
import 'signup_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.primary),
          onPressed: () => _navigateToHomeTab(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildWelcomeBanner(context),
                      const SizedBox(height: 32),
                      _buildSignInForm(),
                      const SizedBox(height: 24),
                      _buildSignInButtons(context, colorScheme),
                      const SizedBox(height: 16),
                      _buildSignUpPrompt(colorScheme),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeBanner(BuildContext context) {
    return Column(
      children: [
        Text(
          'Welcome Back!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to continue',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSignInForm() {
    return Column(
      children: [
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email.';
            }
            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
              return 'Enter a valid email.';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.lock),
          ),
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password.';
            }
            if (value.length < 6) {
              return 'Password should be at least 6 characters.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSignInButtons(BuildContext context, ColorScheme colorScheme) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _signInWithEmail,
          icon: const Icon(Icons.email),
          label: const Text('Sign in with Email'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _signInWithGoogle,
          icon: Image.asset(
            'assets/icons/google.png',
            height: 24,
            width: 24,
          ),
          label: const Text('Sign in with Google'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black54,
            side: const BorderSide(color: Colors.grey),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpPrompt(ColorScheme colorScheme) {
    return TextButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SignUpPage()),
        );
      },
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
      ),
      child: const Text('Don’t have an account? Sign up here.'),
    );
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = await _authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null) {
        await _navigateBasedOnUser(user.uid);
      }
    } catch (e) {
      _showErrorDialog("Sign-in failed. Please try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        await _navigateBasedOnUser(user.uid);
      }
    } catch (e) {
      _showErrorDialog('Google sign-in failed. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateBasedOnUser(String userId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        _showErrorDialog("No user found. Please sign in again.");
        return;
      }

      if (!user.emailVerified) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const EmailVerificationPage()),
        );
        return;
      }

      final isProfileComplete = await _authService.isProfileComplete(userId);

      if (!isProfileComplete) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ProfileSetupManager(
              userId: userId,
              onProfileComplete: _navigateToHomeTab,
            ),
          ),
        );
      } else {
        _navigateToHomeTab();
      }
    } catch (e) {
      _showErrorDialog("An error occurred. Please try again.");
    }
  }

  void _navigateToHomeTab() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) =>  SplashScreenWithTabs()),
      (route) => false, // Clear navigation stack
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
