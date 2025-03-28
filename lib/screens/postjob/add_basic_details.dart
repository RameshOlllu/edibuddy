import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../model/location_model.dart';
import '../../widgets/animated_text_field.dart';
import '../../widgets/location_search_widget.dart';
import '../../widgets/search_location_card.dart';
import 'add_job_details.dart';

class AddJobBasicsScreen extends StatefulWidget {
  final String? jobId;
  final Map<String, dynamic>? jobData;

  const AddJobBasicsScreen({Key? key, this.jobId, this.jobData}) : super(key: key);

  @override
  _AddJobBasicsScreenState createState() => _AddJobBasicsScreenState();
}

class _AddJobBasicsScreenState extends State<AddJobBasicsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _additionalRequirementsController = TextEditingController();

  bool _isRemote = false;
  LocationModel? _selectedLocation;
  bool _isLoading = false;

  String _selectedGender = "No Gender Preference";
  String _selectedNationality = "Indian";
  List<String> _selectedLanguages = [];

  final List<String> _genders = ["No Gender Preference", "Male", "Female", "Other"];
  final List<String> _nationalities = [
    "Indian", "American", "British", "Canadian", "Australian", "French",
    "German", "Chinese", "Japanese", "Spanish", "Italian"
  ];
  final List<String> _languages = [
    "English", "Hindi", "Telugu", "French", "Spanish", "German", 
    "Tamil", "Kannada", "Malayalam", "Gujarati", "Chinese", "Japanese"
  ];

  @override
  void initState() {
    super.initState();
    _loadJobData();
  }

  void _loadJobData() {
    if (widget.jobData != null) {
      _titleController.text = widget.jobData?['jobTitle'] ?? '';
      _descriptionController.text = widget.jobData?['companyDescription'] ?? '';
      _isRemote = widget.jobData?['jobLocation'] == 'Remote';
      _selectedGender = widget.jobData?['preferredGender'] ?? "No Gender Preference";
      _selectedNationality = widget.jobData?['preferredNationality'] ?? "Indian";
      _selectedLanguages = widget.jobData?['preferredLanguages'] != null
          ? List<String>.from(widget.jobData!['preferredLanguages'])
          : [];
      _additionalRequirementsController.text = widget.jobData?['additionalRequirements'] ?? "";

      final locationData = widget.jobData?['locationDetails'];
      if (locationData != null) {
        _selectedLocation = LocationModel.fromJson(locationData);
      }
    }
  }

  Future<void> saveJobBasics() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isRemote && _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a job location')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final jobData = {
        'jobTitle': _titleController.text,
        'companyDescription': _descriptionController.text,
        'isRemote': _isRemote,
        'jobLocation': _isRemote ? 'Remote' : _selectedLocation.toString(),
        'locationDetails': _isRemote ? null : _selectedLocation?.toJson(),
        'userId': user.uid,
        'preferredGender': _selectedGender,
        'preferredNationality': _selectedNationality,
        'preferredLanguages': _selectedLanguages,
        'additionalRequirements': _additionalRequirementsController.text,
        'updatedAt': Timestamp.now(),
      };

      if (widget.jobId != null) {
        await FirebaseFirestore.instance
            .collection('jobs')
            .doc(widget.jobId)
            .set(jobData, SetOptions(merge: true));

        Navigator.pop(context, true);
      } else {
        final docRef = await FirebaseFirestore.instance.collection('jobs').add(jobData);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobDetailsScreen(jobId: docRef.id, jobData: jobData),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving job basics: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.jobId != null ? 'Edit Job Basics' : 'Add Job Basics')),
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
                    _buildJobTitleSection(),
                    const SizedBox(height: 24),
                    _buildCompanyDescriptionSection(),
                    const SizedBox(height: 24),
                    _buildLocationSection(),
                    const SizedBox(height: 24),
                    _buildAdditionalDetailsSection(),
                  ],
                ),
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildJobTitleSection() {
    return AnimatedTextField(
      label: 'Job Title',
      controller: _titleController,
      hint: 'e.g., Math Teacher - High School',
      validator: (value) => value?.isEmpty ?? true ? 'Please enter a job title' : null,
    );
  }

  Widget _buildCompanyDescriptionSection() {
    return AnimatedTextField(
      label: 'Company Description',
      controller: _descriptionController,
      hint: 'Brief overview of your institution...',
      maxLines: 3,
      validator: (value) => value?.isEmpty ?? true ? 'Please provide a description' : null,
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Job Location', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('This is a remote position'),
          subtitle: const Text('Candidates can work from anywhere'),
          value: _isRemote,
          onChanged: (value) => setState(() => _isRemote = value),
        ),
        if (!_isRemote) ...[
          const SizedBox(height: 16),
          LocationSearchWidget(
            onLocationSelected: (location) => setState(() => _selectedLocation = location),
            initialLocation: _selectedLocation,
          ),
          if (_selectedLocation != null)
            SelectedLocationCard(
              location: _selectedLocation!,
              onDelete: () => setState(() => _selectedLocation = null),
            ),
        ],
      ],
    );
  }

  Widget _buildAdditionalDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdown("Preferred Gender", _selectedGender, _genders, (value) {
          setState(() => _selectedGender = value!);
        }),
        const SizedBox(height: 16),
        _buildDropdown("Preferred Nationality", _selectedNationality, _nationalities, (value) {
          setState(() => _selectedNationality = value!);
        }),
        const SizedBox(height: 16),
        _buildMultiSelectChips("Specialized Languages", _languages, _selectedLanguages),
        const SizedBox(height: 16),
        AnimatedTextField(
          label: 'Additional Hiring Preferences',
          controller: _additionalRequirementsController,
          hint: 'Specify any other hiring requirements...',
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

 Widget _buildMultiSelectChips(String label, List<String> options, List<String> selected) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      Wrap(
        spacing: 6,
        children: options.map((lang) {
          final isSelected = selected.contains(lang);
          return ChoiceChip(
            label: Text(lang),
            selected: isSelected,
            onSelected: (bool value) {
              setState(() {
                if (value) {
                  selected.add(lang); // Add to selection
                } else {
                  selected.remove(lang); // Remove from selection
                }
              });
            },
          );
        }).toList(),
      ),
    ],
  );
}


  Widget _buildBottomBar() => ElevatedButton(onPressed: saveJobBasics, child: const Text("Save & Continue"));
}
