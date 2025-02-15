import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../../data/education_data.dart';

class AddEducationScreen extends StatefulWidget {
  final String userId;

  const AddEducationScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _AddEducationScreenState createState() => _AddEducationScreenState();
}

class _AddEducationScreenState extends State<AddEducationScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  String? selectedEducationLevel;
  String? selectedDegree;

  Future<void> _saveEducation() async {
    if (!_formKey.currentState!.saveAndValidate()) {
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

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);
      final doc = await userRef.get();
      List<dynamic> educationDetails = doc.data()?['educationDetails'] ?? [];

      if (newEducation['isPursuing'] == true) {
        for (var edu in educationDetails) {
          if (edu['isPursuing'] == true) {
            edu['isPursuing'] = false;
          }
        }
      }

      educationDetails.add(newEducation);

      await userRef.update({'educationDetails': educationDetails});

      if (mounted) {
        Navigator.pop(context, newEducation);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add education: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Education'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    selectedEducationLevel = value as String?;
                    selectedDegree = null; // Reset degree on level change
                    _formKey.currentState?.fields['degree']?.didChange(null);
                    _formKey.currentState?.fields['specialization']?.didChange(null);
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
                    selectedDegree = value as String?;
                    _formKey.currentState?.fields['specialization']?.didChange(null);
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
              ),
              const SizedBox(height: 16),

              // Completion Year Field
              _buildTextField(
                name: 'completionYear',
                label: 'Completion Year*',
                hint: 'Enter year (e.g., 2023)',
                keyboardType: TextInputType.number,
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
                initialValue: false,
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _saveEducation,
                child: const Text('Save'),
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
    required List<DropdownMenuItem<String>> items,
    void Function(dynamic)? onChanged,
  }) {
    return FormBuilderDropdown<String>(
      name: name,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      validator: FormBuilderValidators.required(errorText: 'This field is required'),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildTextField({
    required String name,
    required String label,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return FormBuilderTextField(
      name: name,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      keyboardType: keyboardType,
    );
  }

  List<DropdownMenuItem<String>> _buildDegreeItems() {
    if (selectedEducationLevel == null) return [];
    return EducationData.getDegrees(selectedEducationLevel!).map((degree) {
      return DropdownMenuItem<String>(
        value: degree,
        child: Text(degree),
      );
    }).toList();
  }

  List<DropdownMenuItem<String>> _buildSpecializationItems() {
    if (selectedDegree == null) return [];
    return EducationData.getSpecializations(selectedDegree!).map((specialization) {
      return DropdownMenuItem<String>(
        value: specialization,
        child: Text(specialization),
      );
    }).toList();
  }
}
