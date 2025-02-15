import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_basic_details.dart';
import '../../widgets/animated_text_field.dart';
import '../../widgets/custom_dropdown.dart';
import 'pay_benefits_screen.dart';
import 'walk_in_interview_screen.dart';

class JobDetailsScreen extends StatefulWidget {
  final String jobId;
  final bool? isEdit;
  final Map<String, dynamic>? jobData;

  JobDetailsScreen({required this.jobId, this.jobData, this.isEdit});

  @override
  _JobDetailsScreenState createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedJobType;
  final _positionsController = TextEditingController();
  final List<String> _selectedSchedules = [];

  final List<String> _jobTypes = [
    'Full-time',
    'Part-time',
    'Permanent',
    'Fresher',
    'Internship',
    'Contractual/Temporary',
    'Freelance',
  ];

  final List<String> _scheduleTypes = [
    'Day shift',
    'Morning shift',
    'Fixed shift',
    'Night shift',
    'US shift',
    'Evening shift',
    'Monday to Friday',
    'Weekend availability',
    'Weekend only',
  ];

  @override
  void initState() {
    super.initState();
    _loadJobData();
  }

  void _loadJobData() {
    if (widget.jobData != null) {
      _selectedJobType = widget.jobData?['jobType'];
      _positionsController.text =
          widget.jobData?['positions']?.toString() ?? '';
      _selectedSchedules.clear();
      _selectedSchedules
          .addAll(List<String>.from(widget.jobData?['schedules'] ?? []));
    }
  }

  Future<void> saveJobDetails() async {
    try {
      final jobDetails = {
        'jobType': _selectedJobType,
        'positions': int.tryParse(_positionsController.text) ?? 0,
        'schedules': _selectedSchedules,
        'updatedAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.jobId)
          .update(jobDetails);

      if (widget.isEdit != null) {
        // Edit flow
        Navigator.pop(context, true);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WalkInInterviewScreen(jobId: widget.jobId),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving job details: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Job Details'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Provide Additional Job Details',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    CustomDropdown(
                      label: 'Job Type',
                      value: _selectedJobType,
                      items: _jobTypes,
                      onChanged: (value) {
                        setState(() => _selectedJobType = value);
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a job type';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AnimatedTextField(
                      controller: _positionsController,
                      label: 'Number of Positions',
                      hint: 'Enter number of positions',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter number of positions';
                        }
                        if (int.tryParse(value!) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Work Schedule',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _scheduleTypes.map((schedule) {
                        final isSelected =
                            _selectedSchedules.contains(schedule);
                        return FilterChip(
                          label: Text(schedule),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedSchedules.add(schedule);
                              } else {
                                _selectedSchedules.remove(schedule);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddJobBasicsScreen(
                            jobId: widget.jobId,
                            jobData: widget.jobData,
                          ),
                        ),
                      );
                    },
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        saveJobDetails();
                      }
                    },
                    child: Text(widget.isEdit != null ? 'Save & Close' : 'Save & Continue'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
