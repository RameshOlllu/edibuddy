import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../../data/education_data.dart';

class EducationDetailsScreen extends StatefulWidget {
  final String userId;
  final void Function(bool isEarned) onNext;
  final VoidCallback onPrevious;

  const EducationDetailsScreen({
    Key? key,
    required this.userId,
    required this.onNext,
    required this.onPrevious,
  }) : super(key: key);

  @override
  State<EducationDetailsScreen> createState() => _EducationDetailsScreenState();
}

class _EducationDetailsScreenState extends State<EducationDetailsScreen> {
  List<Map<String, dynamic>> educationDetails = [];
  bool isLoading = true;
  bool isAddingEducation = false;
  Map<String, dynamic>? editingEducation;
  final _formKey = GlobalKey<FormBuilderState>();

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

      if (doc.exists && doc.data()?['educationDetails'] != null) {
        if (mounted) {
          setState(() {
            educationDetails = List<Map<String, dynamic>>.from(
                doc.data()!['educationDetails']);
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        _showErrorSnackBar('Failed to load education details');
      }
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

  Future<void> _saveEducation() async {
    if (!_formKey.currentState!.saveAndValidate()) {
      debugPrint('Validation failed for the following fields:');
      _formKey.currentState!.fields.forEach((key, field) {
        if (!field.isValid) {
          debugPrint('$key: ${field.errorText}');
        }
      });
      return;
    }

    final formData = _formKey.currentState!.value;
    final newEducation = {
      'highestEducationLevel': formData['highestEducationLevel'] ?? '',
      'degree': formData['degree'] ?? '',
      'specialization': formData['specialization'] ?? '',
      'collegeName': formData['collegeName'] ?? '',
      'completionYear': formData['completionYear'] ?? '',
      'schoolMedium': formData['schoolMedium'] ?? '',
      'isPursuing': formData['isPursuing'] ?? false,
    };

    if (newEducation['isPursuing'] == true) {
      final existingPursuing =
          educationDetails.indexWhere((e) => e['isPursuing'] == true);
      if (existingPursuing != -1 && editingEducation == null) {
        final shouldContinue = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmation'),
            content: const Text(
                'Another education is already marked as pursuing. '
                'Do you want to mark this as your current pursuing education instead?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continue'),
              ),
            ],
          ),
        );

        if (shouldContinue != true) return;

        educationDetails[existingPursuing]['isPursuing'] = false;
      }
    }

    setState(() {
      if (editingEducation != null) {
        final index = educationDetails.indexOf(editingEducation!);
        educationDetails[index] = newEducation;
      } else {
        educationDetails.add(newEducation);
      }
      isAddingEducation = false;
      editingEducation = null;
    });
  }

  Future<void> _saveAndNext() async {
    print('educationDetails is $educationDetails');
    print('educationDetails is ${educationDetails.length}');
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'educationDetails': educationDetails,
        'badges.education': {
          'earned': educationDetails.isNotEmpty,
          'earnedAt': FieldValue.serverTimestamp(),
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (mounted) widget.onNext(educationDetails.isNotEmpty);
    } catch (e) {
      _showErrorSnackBar('Failed to save education details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: educationDetails.isNotEmpty
            ? const Text('Education Details')
            : null, // AppBar will be empty when no education details exist
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
                        if (!isAddingEducation) ...[
                          // Text(
                          //   'Your Education',
                          //   style: Theme.of(context)
                          //       .textTheme
                          //       .headlineSmall
                          //       ?.copyWith(
                          //         fontWeight: FontWeight.bold,
                          //       ),
                          // ),
                          // const SizedBox(height: 16),
                          if (educationDetails.isEmpty)
                            _buildEmptyState()
                          else
                            ...educationDetails
                                .map((edu) => _buildEducationCard(edu)),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: FilledButton.icon(
                                onPressed: () {
                                  if (!isAddingEducation) {
                                    setState(() {
                                      isAddingEducation = true;
                                      editingEducation = null;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add Education'),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(
                                      180, 48), // Consistent button size
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ] else
                          _buildEducationForm(),
                      ],
                    ),
                  ),
                ),
                if (!isAddingEducation)
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
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.school_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Education Details Added',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your education details to continue.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          // const SizedBox(height: 24),
          // ElevatedButton.icon(
          //   onPressed: () {
          //     // Add action to navigate to add education details screen
          //   },
          //   icon: const Icon(Icons.add_circle_outline),
          //   label: const Text('Add Education'),
          //   style: ElevatedButton.styleFrom(
          //     minimumSize: const Size(180, 48),
          //     shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(12),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildEducationCard(Map<String, dynamic> education) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Degree, Specialization, and Delete Icon
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        education['degree'],
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Text(
                        education['specialization'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () => _deleteEducation(education),
                  color: Colors.red.shade400,
                ),
              ],
            ),

            const SizedBox(height: 8),

            // College and Education Level
            Row(
              children: [
                const Icon(Icons.school, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    education['collegeName'],
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Completion Year
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Completion Year: ${education['completionYear']}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Medium of Instruction
            Row(
              children: [
                const Icon(Icons.language, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Medium: ${education['schoolMedium']}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),

            // Bottom Row: Pursuing Indicator
            if (education['isPursuing'] == true) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle,
                          size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        'Currently Pursuing',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _deleteEducation(Map<String, dynamic> education) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Confirmation'),
        content: const Text(
            'Are you sure you want to delete this education record? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmation == true) {
      setState(() {
        educationDetails.remove(education);
      });

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .update({'educationDetails': educationDetails});
        _showErrorSnackBar('Education record deleted successfully!');
      } catch (e) {
        _showErrorSnackBar('Failed to delete education record.');
      }
    }
  }

  Widget _buildEducationForm() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Form Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    editingEducation != null
                        ? 'Edit Education'
                        : 'Add New Education',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 24),
                    onPressed: () {
                      setState(() {
                        isAddingEducation = false;
                        editingEducation = null;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Education Level Dropdown
              _buildDropdown(
                name: 'highestEducationLevel',
                label: 'Education Level*',
                items: EducationData.educationLevels.keys
                    .map((level) => DropdownMenuItem<String>(
                          value: level,
                          child: Text(level),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _formKey.currentState?.fields['degree']?.didChange(null);
                    _formKey.currentState?.fields['specialization']
                        ?.didChange(null);
                  });
                },
              ),

              const SizedBox(height: 16),

              // Degree Dropdown
              _buildDropdown(
                name: 'degree',
                label: 'Degree*',
                items: _buildDegreeItems(),
                onChanged: (value) {
                  setState(() {
                    _formKey.currentState?.fields['specialization']
                        ?.didChange(null);
                  });
                },
              ),

              const SizedBox(height: 16),

              // Specialization Dropdown
              _buildDropdown(
                name: 'specialization',
                label: 'Specialization*',
                items: _buildSpecializationItems(),
              ),

              const SizedBox(height: 16),

              // College Name Field
              _buildTextField(
                name: 'collegeName',
                label: 'College/Institution Name*',
                hint: 'Enter your college name',
                validators: [
                  FormBuilderValidators.required(
                      errorText: 'This field is required'),
                  FormBuilderValidators.minLength(3,
                      errorText: 'Name too short'),
                ],
              ),

              const SizedBox(height: 16),

              // Completion Year Field
              _buildTextField(
                name: 'completionYear',
                label: 'Completion Year*',
                hint: 'Enter year (e.g., 2023)',
                keyboardType: TextInputType.number,
                validators: [
                  FormBuilderValidators.required(
                      errorText: 'This field is required'),
                  FormBuilderValidators.numeric(
                      errorText: 'Enter a valid year'),
                  FormBuilderValidators.min(1950,
                      errorText: 'Year must be 1950 or later'),
                  FormBuilderValidators.max(2030,
                      errorText: 'Year must be 2030 or earlier'),
                ],
              ),

              const SizedBox(height: 16),

              // School Medium Dropdown
              _buildDropdown(
                name: 'schoolMedium',
                label: 'Medium of Instruction*',
                items: EducationData.mediums
                    .map((medium) => DropdownMenuItem<String>(
                          value: medium,
                          child: Text(medium),
                        ))
                    .toList(),
              ),

              const SizedBox(height: 16),

              // Currently Pursuing Switch
              FormBuilderSwitch(
                name: 'isPursuing',
                title: const Text('Currently Pursuing'),
                initialValue: editingEducation?['isPursuing'] ?? false,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
              ),

              const SizedBox(height: 24),

              // Save/Cancel Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          isAddingEducation = false;
                          editingEducation = null;
                        });
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Theme.of(context)
                            .colorScheme
                            .onPrimary, // Text color
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _saveEducation,
                      child: Text(
                        editingEducation != null ? 'Update' : 'Save',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
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

  Widget _buildDropdown({
    required String name,
    required String label,
    List<DropdownMenuItem<String>>? items,
    ValueChanged<String?>? onChanged,
  }) {
    return FormBuilderDropdown<String>(
      name: name,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      validator:
          FormBuilderValidators.required(errorText: 'This field is required'),
      items: items ?? [], // Use an empty list if items is null
      onChanged: onChanged,
    );
  }

  Widget _buildTextField({
    required String name,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    List<String? Function(String?)>? validators,
  }) {
    return FormBuilderTextField(
      name: name,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      keyboardType: keyboardType,
      validator: FormBuilderValidators.compose(validators ?? []),
    );
  }

  List<DropdownMenuItem<String>> _buildDegreeItems() {
    final educationLevel = _formKey
        .currentState?.fields['highestEducationLevel']?.value as String?;
    if (educationLevel == null) return [];

    return EducationData.getDegrees(educationLevel)
        .map((degree) => DropdownMenuItem<String>(
              value: degree,
              child: Text(degree),
            ))
        .toList();
  }

  List<DropdownMenuItem<String>> _buildSpecializationItems() {
    final degree = _formKey.currentState?.fields['degree']?.value as String?;
    if (degree == null) return [];

    return EducationData.getSpecializations(degree)
        .map((spec) => DropdownMenuItem<String>(
              value: spec,
              child: Text(spec),
            ))
        .toList();
  }
}
