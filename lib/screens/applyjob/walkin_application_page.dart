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
  final _formKey = GlobalKey<FormState>();
  final _additionalDetailsController = TextEditingController();
  String? _noticePeriodValue;
  String _noticePeriodType = 'Days';
  String? _resumeUrl;
  bool _isUploading = false;
  int? _selectedSlotIndex;
  Map<String, dynamic>? _walkInDetails;
  late Future<DocumentSnapshot> _jobFuture;

  @override
  void initState() {
    super.initState();
    _jobFuture = FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).get();
  }

  /// Picks and uploads a resume
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
  Future<void> _submitApplication(Map<String, dynamic> jobData) async {
    if (_selectedSlotIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an interview slot')),
      );
      return;
    }

    final String employeeId = FirebaseAuth.instance.currentUser!.uid;
    final selectedSlot = _walkInDetails!['slots'][_selectedSlotIndex!];
    final String employerId = jobData['userId'];

    await FirebaseFirestore.instance.collection('job_applications').add({
      'jobId': widget.jobId,
      'employeeId': employeeId,
      'employerId': employerId,
      'appliedAt': FieldValue.serverTimestamp(),
      'status': 'Applied',
      'selectedSlot': selectedSlot,
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

    return FutureBuilder<DocumentSnapshot>(
      future: _jobFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text('Walk‑In Application')),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: Text('Walk‑In Application')),
            body: Center(child: Text('Error loading job data')),
          );
        }

        final jobData = snapshot.data!.data() as Map<String, dynamic>;
        _walkInDetails = jobData['walkInDetails'];

        if (_walkInDetails == null || _walkInDetails!['hasWalkIn'] != true) {
          return Scaffold(
            appBar: AppBar(title: Text('Walk‑In Application')),
            body: Center(child: Text('No walk‑in interview details available for this job.')),
          );
        }

        List slots = _walkInDetails!['slots'] ?? [];

        return Scaffold(
          appBar: AppBar(title: Text('Apply for Walk‑In Interview')),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const SizedBox(height: 16),

                  /// **Interview Slot Selection**
                  Text('Select Interview Slot', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: List.generate(slots.length, (index) {
                        final slot = slots[index];
                        final date = (slot['date'] as Timestamp).toDate();
                        final startTime = TimeOfDay(hour: slot['startTime']['hour'], minute: slot['startTime']['minute']);
                        final endTime = TimeOfDay(hour: slot['endTime']['hour'], minute: slot['endTime']['minute']);
                        final slotText = '${DateFormat('EEEE, MMM d').format(date)}\n${startTime.format(context)} - ${endTime.format(context)}';
                        bool isSelected = _selectedSlotIndex == index;

                        return ListTile(
                          title: Text(slotText),
                          leading: Radio<int>(
                            value: index,
                            groupValue: _selectedSlotIndex,
                            onChanged: (int? value) {
                              setState(() {
                                _selectedSlotIndex = value;
                              });
                            },
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 24),

                  /// **Additional Details Text Box**
                  Text('Additional Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _additionalDetailsController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Mention anything relevant for the recruiter...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  /// **Notice Period Selection**
                  Text('Notice Period', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Enter duration',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                        items: ['Days', 'Months'].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                        onChanged: (value) {
                          setState(() {
                            _noticePeriodType = value!;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  /// **Resume Upload Section**
                  Text('Upload Resume', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _pickAndUploadResume,
                    icon: Icon(Icons.upload_file),
                    label: Text(_resumeUrl != null ? 'Resume Uploaded' : 'Upload Resume (PDF, DOC, DOCX)'),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => _submitApplication(jobData),
              child: Text('Submit Application'),
            ),
          ),
        );
      },
    );
  }
}
