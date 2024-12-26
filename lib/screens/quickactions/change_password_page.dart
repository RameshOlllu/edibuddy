import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../service/auth_service.dart';

class ChangePasswordPage extends StatefulWidget {
  final bool isGoogleSignIn;
  final AuthService authService;

  const ChangePasswordPage({
    Key? key,
    required this.isGoogleSignIn,
    required this.authService,
  }) : super(key: key);

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = widget.authService.currentUser;
      if (user == null) {
        throw Exception("User not logged in.");
      }

      if (!widget.isGoogleSignIn) {
        // Re-authenticate for email/password users
        await _reauthenticateWithEmail(user);
      } else {
        // Re-authenticate for Google users
        await _reauthenticateWithGoogle();
      }

      // Change the password
      await user.updatePassword(_newPasswordController.text);
      _showSuccessDialog("Password updated successfully.");
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        _showErrorDialog("Your session has expired. Please log in again to change your password.");
      } else {
        _showErrorDialog(e.message ?? "An error occurred. Please try again.");
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _reauthenticateWithEmail(User user) async {
    final currentPassword = _oldPasswordController.text.trim();
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
  }

  Future<void> _reauthenticateWithGoogle() async {
    final googleUser = await widget.authService.signInWithGoogle();
    if (googleUser == null) {
      throw Exception("Google re-authentication failed. Please try again.");
    }
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

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Success"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to the previous page
            },
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
        title: const Text("Change Password"),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!widget.isGoogleSignIn) ...[
                      TextFormField(
                        controller: _oldPasswordController,
                        decoration: const InputDecoration(
                          labelText: "Current Password",
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter your current password.";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _newPasswordController,
                      decoration: const InputDecoration(
                        labelText: "New Password",
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter a new password.";
                        }
                        if (value.length < 6) {
                          return "Password must be at least 6 characters.";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: const InputDecoration(
                        labelText: "Confirm Password",
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value != _newPasswordController.text) {
                          return "Passwords do not match.";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                        child: const Text("Update Password"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
