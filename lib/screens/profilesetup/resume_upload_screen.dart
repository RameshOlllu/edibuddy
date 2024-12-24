import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lottie/lottie.dart';

import '../../service/resume_serivce.dart';

class ResumeUploadScreen extends StatefulWidget {
  final String userId;

  const ResumeUploadScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ResumeUploadScreen> createState() => _ResumeUploadScreenState();
}

class _ResumeUploadScreenState extends State<ResumeUploadScreen> {
  final ResumeService _resumeService = ResumeService();

  String? uploadedFileName;
  String? uploadedFileUrl;
  bool isUploading = false;
  double uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadExistingResume();
  }

  Future<void> _loadExistingResume() async {
    try {
      final resumeUrl = await _resumeService.fetchResumeUrl(widget.userId);
      if (resumeUrl != null) {
        setState(() {
          uploadedFileUrl = resumeUrl;

          // Extract file name from URL (removing storage folder and query params)
          uploadedFileName =
              Uri.decodeFull(resumeUrl.split('/').last.split('?').first);
        });
      }
    } catch (e) {
      _showSnackBar('Failed to load existing resume.', isError: true);
    }
  }

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;

        if (file.lengthSync() > 5 * 1024 * 1024) {
          _showSnackBar("File size exceeds 5 MB.", isError: true);
          return;
        }

        setState(() {
          isUploading = true;
          uploadProgress = 0.0;
          uploadedFileName = fileName;
        });

        if (uploadedFileUrl != null) {
          await _resumeService.deleteResume(uploadedFileUrl!, widget.userId);
        }

        final newFileUrl = await _resumeService.uploadResume(
            widget.userId, file.path, fileName);
        await _resumeService.updateResumeUrl(widget.userId, newFileUrl);

        setState(() {
          uploadedFileUrl = newFileUrl;
          isUploading = false;
        });

        _showSnackBar("Resume uploaded successfully!");
      }
    } catch (e) {
      setState(() => isUploading = false);
      _showSnackBar("Failed to upload resume.", isError: true);
    }
  }

  Future<void> _deleteResume() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Resume"),
        content: const Text("Are you sure you want to delete this resume?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("No")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Yes")),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await _resumeService.deleteResume(uploadedFileUrl!, widget.userId);
        setState(() {
          uploadedFileUrl = null;
          uploadedFileName = null;
        });
        _showSnackBar("Resume deleted successfully!");
      } catch (e) {
        _showSnackBar("Failed to delete resume.", isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

void _completeProfile() async {
  if (uploadedFileUrl == null) {
    _showSnackBar("Please upload your resume first!", isError: true);
    return;
  }

  try {
    // Mark the user's profile as complete
    await _resumeService.updateUserProfileStatus(widget.userId, true);

    // Show a success dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset('assets/animations/congratulations.json', repeat: false),
              const Text(
                "Congratulations!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Text(
                "Your profile setup is complete!",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                child: const Text("Go to Home"),
              ),
            ],
          ),
        ),
      ),
    );
  } catch (e) {
    _showSnackBar("Failed to mark profile as complete. Please try again.", isError: true);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Upload'),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (isUploading)
                        Column(
                          children: [
                            Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                height: 150,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Uploading: ${(uploadProgress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ],
                        )
                      else if (uploadedFileUrl != null)
                        Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ListTile(
                            leading: const Icon(Icons.description,
                                size: 36, color: Colors.blue),
                            title: Text(
                              uploadedFileName ?? 'Resume',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle:
                                const Text("Tap below to update or delete"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: _deleteResume,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.upload_file,
                                      color: Colors.blue),
                                  onPressed: _pickAndUploadFile,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                      .withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(24),
                                child: const Icon(
                                  Icons.upload_file,
                                  size: 80,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                "Upload Your Resume!",
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Showcase your experience and get tailored job opportunities.",
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _pickAndUploadFile,
                                icon: const Icon(Icons.upload),
                                label: const Text("Upload Resume"),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(180, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              Container(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                      .withOpacity(0.1),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.3),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.info_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "File Upload Guidelines",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            "• Only .pdf or .docx files are allowed.\n"
                                            "• Maximum file size is 5MB.\n"
                                            "• Uploading is quick and secure.",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Column(
                                      children: [
                                        _buildBenefitItem(
                                          icon: Icons.school_rounded,
                                          backgroundColor: Colors.blue.shade100,
                                          iconColor: Colors.blue.shade700,
                                          text:
                                              "Fast-track your teaching career with top jobs",
                                        ),
                                        const SizedBox(height: 12),
                                        _buildBenefitItem(
                                          icon: Icons.phone_callback_rounded,
                                          backgroundColor:
                                              Colors.green.shade100,
                                          iconColor: Colors.green.shade700,
                                          text:
                                              "Get direct calls from school recruiters",
                                        ),
                                        const SizedBox(height: 12),
                                        _buildBenefitItem(
                                          icon: Icons.insights_rounded,
                                          backgroundColor:
                                              Colors.purple.shade100,
                                          iconColor: Colors.purple.shade700,
                                          text:
                                              "Discover roles tailored to your expertise",
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: uploadedFileUrl != null ? _completeProfile : null,
            child: const Text("Complete Profile"),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
