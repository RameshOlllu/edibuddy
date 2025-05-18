import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lottie/lottie.dart';
import '../../service/resume_serivce.dart';
import 'congratulations_page.dart';

class ResumeUploadScreen extends StatefulWidget {
  final String userId;
  final VoidCallback onProfileComplete;

  const ResumeUploadScreen({
    Key? key,
    required this.userId,
    required this.onProfileComplete,
  }) : super(key: key);

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

  // Previous methods remain unchanged...
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
  if (uploadedFileUrl == null && false) {
    if (mounted) {
      _showSnackBar("Please upload your resume first!", isError: true);
    }
    return;
  }

  try {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();

    if (!userDoc.exists || userDoc.data() == null) {
      if (mounted) {
        _showSnackBar("User data not found. Please try again.", isError: true);
      }
      return;
    }

    final userData = userDoc.data()!;
    final stars = _calculateStars(userData);
    final hearts = _calculateHearts(userData);

    // await _resumeService.updateUserProfileStatus(widget.userId, stars >= 3, stars, hearts);
    await _resumeService.updateUserProfileStatus(widget.userId, true, stars, hearts);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CongratulationsPage(stars: stars, hearts: hearts),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      _showSnackBar("Failed to complete profile. Please try again.", isError: true);
    }
    debugPrint("Error in _completeProfile: $e");
  }
}

int _calculateStars(Map<String, dynamic> userData) {
  final educationDetails = userData['educationDetails'] as List<dynamic>;
  final degrees = educationDetails.map((edu) => edu['degree'] as String).toList();

  bool hasBachelor = degrees.any((degree) => degree.contains("Bachelor"));
  bool hasBEd = degrees.any((degree) => degree.contains("B.Ed"));
  bool hasPrimaryCertification = degrees.any((degree) => degree.contains("Primary Teaching Certification"));
  bool hasMaster = degrees.any((degree) => degree.contains("Master"));
  bool hasHigherEducation = degrees.any((degree) => degree.contains("M.Ed") || degree.contains("PhD") || degree.contains("Doctorate"));

  int stars = 0;

  // Star calculation logic
  if (hasBachelor) stars = 1;
  if (hasBachelor && hasBEd) stars = 2;
  if (hasBachelor && hasBEd && hasPrimaryCertification) stars = 3;
  if (hasBachelor && hasBEd && hasMaster) stars = 4;
  if (hasBachelor && hasBEd && hasMaster && hasHigherEducation) stars = 5;

  return stars;
}


int _calculateHearts(Map<String, dynamic> userData) {
  final experienceDetails = userData['experienceDetails'] as List<dynamic>;
  final awards = userData['awards'] as List<dynamic>;

  int totalYears = 0;

  for (var exp in experienceDetails) {
    final startDate = DateTime.parse(exp['startDate'] as String);
    final endDate = exp['isCurrentlyWorking'] == true
        ? DateTime.now()
        : DateTime.parse(exp['endDate'] as String);

    totalYears += endDate.difference(startDate).inDays ~/ 365;
  }

  int hearts = 0;

  if (totalYears <= 5) {
    hearts = 1;
  } else if (totalYears <= 8) {
    hearts = 2;
  } else if (totalYears <= 10) {
    hearts = 3;
  } else if (totalYears > 10) {
    hearts = 4;
  }

  if (awards.isNotEmpty) hearts++;

  return hearts;
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
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Showcase your skills and experience',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.picture_as_pdf_rounded,
                                  color: colorScheme.secondary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      uploadedFileName ?? 'Current Resume',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Ensure your resume is up-to-date',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: _deleteResume,
                                    icon: const Icon(Icons.delete_rounded),
                                    tooltip: 'Delete Resume',
                                    style: IconButton.styleFrom(
                                      backgroundColor: colorScheme.errorContainer.withOpacity(0.3),
                                      foregroundColor: colorScheme.error,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: _pickAndUploadFile,
                                    icon: const Icon(Icons.upload_rounded),
                                    tooltip: 'Update Resume',
                                    style: IconButton.styleFrom(
                                      backgroundColor: colorScheme.primaryContainer.withOpacity(0.3),
                                      foregroundColor: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (isUploading) ...[
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: uploadProgress,
                                    backgroundColor: colorScheme.primaryContainer.withOpacity(0.3),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Uploading... ${(uploadProgress * 100).toStringAsFixed(0)}%',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
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
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(32),
          child: Icon(
            Icons.upload_file_rounded,
            size: 64,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Upload Your Resume!",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            "Showcase your experience and get tailored job opportunities.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: _pickAndUploadFile,
          icon: const Icon(Icons.upload_rounded),
          label: const Text("Upload Resume"),
          style: FilledButton.styleFrom(
            minimumSize: const Size(200, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 32),
        _buildUploadGuidelines(),
        const SizedBox(height: 32),
        _buildBenefitsSection(),
      ],
    );
  }

  Widget _buildUploadGuidelines() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.1),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.info_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "File Upload Guidelines",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildGuidelineItem(
            icon: Icons.description_rounded,
            text: "Only .pdf or .docx files are allowed",
          ),
          const SizedBox(height: 8),
          _buildGuidelineItem(
            icon: Icons.storage_rounded,
            text: "Maximum file size is 5MB",
          ),
          const SizedBox(height: 8),
          _buildGuidelineItem(
            icon: Icons.security_rounded,
            text: "Uploading is quick and secure",
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelineItem({
    required IconData icon,
    required String text,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: colorScheme.primary.withOpacity(0.7),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Benefits",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildBenefitItem(
            icon: Icons.school_rounded,
            backgroundColor: Colors.blue.shade50,
            iconColor: Colors.blue.shade700,
            text: "Fast-track your teaching career with top jobs",
          ),
          const SizedBox(height: 12),
          _buildBenefitItem(
            icon: Icons.phone_callback_rounded,
            backgroundColor: Colors.green.shade50,
            iconColor: Colors.green.shade700,
            text: "Get direct calls from school recruiters",
          ),
          const SizedBox(height: 12),
          _buildBenefitItem(
            icon: Icons.insights_rounded,
            backgroundColor: Colors.purple.shade50,
            iconColor: Colors.purple.shade700,
            text: "Discover roles tailored to your expertise",
          ),
        ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
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
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    if (isUploading || uploadedFileUrl != null)
                      _buildResumeCard()
                    else
                      _buildEmptyState(),
                  ],
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
            // onPressed: uploadedFileUrl != null ? _completeProfile : null,
          onPressed: _completeProfile,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              "Complete Profile",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}