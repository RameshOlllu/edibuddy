// lib/sign_in_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
// Import Firestore if you need to use it
import 'package:cloud_firestore/cloud_firestore.dart';
// Removed unnecessary import
// import 'homepage.dart'; // Not needed as AuthWrapper handles navigation

class SignInPage extends StatefulWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false; // To show a loading indicator

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.signInTitle),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      Text(
                        AppLocalizations.of(context)!.welcomeMessage,
                        style: textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.emailLabel,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!.emailRequired;
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.passwordLabel,
                          border: const OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!.passwordRequired;
                          }
                          if (value.length < 6) {
                            return 'Password should be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _signInWithEmail,
                        child: Text(AppLocalizations.of(context)!.signInButton),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _signInWithGoogle,
                        child: Text(AppLocalizations.of(context)!.signInWithGoogle),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _signInWithInstagram,
                        child: Text(AppLocalizations.of(context)!.signInWithInstagram),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: _navigateToSignUp,
                        child: Text(AppLocalizations.of(context)!.signUpPrompt),
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // Sign in with Email and Password
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

      // Successful sign-in
      print('Signed in as: ${userCredential.user?.email}');

      // No need to navigate manually; AuthWrapper handles it
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        case 'user-disabled':
          message = 'This user has been disabled.';
          break;
        case 'user-not-found':
          message = 'No user found for this email.';
          break;
        case 'wrong-password':
          message = 'Incorrect password.';
          break;
        default:
          message = 'An error occurred. Please try again.';
      }

      _showErrorDialog(message);
    } catch (e) {
      _showErrorDialog('An unexpected error occurred.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Sign in with Google
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      // Successful sign-in
      print('Signed in as: ${userCredential.user?.email}');

      // Optionally, save user data to Firestore
      await _saveUserToFirestore(userCredential.user);
      
      // No need to navigate manually; AuthWrapper handles it
    } on FirebaseAuthException catch (e) {
      _showErrorDialog('Failed to sign in with Google: ${e.message}');
    } catch (e) {
      _showErrorDialog('An unexpected error occurred.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // (Optional) Save user data to Firestore
  Future<void> _saveUserToFirestore(User? user) async {
    if (user == null) return;

    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      await userDoc.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        // Add more fields as necessary
      });
    }
  }

  // Instagram Sign-In (Not natively supported by Firebase)
  void _signInWithInstagram() {
    // Implement Instagram sign-in using a custom OAuth flow or third-party package
    // Firebase Authentication does not support Instagram out of the box
    // Alternatively, use a server-side function to handle Instagram OAuth and provide a custom token to Firebase
    _showErrorDialog('Instagram sign-in is not supported yet.');
  }

  // Navigate to Sign-Up Page
  void _navigateToSignUp() {
    // Implement navigation to SignUpPage if available
    // For example:
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (_) => const SignUpPage()),
    // );
    _showErrorDialog('Sign-Up page is not implemented yet.');
  }

  // Show Error Dialog
  void _showErrorDialog(String message) {
    showDialog<void>(
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
