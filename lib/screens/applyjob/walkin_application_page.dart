import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WalkInApplicationPage extends StatefulWidget {
  final String jobId;

  const WalkInApplicationPage({Key? key, required this.jobId}) : super(key: key);

  @override
  _WalkInApplicationPageState createState() => _WalkInApplicationPageState();
}

class _WalkInApplicationPageState extends State<WalkInApplicationPage> {
  late Future<DocumentSnapshot> _jobFuture;
  Map<String, dynamic>? walkInDetails;
  int? selectedSlotIndex;
  String? resumeUrl;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    _jobFuture = FirebaseFirestore.instance
        .collection('jobs')
        .doc(widget.jobId)
        .get();
  }

  /// Uses FilePicker to select a resume file and uploads it to Firebase Storage.
  Future<void> _pickAndUploadResume() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String fileName =
          'resumes/${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}';

      setState(() {
        isUploading = true;
      });

      try {
        TaskSnapshot snapshot =
            await FirebaseStorage.instance.ref(fileName).putFile(file);
        String downloadUrl = await snapshot.ref.getDownloadURL();
        setState(() {
          resumeUrl = downloadUrl;
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
          isUploading = false;
        });
      }
    }
  }

  /// Submits the walk‑in application with the selected slot and resume.
  Future<void> _submitApplication(Map<String, dynamic> jobData) async {
    if (selectedSlotIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an interview slot')),
      );
      return;
    }
    if (resumeUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please upload your resume')),
      );
      return;
    }

    final String employeeId = FirebaseAuth.instance.currentUser!.uid;
    final selectedSlot = walkInDetails!['slots'][selectedSlotIndex!];
    final String employerId = jobData['userId'];

    await FirebaseFirestore.instance.collection('job_applications').add({
      'jobId': widget.jobId,
      'employeeId': employeeId,
      'employerId': employerId,
      'appliedAt': FieldValue.serverTimestamp(),
      'status': 'Applied',
      'selectedSlot': selectedSlot,
      'resumeUrl': resumeUrl,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Application submitted successfully!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<DocumentSnapshot>(
      future: _jobFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Walk‑In Application'),
              backgroundColor: theme.primaryColor,
              elevation: 0,
            ),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError ||
            !snapshot.hasData ||
            !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Walk‑In Application'),
              backgroundColor: theme.primaryColor,
              elevation: 0,
            ),
            body: Center(child: Text('Error loading job data')),
          );
        }

        final jobData = snapshot.data!.data() as Map<String, dynamic>;
        walkInDetails = jobData['walkInDetails'];

        if (walkInDetails == null || walkInDetails!['hasWalkIn'] != true) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Walk‑In Application'),
              backgroundColor: theme.primaryColor,
              elevation: 0,
            ),
            body: Center(
                child: Text('No walk‑in interview details available for this job.')),
          );
        }

        List slots = walkInDetails!['slots'] ?? [];

        return Scaffold(
          appBar: AppBar(
            title: Text('Select Interview Slot'),
            backgroundColor: theme.primaryColor,
            elevation: 0,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with gradient background.
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.primaryColor, theme.primaryColorLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Available Interview Slots',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Slot selection list wrapped in a Card.
                Expanded(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.separated(
                      padding: EdgeInsets.all(8),
                      itemCount: slots.length,
                      separatorBuilder: (context, index) =>
                          Divider(color: Colors.grey[300]),
                      itemBuilder: (context, index) {
                        final slot = slots[index];
                        final date = (slot['date'] as Timestamp).toDate();
                        final startTime = TimeOfDay(
                          hour: slot['startTime']['hour'],
                          minute: slot['startTime']['minute'],
                        );
                        final endTime = TimeOfDay(
                          hour: slot['endTime']['hour'],
                          minute: slot['endTime']['minute'],
                        );
                        final slotText =
                            '${DateFormat('EEEE, MMMM d').format(date)}\n${startTime.format(context)} - ${endTime.format(context)}';
                        bool isSelected = selectedSlotIndex == index;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              selectedSlotIndex = index;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.primaryColor.withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Radio<int>(
                                  value: index,
                                  groupValue: selectedSlotIndex,
                                  onChanged: (int? value) {
                                    setState(() {
                                      selectedSlotIndex = value;
                                    });
                                  },
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    slotText,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Resume Upload Section inside a Card.
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading:
                        Icon(Icons.upload_file, color: theme.primaryColor),
                    title: Text(
                      resumeUrl != null ? 'Resume Uploaded' : 'Upload Resume',
                      style: theme.textTheme.titleMedium,
                    ),
                    subtitle: resumeUrl != null
                        ? Text('Your resume is ready for submission.')
                        : Text('Please upload your resume (PDF, DOC, DOCX)'),
                    trailing: isUploading
                        ? CircularProgressIndicator()
                        : ElevatedButton.icon(
                            onPressed: _pickAndUploadResume,
                            icon: Icon(Icons.cloud_upload),
                            label: Text('Upload'),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 24),
                // Submit Button.
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _submitApplication(jobData),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Submit Application',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
