import 'package:edibuddy/screens/postjob/review_confirm_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/animated_text_field.dart';

class SetPreferencesScreen extends StatefulWidget {
  final String jobId;
  final Map<String, dynamic>? jobData;
  final bool? isEdit;

  SetPreferencesScreen({required this.jobId, this.jobData, this.isEdit});

  @override
  _SetPreferencesScreenState createState() => _SetPreferencesScreenState();
}

class _SetPreferencesScreenState extends State<SetPreferencesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  bool _requireCV = true;
  bool _allowOptionalCV = false;

  @override
  void initState() {
    super.initState();
    _loadJobData();
  }

  void _loadJobData() {
    if (widget.jobData != null) {
      _mobileController.text = widget.jobData?['applicantContact'] ?? '';
      _emailController.text = widget.jobData?['dailyUpdatesEmail'] ?? '';
      _requireCV = widget.jobData?['requireCV'] ?? true;
      _allowOptionalCV = widget.jobData?['allowOptionalCV'] ?? false;
    }
  }

  Future<void> savePreferences() async {
    try {
      final preferences = {
        'applicantContact': _mobileController.text,
        'dailyUpdatesEmail': _emailController.text,
        'requireCV': _requireCV,
        'allowOptionalCV': _allowOptionalCV,
        'updatedAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.jobId)
          .update(preferences);
      if (widget.isEdit != null) {
        // Edit flow
        Navigator.pop(context, true);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReviewAndConfirmScreen(jobId: widget.jobId),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving preferences: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Set Preferences'),
      ),
      body: Stack(
        children: [
          Padding(
            padding:
                const EdgeInsets.only(bottom: 80), // Space for bottom buttons
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Applicant Communication',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    AnimatedTextField(
                      controller: _mobileController,
                      label: 'Mobile Number',
                      hint: 'Enter a mobile number for candidates to contact',
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter a valid mobile number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AnimatedTextField(
                      controller: _emailController,
                      label: 'Daily Updates Email',
                      hint: 'Enter an email to receive application summaries',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Application Preferences',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RadioListTile<bool>(
                          title: const Text('Yes, require a CV'),
                          value: true,
                          groupValue: _requireCV,
                          onChanged: (value) {
                            setState(() {
                              _requireCV = value!;
                              _allowOptionalCV =
                                  false; // Reset optional CV if requiring a CV
                            });
                          },
                        ),
                        RadioListTile<bool>(
                          title: const Text("No, don't ask for a CV"),
                          value: false,
                          groupValue: _requireCV,
                          onChanged: (value) {
                            setState(() {
                              _requireCV = value!;
                            });
                          },
                        ),
                        if (!_requireCV)
                          CheckboxListTile(
                            title: const Text(
                                'Allow candidates to attach a CV if they wish'),
                            value: _allowOptionalCV,
                            onChanged: (value) {
                              setState(() {
                                _allowOptionalCV = value!;
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: theme.scaffoldBackgroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          savePreferences();
                        }
                      },
                      child: Text(widget.isEdit != null
                          ? 'Save & Close'
                          : 'Save & Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
