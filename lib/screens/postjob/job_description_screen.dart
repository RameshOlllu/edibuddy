import 'package:edibuddy/screens/postjob/set_preferences_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/rich_text_editor.dart';

class JobDescriptionScreen extends StatefulWidget {
  final String jobId;
  final bool? isEdit;
  final Map<String, dynamic>? jobData;

  JobDescriptionScreen({required this.jobId, this.jobData, this.isEdit});

  @override
  _JobDescriptionScreenState createState() => _JobDescriptionScreenState();
}

class _JobDescriptionScreenState extends State<JobDescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _qualificationsController = TextEditingController();
  final List<String> _requiredSkills = [];

  @override
  void initState() {
    super.initState();
    _loadJobData();
  }

  void _loadJobData() {
    if (widget.jobData != null) {
      _descriptionController.text = widget.jobData?['description'] ?? '';
      _qualificationsController.text = widget.jobData?['qualifications'] ?? '';
      _requiredSkills.clear();
      _requiredSkills
          .addAll(List<String>.from(widget.jobData?['requiredSkills'] ?? []));
    }
  }

  Future<void> saveJobDescription() async {
    try {
      final jobDetails = {
        'description': _descriptionController.text,
        'qualifications': _qualificationsController.text,
        'requiredSkills': _requiredSkills,
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
            builder: (context) => SetPreferencesScreen(jobId: widget.jobId),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving job description: $e')),
      );
    }
  }

  void _addSkill(String skill) {
    if (skill.isNotEmpty && !_requiredSkills.contains(skill)) {
      setState(() {
        _requiredSkills.add(skill);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Job Description'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 80), // Space for buttons
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Define Job Description',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    RichTextEditor(
                      controller: _descriptionController,
                      label: 'Job Description',
                      hint:
                          'Describe the role, responsibilities, and expectations...',
                      minLines: 5,
                      maxLines: 10,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter a job description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    RichTextEditor(
                      controller: _qualificationsController,
                      label: 'Qualifications',
                      hint:
                          'List required qualifications, certifications, and experience...',
                      minLines: 3,
                      maxLines: 6,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter required qualifications';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Required Skills',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._requiredSkills.map((skill) {
                          return Chip(
                            label: Text(skill),
                            onDeleted: () {
                              setState(() {
                                _requiredSkills.remove(skill);
                              });
                            },
                          );
                        }),
                        ActionChip(
                          label: const Text('+ Add Skill'),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => _AddSkillDialog(
                                onAdd: _addSkill,
                              ),
                            );
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
                          saveJobDescription();
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
    _descriptionController.dispose();
    _qualificationsController.dispose();
    super.dispose();
  }
}

class _AddSkillDialog extends StatefulWidget {
  final Function(String) onAdd;

  const _AddSkillDialog({
    Key? key,
    required this.onAdd,
  }) : super(key: key);

  @override
  State<_AddSkillDialog> createState() => _AddSkillDialogState();
}

class _AddSkillDialogState extends State<_AddSkillDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Required Skill'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: 'Enter skill name',
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onAdd(_controller.text);
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
