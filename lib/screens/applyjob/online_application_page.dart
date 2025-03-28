import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class OnlineApplicationPage extends StatefulWidget {
  final String jobId;

  const OnlineApplicationPage({Key? key, required this.jobId}) : super(key: key);

  @override
  _OnlineApplicationPageState createState() => _OnlineApplicationPageState();
}

class _OnlineApplicationPageState extends State<OnlineApplicationPage> {
  final _formKey = GlobalKey<FormState>();
  final _additionalDetailsController = TextEditingController();
  String? _noticePeriodValue;
  String _noticePeriodType = 'Days'; // Default selection
  String? _resumeUrl;
  bool _isUploading = false;

  /// Picks and uploads resume
  Future<void> _pickAndUploadResume() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String fileName = 'resumes/${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}';

      setState(() {
        _isUploading = true;
      });

      try {
        TaskSnapshot snapshot = await FirebaseStorage.instance.ref(fileName).putFile(file);
        String downloadUrl = await snapshot.ref.getDownloadURL();
        setState(() {
          _resumeUrl = downloadUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resume uploaded successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading resume: $e')),
        );
      } finally {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  /// Submits the application
  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    final String employeeId = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('job_applications').add({
      'jobId': widget.jobId,
      'employeeId': employeeId,
      'appliedAt': FieldValue.serverTimestamp(),
      'status': 'Applied',
      'additionalDetails': _additionalDetailsController.text.trim(),
      'noticePeriod': _noticePeriodValue != null ? '$_noticePeriodValue $_noticePeriodType' : 'Not specified',
      'resumeUrl': _resumeUrl,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Application submitted successfully!')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Apply for Job'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 16),

              /// **Additional Details Text Box**
              Text(
                'Additional Details',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _additionalDetailsController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Mention anything relevant for the recruiter...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              /// **Notice Period Selection**
              Text(
                'Notice Period',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter duration',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _noticePeriodValue = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _noticePeriodType,
                    items: ['Days', 'Months']
                        .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _noticePeriodType = value!;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              /// **Upload Resume Section**
              Text(
                'Upload Resume',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickAndUploadResume,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.primary),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.upload_file, color: theme.colorScheme.primary),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            _resumeUrl != null ? 'Resume Uploaded' : 'Tap to Upload Resume (PDF, DOC, DOCX)',
                            style: theme.textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (_isUploading) CircularProgressIndicator(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),

      /// **Fixed Submit Button in Bottom Navigation Bar**
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _submitApplication,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            'Submit Application',
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _additionalDetailsController.dispose();
    super.dispose();
  }
}
