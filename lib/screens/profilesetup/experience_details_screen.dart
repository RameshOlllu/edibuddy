import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import '../../data/experience_data.dart';

class ExperienceDetailsScreen extends StatefulWidget {
  final String userId;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const ExperienceDetailsScreen({
    Key? key,
    required this.userId,
    required this.onNext,
    required this.onPrevious,
  }) : super(key: key);

  @override
  State<ExperienceDetailsScreen> createState() =>
      _ExperienceDetailsScreenState();
}

class _ExperienceDetailsScreenState extends State<ExperienceDetailsScreen> {
  List<Map<String, dynamic>> experienceDetails = [];
  bool isLoading = true;
  bool isAddingExperience = false;
  Map<String, dynamic>? editingExperience;
  final _formKey = GlobalKey<FormBuilderState>();
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (doc.exists && doc.data()?['experienceDetails'] != null) {
        setState(() {
          experienceDetails = List<Map<String, dynamic>>.from(
              doc.data()!['experienceDetails']);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar('Failed to load experience details');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _saveExperience() async {
    if (!_formKey.currentState!.saveAndValidate()) return;

    final formData = _formKey.currentState!.value;
    final newExperience = {
      'jobTitle': _jobTitleController.text.isNotEmpty
          ? _jobTitleController.text
          : 'Unknown Job Title',
      'companyName': _companyNameController.text.isNotEmpty
          ? _companyNameController.text
          : 'Unknown Company',
      'startDate': formData['startDate']?.toString() ?? '',
      'endDate': formData['isCurrent'] == true
          ? null
          : formData['endDate']?.toString(),
      'isCurrent': formData['isCurrent'] ?? false,
      'location': _locationController.text.isNotEmpty
          ? _locationController.text
          : 'Unknown Location',
    };

    setState(() {
      if (editingExperience != null) {
        final index = experienceDetails.indexOf(editingExperience!);
        experienceDetails[index] = newExperience;
      } else {
        experienceDetails.add(newExperience);
      }
      isAddingExperience = false;
      editingExperience = null;
      _jobTitleController.clear();
      _companyNameController.clear();
      _locationController.clear();
    });
  }

  Future<void> _saveAndNext() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'experienceDetails': experienceDetails,
        'badges.experience': {
          'earned': true,
          'earnedAt': FieldValue.serverTimestamp(),
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (mounted) widget.onNext();
    } catch (e) {
      _showErrorSnackBar('Failed to save experience details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Experience Details'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isAddingExperience) ...[
                          if (experienceDetails.isEmpty)
                            _buildEmptyState()
                          else
                            ...experienceDetails
                                .map((exp) => _buildExperienceCard(exp)),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => setState(() {
                              isAddingExperience = true;
                              editingExperience = null;
                              _jobTitleController.clear();
                              _companyNameController.clear();
                              _locationController.clear();
                            }),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Experience'),
                          ),
                        ] else
                          _buildExperienceForm(),
                      ],
                    ),
                  ),
                ),
                if (!isAddingExperience)
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: widget.onPrevious,
                              child: const Text('Previous'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FilledButton(
                              onPressed: _saveAndNext,
                              child: const Text('Next'),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/empty-experience.json',
            height: 200,
          ),
          const SizedBox(height: 16),
          Text(
            'No Experience Details Added',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your experience details to continue',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

 Widget _buildExperienceCard(Map<String, dynamic> experience) {
  final jobTitle = experience['jobTitle'] ?? 'Unknown Job Title';
  final companyName = experience['companyName'] ?? 'Unknown Company';
  final location = experience['location'] ?? 'Unknown Location';

  final startDate = DateTime.parse(experience['startDate'] ?? DateTime.now().toString());
  final endDate = experience['endDate'] != null
      ? DateTime.parse(experience['endDate'])
      : null;

  return Card(
    margin: const EdgeInsets.symmetric(vertical: 8),
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.work_outline,
                  size: 32,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jobTitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      companyName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          location,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blueAccent),
                onPressed: () {
                  setState(() {
                    editingExperience = experience;
                    isAddingExperience = true;
                    _jobTitleController.text = jobTitle;
                    _companyNameController.text = companyName;
                    _locationController.text = location;
                  });
                },
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${DateFormat('MMM yyyy').format(startDate)} - ${experience['isCurrent'] == true ? 'Present' : DateFormat('MMM yyyy').format(endDate!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              if (experience['isCurrent'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Current',
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildExperienceForm() {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                editingExperience != null
                    ? 'Edit Experience'
                    : 'Add Experience',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TypeAheadField<String>(
                controller: _jobTitleController,
                suggestionsCallback: (pattern) {
                  return ExperienceData.getAllJobTitles()
                      .where((title) =>
                          title.toLowerCase().contains(pattern.toLowerCase()))
                      .toList();
                },
                itemBuilder: (context, suggestion) {
                  return ListTile(
                    title: Text(suggestion),
                  );
                },
                onSelected: (suggestion) {
                  _jobTitleController.text = suggestion;
                },
                hideOnEmpty: true,
              ),
              const SizedBox(height: 16),
              TypeAheadField<String>(
                controller: _companyNameController,
                suggestionsCallback: (pattern) {
                  return ExperienceData.companies
                      .where((company) =>
                          company.toLowerCase().contains(pattern.toLowerCase()))
                      .toList();
                },
                itemBuilder: (context, suggestion) {
                  return ListTile(
                    title: Text(suggestion),
                  );
                },
                onSelected: (suggestion) {
                  _companyNameController.text = suggestion;
                },
                hideOnEmpty: true,
              ),
              const SizedBox(height: 16),
              FormBuilderDateTimePicker(
                name: 'startDate',
                inputType: InputType.date,
                format: DateFormat('yyyy-MM-dd'),
                decoration: const InputDecoration(
                  labelText: 'Start Date*',
                  border: OutlineInputBorder(),
                ),
                validator: FormBuilderValidators.required(
                  errorText: 'Please select a start date',
                ),
              ),
              const SizedBox(height: 16),
              FormBuilderSwitch(
                name: 'isCurrent',
                title: const Text('Current Position'),
                initialValue: editingExperience?['isCurrent'] ?? false,
                onChanged: (value) {
                  if (value == true) {
                    _formKey.currentState?.fields['endDate']?.didChange(null);
                  }
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),
              if (_formKey.currentState?.fields['isCurrent']?.value != true)
                FormBuilderDateTimePicker(
                  name: 'endDate',
                  inputType: InputType.date,
                  format: DateFormat('yyyy-MM-dd'),
                  decoration: const InputDecoration(
                    labelText: 'End Date*',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_formKey.currentState?.fields['isCurrent']?.value !=
                            true &&
                        value == null) {
                      return 'Please enter end date';
                    }
                    if (value != null &&
                        _formKey.currentState?.fields['startDate']?.value !=
                            null &&
                        value.isBefore(
                            _formKey.currentState!.fields['startDate']!.value)) {
                      return 'End date must be after start date';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),
              TypeAheadField<String>(
                controller: _locationController,
                suggestionsCallback: (pattern) {
                  return ExperienceData.cities
                      .where((city) =>
                          city.toLowerCase().contains(pattern.toLowerCase()))
                      .toList();
                },
                itemBuilder: (context, suggestion) {
                  return ListTile(
                    title: Text(suggestion),
                  );
                },
                onSelected: (suggestion) {
                  _locationController.text = suggestion;
                },
                hideOnEmpty: true,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() {
                        isAddingExperience = false;
                        editingExperience = null;
                        _jobTitleController.clear();
                        _companyNameController.clear();
                        _locationController.clear();
                      }),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saveExperience,
                      child: Text(
                        editingExperience != null ? 'Update' : 'Save',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
