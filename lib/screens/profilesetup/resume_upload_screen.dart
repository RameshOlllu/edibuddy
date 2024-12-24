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
          uploadedFileName = Uri.decodeFull(resumeUrl.split('/').last.split('?').first);
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

        final newFileUrl = await _resumeService.uploadResume(widget.userId, file.path, fileName);
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes")),
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

  void _completeProfile() {
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
              const Text("Your profile setup is complete!", textAlign: TextAlign.center),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resume Upload'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
                  Text('Uploading: ${(uploadProgress * 100).toStringAsFixed(0)}%'),
                ],
              )
            else if (uploadedFileUrl != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.description, size: 36, color: Colors.blue),
                  title: Text('Resume'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: _deleteResume),
                      IconButton(icon: const Icon(Icons.upload_file, color: Colors.blue), onPressed: _pickAndUploadFile),
                    ],
                  ),
                ),
              ),
            ElevatedButton.icon(
              onPressed: _pickAndUploadFile,
              icon: const Icon(Icons.upload_file),
              label: const Text("Upload Resume"),
            ),
          ],
        ),
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
}
