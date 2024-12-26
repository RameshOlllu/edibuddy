import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import '../../data/experience_data.dart';
import 'skill_selection_screen.dart';

class AddExperienceScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic>? existingExperience;

  const AddExperienceScreen({
    Key? key,
    required this.userId,
    this.existingExperience,
  }) : super(key: key);

  @override
  State<AddExperienceScreen> createState() => _AddExperienceScreenState();
}

class _AddExperienceScreenState extends State<AddExperienceScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool isCurrentlyWorking = false;
  List<String> selectedJobRoles = [];
  List<String> filteredSuggestions = [];
  List<String> selectedSkills = [];
  TextEditingController searchController = TextEditingController();
  String? selectedEmploymentType;

  final List<String> employmentTypes = [
    'Full-time',
    'Part-time',
    'Internship',
    'Freelance',
    'Contract',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingExperience != null) {
      isCurrentlyWorking = widget.existingExperience!['isCurrentlyWorking'] ?? false;
      selectedJobRoles = List<String>.from(widget.existingExperience!['jobRole'] ?? []);
      selectedSkills = List<String>.from(widget.existingExperience!['skills'] ?? []);
      selectedEmploymentType = widget.existingExperience!['employmentType'];
    }
    filteredSuggestions = ExperienceData.getAllJobTitles();
    searchController.addListener(_filterSuggestions);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _filterSuggestions() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredSuggestions = ExperienceData.getAllJobTitles()
          .where((role) => role.toLowerCase().contains(query))
          .toList();
    });
  }

  void _openJobRoleSelectionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void filterSuggestions(String input) {
              final regex = RegExp(r'^[a-zA-Z\s]*$'); // Allow only alphabets and spaces.
              if (regex.hasMatch(input)) {
                setModalState(() {
                  filteredSuggestions = ExperienceData.getAllJobTitles()
                      .where((role) => role.toLowerCase().contains(input.toLowerCase()))
                      .toList();
                });
              } else {
                setModalState(() {
                  filteredSuggestions = [];
                });
              }
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: "Search Job Roles",
                      hintText: "Type to search...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      filterSuggestions(value); // Dynamically filter suggestions as user types.
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: filteredSuggestions.isEmpty
                        ? const Center(child: Text("No suggestions found"))
                        : ListView(
                            children: filteredSuggestions.map((role) {
                              final isSelected = selectedJobRoles.contains(role);
                              return ListTile(
                                title: Text(role),
                                trailing: isSelected
                                    ? IconButton(
                                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                                        onPressed: () {
                                          setModalState(() {
                                            selectedJobRoles.remove(role);
                                          });
                                          setState(() {});
                                        },
                                      )
                                    : IconButton(
                                        icon: const Icon(Icons.add_circle, color: Colors.green),
                                        onPressed: () {
                                          if (selectedJobRoles.length < 10) {
                                            setModalState(() {
                                              selectedJobRoles.add(role);
                                            });
                                            setState(() {});
                                          }
                                        },
                                      ),
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openSkillSelectionModal() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => SkillSelectionScreen(selectedSkills: selectedSkills),
      ),
    );

    if (result != null) {
      setState(() {
        selectedSkills = result;
      });
    }
  }

  Future<void> _saveExperience() async {
    if (!_formKey.currentState!.saveAndValidate()) return;

    final formData = _formKey.currentState!.value;
    final startDate = formData['startDate'] as DateTime;
    final endDate = formData['isCurrentlyWorking']
        ? null
        : formData['endDate'] as DateTime;

    if (!formData['isCurrentlyWorking'] &&
        endDate != null &&
        startDate.add(const Duration(days: 30)).isAfter(endDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("The duration between start and end dates must be at least one month."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (startDate.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("The start date cannot be in the future."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final experience = {
      'jobTitle': formData['jobTitle'],
      'jobRole': selectedJobRoles,
      'description': formData['description'],
      'skills': selectedSkills,
      'institutionName': formData['institutionName'],
      'industry': formData['industry'],
      'employmentType': selectedEmploymentType,
      'isCurrentlyWorking': formData['isCurrentlyWorking'] ?? false,
      'startDate': formData['startDate']?.toIso8601String(),
      'endDate': formData['isCurrentlyWorking'] ? null : formData['endDate']?.toIso8601String(),
    };

    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(widget.userId);
      final userSnapshot = await userDoc.get();

      if (userSnapshot.exists) {
        final experiences = List<Map<String, dynamic>>.from(userSnapshot.data()?['experienceDetails'] ?? []);

        if (widget.existingExperience != null) {
          final index = experiences.indexWhere((exp) =>
              exp['jobTitle'] == widget.existingExperience!['jobTitle'] &&
              exp['institutionName'] == widget.existingExperience!['institutionName']);
          if (index != -1) {
            experiences[index] = experience;
          }
        } else {
          experiences.add(experience);
        }

        await userDoc.update({'experienceDetails': experiences,'badges.experience': {
          'earned': true,
          'earnedAt': FieldValue.serverTimestamp(),
        },},);
      } else {
        await userDoc.set({'experienceDetails': [experience]});
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to save experience: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Experience"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FormBuilder(
          key: _formKey,
          child: ListView(
            children: [
              FormBuilderTextField(
                name: 'jobTitle',
                decoration: InputDecoration(
                  labelText: 'Job Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: FormBuilderValidators.required(),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _openJobRoleSelectionModal(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: selectedJobRoles.isEmpty
                        ? 'Job Roles'
                        : 'Selected Job Roles (${selectedJobRoles.length})',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: selectedJobRoles.map((role) {
                      return Chip(
                        label: Text(role, style: const TextStyle(fontSize: 10)),
                        onDeleted: () {
                          setState(() {
                            selectedJobRoles.remove(role);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _openSkillSelectionModal,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: selectedSkills.isEmpty
                        ? 'Skills'
                        : 'Selected Skills (${selectedSkills.length})',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: selectedSkills.map((skill) {
                      return Chip(
                        label: Text(skill, style: const TextStyle(fontSize: 10)),
                        onDeleted: () {
                          setState(() {
                            selectedSkills.remove(skill);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FormBuilderDropdown(
                name: 'employmentType',
                initialValue: selectedEmploymentType,
                items: employmentTypes
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                decoration: InputDecoration(
                  labelText: 'Employment Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: FormBuilderValidators.required(),
                onChanged: (value) {
                  setState(() {
                    selectedEmploymentType = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'institutionName',
                decoration: InputDecoration(
                  labelText: 'Institution Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: FormBuilderValidators.required(),
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'industry',
                decoration: InputDecoration(
                  labelText: 'Industry',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FormBuilderDateTimePicker(
                      name: 'startDate',
                      decoration: InputDecoration(
                        labelText: 'Start Date',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      inputType: InputType.date,
                      validator: FormBuilderValidators.required(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FormBuilderDateTimePicker(
                      name: 'endDate',
                      decoration: InputDecoration(
                        labelText: 'End Date',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      inputType: InputType.date,
                      enabled: !isCurrentlyWorking,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FormBuilderSwitch(
                name: 'isCurrentlyWorking',
                initialValue: isCurrentlyWorking,
                title: const Text('Currently Working'),
                onChanged: (value) {
                  setState(() {
                    isCurrentlyWorking = value ?? false;
                  });
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveExperience,
                child: const Text("Save Experience"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
