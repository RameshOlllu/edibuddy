import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/profilesetup/profile_setup_manager.dart';
import 'homepage.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? loggedInUserId;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
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
            'assets/icons/google.png', // Ensure you have this asset
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
      onPressed: _navigateToSignUp,
      child: const Text('Don’t have an account? Sign up here.'),
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
      ),
    );
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user != null) {
        loggedInUserId = user.uid;
        await _handleUserNavigation(user.uid);
      }
    } catch (e) {
      _showErrorDialog('Sign-in failed. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

Future<void> _signInWithGoogle() async {
  if (!mounted) return; // Early return if the widget is not mounted

  setState(() {
    _isLoading = true;
  });

  try {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return; // User canceled the sign-in process

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    final user = userCredential.user;
    if (user != null) {
      loggedInUserId = user.uid;

      // Check if the user document exists in Firestore
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        // Create a new document with `basicDetails`
        await userDoc.set({
          'uid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'profileComplete': false,
          'photoURL': user.photoURL ?? "",
          'basicDetails': {
            'fullName': user.displayName ?? 'N/A',
            'email': user.email ?? 'N/A',
            'dob': null, // Placeholder for DOB
            'gender': null, // Placeholder for Gender
          },
        });
      }

      if (mounted) {
        await _handleUserNavigation(user.uid);
      }
    }
  } catch (e) {
    if (mounted) {
      _showErrorDialog('Google sign-in failed. Please try again.');
    }
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

  Future<void> _handleUserNavigation(String userId) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
    final docSnapshot = await userDoc.get();

    if (docSnapshot.exists && docSnapshot['profileComplete'] == false) {
      _navigateToProfileSetup();
    } else {
      _navigateToHome();
    }
  }

  void _navigateToProfileSetup() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ProfileSetupManager(userId: loggedInUserId!),
      ),
    );
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const HomePage(),
      ),
    );
  }

  void _navigateToSignUp() {
    _showErrorDialog('Sign-Up page is not implemented yet.');
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
