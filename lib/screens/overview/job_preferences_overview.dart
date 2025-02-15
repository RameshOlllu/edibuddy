import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JobPreferencesOverviewScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> currentPreferences;

  const JobPreferencesOverviewScreen({
    Key? key,
    required this.userId,
    required this.currentPreferences,
  }) : super(key: key);

  @override
  State<JobPreferencesOverviewScreen> createState() =>
      _JobPreferencesOverviewScreenState();
}

class _JobPreferencesOverviewScreenState
    extends State<JobPreferencesOverviewScreen> {
  bool isLoading = true;

  // Preferences
  List<String> preferredShifts = [];
  List<String> preferredWorkplaces = [];
  List<String> preferredEmploymentTypes = [];
  late TextEditingController currentPackageController;
  late TextEditingController expectedSalaryController;

  final List<Map<String, dynamic>> shiftOptions = [
    {'label': 'Night Shift', 'icon': Icons.nightlight_round},
    {'label': 'Day Shift', 'icon': Icons.wb_sunny},
  ];

  final List<Map<String, dynamic>> workplaceOptions = [
    {'label': 'Work from Home', 'icon': Icons.home},
    {'label': 'Work from Office', 'icon': Icons.business},
    {'label': 'Field Job', 'icon': Icons.directions_walk},
  ];

  final List<Map<String, dynamic>> employmentTypeOptions = [
    {'label': 'Full Time', 'icon': Icons.access_time_filled},
    {'label': 'Part Time', 'icon': Icons.timelapse},
  ];

  @override
  void initState() {
    super.initState();
    _initializePreferences();
  }

  void _initializePreferences() {
    final preferences = widget.currentPreferences;

    setState(() {
      preferredShifts = List<String>.from(preferences['shifts'] ?? []);
      preferredWorkplaces = List<String>.from(preferences['workplaces'] ?? []);
      preferredEmploymentTypes =
          List<String>.from(preferences['employmentTypes'] ?? []);
      currentPackageController =
          TextEditingController(text: preferences['currentPackage']);
      expectedSalaryController =
          TextEditingController(text: preferences['expectedSalary']);
      isLoading = false;
    });
  }

  Future<void> _savePreferences() async {
    final currentPackage = currentPackageController.text.trim();
    final expectedSalary = expectedSalaryController.text.trim();

    if (currentPackage.isEmpty || expectedSalary.isEmpty) {
      _showSnackBar('Please fill out all fields.', isError: true);
      return;
    }

    try {
      final updatedPreferences = {
        'shifts': preferredShifts,
        'workplaces': preferredWorkplaces,
        'employmentTypes': preferredEmploymentTypes,
        'currentPackage': currentPackage,
        'expectedSalary': expectedSalary,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'jobPreferences': updatedPreferences});

      Navigator.pop(context, updatedPreferences);
    } catch (e) {
      _showSnackBar('Failed to save preferences.', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _togglePreference(String label, List<String> selectedItems) {
    setState(() {
      if (selectedItems.contains(label)) {
        selectedItems.remove(label);
      } else {
        selectedItems.add(label);
      }
    });
  }

  Widget _buildCompensationSection() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compensation Details',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInputField(
              context,
              label: 'Current Package (LPA)',
              controller: currentPackageController,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              context,
              label: 'Expected Salary (LPA)',
              controller: expectedSalaryController,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(BuildContext context,
      {required String label, required TextEditingController controller}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildPreferenceSection({
    required String title,
    required List<Map<String, dynamic>> options,
    required List<String> selectedItems,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: options.map((option) {
                final isSelected = selectedItems.contains(option['label']);
                return ChoiceChip(
                  label: Text(option['label']),
                  selected: isSelected,
                  onSelected: (selected) {
                    _togglePreference(option['label'], selectedItems);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Job Preferences'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePreferences,
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildCompensationSection(),
                  const SizedBox(height: 16),
                  _buildPreferenceSection(
                    title: 'Preferred Shifts',
                    options: shiftOptions,
                    selectedItems: preferredShifts,
                  ),
                  const SizedBox(height: 16),
                  _buildPreferenceSection(
                    title: 'Preferred Workplaces',
                    options: workplaceOptions,
                    selectedItems: preferredWorkplaces,
                  ),
                  const SizedBox(height: 16),
                  _buildPreferenceSection(
                    title: 'Employment Types',
                    options: employmentTypeOptions,
                    selectedItems: preferredEmploymentTypes,
                  ),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _savePreferences,
            child: const Text('Save and Close'),
          ),
        ),
      ),
    );
  }
}
