import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _gender;
  bool _isLoading = false;
  bool _isEmailUnique = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 32),
                    _buildSignUpForm(),
                    const SizedBox(height: 24),
                    _buildSignUpButton(context, colorScheme),
                    const SizedBox(height: 16),
                    _buildSignInPrompt(colorScheme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Text(
          'Create Your Account',
          style: GoogleFonts.lato(
            textStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Sign up to get started!',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSignUpForm() {
    return Column(
      children: [
        // Full Name
        TextFormField(
          controller: _fullNameController,
          decoration: const InputDecoration(labelText: 'Full Name'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your full name.';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // Date of Birth
        TextFormField(
          controller: _dobController,
          decoration: const InputDecoration(
            labelText: 'Date of Birth',
            suffixIcon: Icon(Icons.calendar_today),
          ),
          readOnly: true,
          onTap: _selectDateOfBirth,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please select your date of birth.';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // Gender
        DropdownButtonFormField<String>(
          value: _gender,
          items: const [
            DropdownMenuItem(value: 'Male', child: Text('Male')),
            DropdownMenuItem(value: 'Female', child: Text('Female')),
            DropdownMenuItem(value: 'Other', child: Text('Other')),
          ],
          onChanged: (value) => setState(() => _gender = value),
          decoration: const InputDecoration(labelText: 'Gender'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select your gender.';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // Email
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => _checkEmailAvailability(),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your email.';
            }
            if (!_isEmailUnique) {
              return 'This email is already registered.';
            }
            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
              return 'Enter a valid email.';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // Password
        TextFormField(
          controller: _passwordController,
          decoration: const InputDecoration(labelText: 'Password'),
          obscureText: true,
          validator: (value) {
            if (value == null || value.length < 6) {
              return 'Password must be at least 6 characters.';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // Confirm Password
        TextFormField(
          controller: _confirmPasswordController,
          decoration: const InputDecoration(labelText: 'Confirm Password'),
          obscureText: true,
          validator: (value) {
            if (value != _passwordController.text) {
              return 'Passwords do not match.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSignUpButton(BuildContext context, ColorScheme colorScheme) {
    return ElevatedButton(
      onPressed: _signUp,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text('Sign Up', style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSignInPrompt(ColorScheme colorScheme) {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: const Text('Already have an account? Sign in here.'),
      style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
    );
  }

  Future<void> _selectDateOfBirth() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (selectedDate != null) {
      _dobController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
    }
  }

  Future<void> _checkEmailAvailability() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      setState(() => _isEmailUnique = true);
      return;
    }

    final signInMethods =
        await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
    setState(() => _isEmailUnique = signInMethods.isEmpty);
  }

Future<void> _signUp() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);
  try {
    // Register User
    final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'Failed to create user. Please try again.',
      );
    }

    // Convert DOB string to Timestamp
    final dobDate = DateFormat('yyyy-MM-dd').parse(_dobController.text.trim());
    final dobTimestamp = Timestamp.fromDate(dobDate);

    // Save Additional Info
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'profileComplete': false,
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
      'basicDetails': {
        'fullName': _fullNameController.text.trim(),
        'dob': dobTimestamp, // Save DOB as Timestamp
        'gender': _gender,
        'email': _emailController.text.trim(),
      },
      'badges': {
        'basicdetails': {
          'earned': true,
          'earnedAt': FieldValue.serverTimestamp(),
        },
      },
    });

    // Send Email Verification
    await user.sendEmailVerification();

    // Navigate to Email Verification Page
    Navigator.pushReplacementNamed(context, '/email-verification');
  } on FirebaseAuthException catch (e) {
    // Enhanced Error Handling
    switch (e.code) {
      case 'email-already-in-use':
        _showErrorDialog('This email is already registered. Please use another email.');
        break;
      case 'weak-password':
        _showErrorDialog('The password is too weak. Please choose a stronger password.');
        break;
      default:
        _showErrorDialog('Signup failed: ${e.message}');
    }
  } catch (e) {
    debugPrint('Error while signup: ${e.toString()}');
    _showErrorDialog('An unexpected error occurred. Please try again.');
  } finally {
    setState(() => _isLoading = false);
  }
}

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
