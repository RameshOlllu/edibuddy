import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';

class ResumeOverviewScreen extends StatefulWidget {
  final String userId;

  const ResumeOverviewScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  _ResumeOverviewScreenState createState() => _ResumeOverviewScreenState();
}

class _ResumeOverviewScreenState extends State<ResumeOverviewScreen> {
  String? uploadedFileUrl;
  String? uploadedFileName;
  bool isUploading = false;
  double uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadExistingResume();
  }

  Future<void> _loadExistingResume() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (doc.exists && doc.data()?['resumeUrl'] != null) {
        final resumeUrl = doc.data()?['resumeUrl'] as String;
        setState(() {
          uploadedFileUrl = resumeUrl;
          uploadedFileName =
              Uri.decodeFull(resumeUrl.split('/').last.split('?').first);
        });
      }
    } catch (e) {
      _showSnackBar("Failed to load existing resume.", isError: true);
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
          await _deleteExistingResumeFile();
        }

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('resumes/${widget.userId}/$fileName');
        final uploadTask = storageRef.putFile(file);

        uploadTask.snapshotEvents.listen((event) {
          setState(() {
            uploadProgress = event.bytesTransferred / event.totalBytes;
          });
        });

        final snapshot = await uploadTask;
        final newFileUrl = await snapshot.ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .update({'resumeUrl': newFileUrl});

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
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await _deleteExistingResumeFile();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .update({'resumeUrl': FieldValue.delete()});

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

  Future<void> _deleteExistingResumeFile() async {
    if (uploadedFileUrl != null) {
      final storageRef = FirebaseStorage.instance.refFromURL(uploadedFileUrl!);
      await storageRef.delete();
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  Widget _buildResumeCard() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Card(
          elevation: 8,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.surface,
                  colorScheme.surface.withOpacity(0.8),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.description_rounded,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Resume',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              uploadedFileName ?? 'No Resume Uploaded',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _viewResume,
                        icon: const Icon(Icons.open_in_new),
                        label: const Text("View Resume"),
                      ),
                      ElevatedButton.icon(
                        onPressed: _deleteResume,
                        icon: const Icon(Icons.delete),
                        label: const Text("Delete"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.upload_file_rounded, size: 80, color: Colors.grey),
        const SizedBox(height: 16),
        Text(
          "No Resume Uploaded",
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Overview'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, uploadedFileUrl);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isUploading)
                      Column(
                        children: [
                          const SizedBox(height: 16),
                          LinearProgressIndicator(value: uploadProgress),
                          const SizedBox(height: 16),
                          Text(
                            "Uploading... ${(uploadProgress * 100).toStringAsFixed(0)}%",
                          ),
                        ],
                      )
                    else if (uploadedFileUrl != null)
                      _buildResumeCard()
                    else
                      _buildEmptyState(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickAndUploadFile,
        icon: const Icon(Icons.upload),
        label: const Text("Upload"),
      ),
    );
  }

  Future<void> _viewResume() async {
    if (uploadedFileUrl != null) {
      final Uri uri = Uri.parse(uploadedFileUrl!);
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          _showSnackBar("No application available to open this file.",
              isError: true);
        }
      } catch (e) {
        _showSnackBar("Failed to open resume: ${e.toString()}", isError: true);
      }
    } else {
      _showSnackBar("No resume available to view.", isError: true);
    }
  }
}
