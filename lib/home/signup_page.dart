import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'otp_verification_page.dart';

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
  final _mobileNumberController = TextEditingController();

  String? _gender;
  String? _workStatus;
  bool _agreeToTerms = false;
  bool _updatesAndPromotions = false;
  bool _isLoading = false;
  bool _isEmailUnique = true;
  bool _isMobileUnique = true;
  bool _isVerifyButtonEnabled = false;
  String? _otpCode;
  String? _verificationId;
  bool _isMobileVerified = false;

  PhoneAuthCredential? _phoneCredential; // Store verified phone credential
String? _oldPhoneNumber; // Store old phone number


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(theme),
                      const SizedBox(height: 40),
                      _buildSignUpForm(theme),
                      const SizedBox(height: 24),
                      _buildMobileVerificationSection(theme),
                      const SizedBox(height: 24),
                      _buildWorkStatus(theme),
                      const SizedBox(height: 32),
                      _buildTermsAndConditions(theme),
                      const SizedBox(height: 32),
                      _buildSignUpButton(theme),
                      const SizedBox(height: 24),
                      _buildSignInPrompt(theme),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Text(
          'Create Your Account',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Sign up to get started!',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  InputDecoration _getInputDecoration(ThemeData theme, String label, {bool isMandatory = false}) {
    return InputDecoration(
      labelText: isMandatory ? '$label *' : label,
      labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.outline),
      ),
      filled: true,
      fillColor: theme.colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildSignUpForm(ThemeData theme) {
    return Column(
      children: [
        TextFormField(
          controller: _fullNameController,
          decoration: _getInputDecoration(theme, 'Full Name', isMandatory: true),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your full name.';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _dobController,
          decoration: _getInputDecoration(theme, 'Date of Birth', isMandatory: true).copyWith(
            suffixIcon: Icon(Icons.calendar_today, color: theme.colorScheme.primary),
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
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: _gender,
          items: ['Male', 'Female', 'Other'].map((value) {
            return DropdownMenuItem(value: value, child: Text(value));
          }).toList(),
          onChanged: (value) => setState(() => _gender = value),
          decoration: _getInputDecoration(theme, 'Gender'),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _emailController,
          decoration: _getInputDecoration(theme, 'Email', isMandatory: true),
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
        const SizedBox(height: 20),
        TextFormField(
          controller: _passwordController,
          decoration: _getInputDecoration(theme, 'Password', isMandatory: true),
          obscureText: true,
          validator: (value) {
            if (value == null || value.length < 6) {
              return 'Password must be at least 6 characters.';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _confirmPasswordController,
          decoration: _getInputDecoration(theme, 'Confirm Password', isMandatory: true),
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

    Widget _buildWorkStatus(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Work Status *',
          style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildWorkStatusOption(theme, 'Experienced', 'I have work experience', 'experienced'),
            _buildWorkStatusOption(theme, 'Fresher', "I am a student / haven't worked yet", 'fresher'),
          ],
        ),
      ],
    );
  }


  Widget _buildWorkStatusOption(ThemeData theme, String title, String subtitle, String value) {
    final isSelected = _workStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _workStatus = value),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.4,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withOpacity(0.2) : theme.colorScheme.surface,
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }


Widget _buildTermsAndConditions(ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Checkbox(
              value: _updatesAndPromotions,
              onChanged: (value) => setState(() => _updatesAndPromotions = value!),
              activeColor: theme.colorScheme.primary,
            ),
            Expanded(
              child: Text(
                'Send me important updates & promotions via SMS, email, and WhatsApp',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _agreeToTerms,
              onChanged: (value) => setState(() => _agreeToTerms = value!),
              activeColor: theme.colorScheme.primary,
            ),
            Expanded(
              child: RichText(
                text: TextSpan(
                  text: 'By clicking Register, you agree to the ',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface),
                  children: [
                    TextSpan(
                      text: 'Terms and Conditions',
                      style: TextStyle(color: theme.colorScheme.primary, decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _openFullScreenDialog(context, 'Terms and Conditions'),
                    ),
                    const TextSpan(text: ' & '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(color: theme.colorScheme.primary, decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _openFullScreenDialog(context, 'Privacy Policy'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }


void _openFullScreenDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Content for $title goes here.'),
        ),
      ),
    );
  }


Widget _buildMobileVerificationSection(ThemeData theme) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Mobile Number Field with Label
      Text(
        'Mobile Number *',
        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          // Mobile Number Input Field
          Expanded(
            child: TextFormField(
              controller: _mobileNumberController,
              decoration: _getInputDecoration(theme, 'Enter your mobile number', isMandatory: false).copyWith(
                prefixText: '+91 ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                helperText: 'Recruiters will contact you on this number.',
                helperStyle: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              keyboardType: TextInputType.phone,
              onChanged: (value) {
                setState(() {
                  // Enable button only for valid numbers
                  _isVerifyButtonEnabled = RegExp(r'^[6-9]\d{9}$').hasMatch(value);
                });
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your mobile number.';
                }
                if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
                  return 'Please enter a valid Indian mobile number.';
                }
                if (!_isMobileUnique) {
                  return 'This mobile number is already registered.';
                }
                return null;
              },
            ),
          ),
          const SizedBox(width: 12),
          // Verify Button
          ElevatedButton(
            onPressed: _isVerifyButtonEnabled
                ? () async {
                    if (_mobileNumberController.text.isNotEmpty) {
                      await _startOtpVerification();
                    }
                  }
                : null,
           
            child: const Text('Verify'),
          ),
        ],
      ),
      const SizedBox(height: 16),

      // Verified Status Message
      if (_isMobileVerified)
        Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Text(
              'Mobile number verified!',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
    ],
  );
}

  Widget _buildSignUpButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_isMobileVerified && _agreeToTerms && _formKey.currentState?.validate() == true)
            ? _signUp
            : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Register Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSignInPrompt(ThemeData theme) {
    return Center(
      child: TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(
          'Already have an account? Sign in here.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
        ),
      ),
    );
  }


Future<void> _startOtpVerification() async {
  final phoneNumber = '+91${_mobileNumberController.text.trim()}';
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => OtpVerificationPage(
        phoneNumber: phoneNumber,
        onVerificationComplete: (isVerified, isMerged, otp) {
          debugPrint('Test isMObile $_isMobileVerified otp $otp');
          setState(() {
            _isMobileVerified = isVerified;

            // Store the OTP if verification was successful
            if (isVerified && otp != null) {
              _otpCode = otp;
            }
          });
        },
      ),
    ),
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

    final signInMethods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
    setState(() => _isEmailUnique = signInMethods.isEmpty);
  }

Future<void> _signUp() async {
  if (!_formKey.currentState!.validate() || !_isMobileVerified) {
    _showErrorDialog('Please complete the form and verify your mobile number.');
    return;
  }

  setState(() => _isLoading = true);

  try {
    final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    final user = credential.user;
    if (user == null) throw FirebaseAuthException(code: 'user-null');

    // Link phone credential if OTP is available
    if (_otpCode != null && _verificationId != null) {
      final phoneCredential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpCode!, // Use the stored OTP
      );
      await user.linkWithCredential(phoneCredential); // Merge accounts
    }

    // Add user details to Firestore
    final dobTimestamp = Timestamp.fromDate(
      DateFormat('yyyy-MM-dd').parse(_dobController.text.trim()),
    );

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'profileComplete': false,
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
      'basicDetails': {
        'fullName': _fullNameController.text.trim(),
        'dob': dobTimestamp,
        'gender': _gender,
        'email': _emailController.text.trim(),
        'mobileNumber': '+91 ${_mobileNumberController.text.trim()}', // Store verified number
        'workStatus': _workStatus,
      },
    });

    Navigator.pushReplacementNamed(context, '/email-verification');
  } catch (e) {
    _showErrorDialog('Signup failed. Please try again.');
  } finally {
    setState(() => _isLoading = false);
  }
}

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
