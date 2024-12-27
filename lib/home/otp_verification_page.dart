import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OtpVerificationPage extends StatefulWidget {
  final String phoneNumber;
  final Function(bool, bool, String?) onVerificationComplete; // Updated callback with OTP parameter

  const OtpVerificationPage({
    Key? key,
    required this.phoneNumber,
    required this.onVerificationComplete,
  }) : super(key: key);

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _verificationId;
  int _remainingSeconds = 40;
  bool _isResendEnabled = false;
  Timer? _timer;
  bool _isVerifying = false;
  bool _isVerifyButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _sendOtp();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _remainingSeconds = 40;
    _isResendEnabled = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _isResendEnabled = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _sendOtp() async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification success
          setState(() => _isVerifying = true);
          await _handleVerification(credential, null);
        },
        verificationFailed: (FirebaseAuthException e) {
          _showErrorDialog(e.message ?? 'Verification failed.');
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() => _verificationId = verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() => _verificationId = verificationId);
        },
      );
    } catch (e) {
      _showErrorDialog('Failed to send OTP. Please try again.');
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text.trim()).join(); // Combine OTP digits
    if (otp.length != 6) {
      _showErrorDialog('Please enter the complete 6-digit OTP.');
      return;
    }

    if (_verificationId == null) {
      _showErrorDialog('Verification ID is null. Please resend OTP.');
      return;
    }

    try {
      setState(() => _isVerifying = true);

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      await _handleVerification(credential, otp); // Pass OTP to handle verification
    } on FirebaseAuthException catch (e) {
      _showErrorDialog(e.message ?? 'Invalid OTP. Please try again.');
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  Future<void> _handleVerification(PhoneAuthCredential credential, String? otp) async {
    final currentUser = _auth.currentUser;

    try {
      if (currentUser != null) {
        // User is already signed in, link the phone number to their account
        await currentUser.linkWithCredential(credential);
        widget.onVerificationComplete(true, true, otp); // Pass OTP to the callback
      } else {
        // Validate OTP without creating an account
        await _auth.signInWithCredential(credential);
        await _auth.signOut(); // Sign out to avoid account creation
        widget.onVerificationComplete(true, false, otp); // Pass OTP to the callback
      }
      Navigator.pop(context);
    } catch (e) {
      _showErrorDialog('Failed to validate OTP or merge account: ${e.toString()}');
      widget.onVerificationComplete(false, false, null); // Pass null OTP on failure
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

  void _onOtpInputChanged() {
    final otp = _otpControllers.map((c) => c.text.trim()).join();
    setState(() => _isVerifyButtonEnabled = otp.length == 6);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP Verification'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            Text(
              'Verify your phone number',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'We have sent an OTP to ${widget.phoneNumber}. Please enter it below to verify.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                6,
                (index) => SizedBox(
                  width: 48,
                  child: TextField(
                    controller: _otpControllers[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        FocusScope.of(context).nextFocus();
                      } else if (value.isEmpty && index > 0) {
                        FocusScope.of(context).previousFocus();
                      }
                      _onOtpInputChanged();
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_isVerifying)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _isVerifyButtonEnabled ? _verifyOtp : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Verify', style: TextStyle(fontSize: 16)),
              ),
            const SizedBox(height: 24),
            if (_isResendEnabled)
              TextButton(
                onPressed: () {
                  _startTimer();
                  _sendOtp();
                },
                child: const Text('Resend OTP'),
              )
            else
              Text(
                'Resend OTP in $_remainingSeconds seconds',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}
