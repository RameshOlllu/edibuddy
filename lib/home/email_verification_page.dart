import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({Key? key}) : super(key: key);

  @override
  _EmailVerificationPageState createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  Timer? _emailCheckTimer;
  Timer? _resendTimer;
  bool _isResendDisabled = false;
  int _resendTimerValue = 60;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _startEmailVerificationCheck();
  }

  @override
  void dispose() {
    _emailCheckTimer?.cancel();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startEmailVerificationCheck() {
    _emailCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      await _checkEmailVerified();
    });
  }

 Future<void> _checkEmailVerified() async {
  try {
    // Reload user data
    await _auth.currentUser?.reload();

    // Update the _user object to get the latest state
    _user = _auth.currentUser;

    print('Ramesh _checkEmailVerified: ${_user?.emailVerified}');

    if (_user?.emailVerified ?? false) {
      print('Ramesh _checkEmailVerified - Email verified');
      _emailCheckTimer?.cancel(); // Cancel the timer
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } else {
      print('Ramesh _checkEmailVerified - Email not verified');
    }
  } catch (e) {
    print('Ramesh Error in _checkEmailVerified: $e');
    _showErrorDialog("Error verifying email status. Please try again.");
  }
}

  Future<void> _resendVerificationEmail() async {
    setState(() => _isResendDisabled = true);

    try {
      await _user?.sendEmailVerification();
      _startResendCountdown();
    } catch (e) {
      _showErrorDialog("Error sending verification email. Please try again.");
    }
  }

  void _startResendCountdown() {
    _resendTimerValue = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return; // Ensure widget is still mounted
      setState(() {
        if (_resendTimerValue > 0) {
          _resendTimerValue--;
        } else {
          timer.cancel();
          _isResendDisabled = false;
        }
      });
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify Your Email"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/signin');
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.email,
              size: 100,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              "Verification Email Sent",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              "We have sent a verification email to your registered email address. Please check your inbox or spam folder.",
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    await _checkEmailVerified();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text("Refresh"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isResendDisabled ? null : _resendVerificationEmail,
                  icon: const Icon(Icons.send),
                  label: Text(
                    _isResendDisabled ? "Resend in $_resendTimerValue" : "Resend",
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
}
