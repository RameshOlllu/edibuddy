import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JobPreferencesScreen extends StatefulWidget {
  final String userId;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const JobPreferencesScreen({
    Key? key,
    required this.userId,
    required this.onNext,
    required this.onPrevious,
  }) : super(key: key);

  @override
  State<JobPreferencesScreen> createState() => _JobPreferencesScreenState();
}

class _JobPreferencesScreenState extends State<JobPreferencesScreen> {
  bool isLoading = true;

  // Preferences
  List<String> preferredShifts = [];
  List<String> preferredWorkplaces = [];
  List<String> preferredEmploymentTypes = [];

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
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (doc.exists && doc.data()?['jobPreferences'] != null) {
        final jobPreferences = doc.data()!['jobPreferences'];
        setState(() {
          preferredShifts = List<String>.from(jobPreferences['shifts'] ?? []);
          preferredWorkplaces =
              List<String>.from(jobPreferences['workplaces'] ?? []);
          preferredEmploymentTypes =
              List<String>.from(jobPreferences['employmentTypes'] ?? []);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar('Failed to load job preferences');
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

  Future<void> _saveAndNext() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'jobPreferences': {
          'shifts': preferredShifts,
          'workplaces': preferredWorkplaces,
          'employmentTypes': preferredEmploymentTypes,
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (mounted) widget.onNext();
    } catch (e) {
      _showErrorSnackBar('Failed to save job preferences');
    }
  }

  Widget _buildPreferenceSection({
    required String title,
    required List<Map<String, dynamic>> options,
    required List<String> selectedItems,
    required Function(String) onItemToggle,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 600, // Ensure consistent width for all cards
          minWidth: 300,
        ),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: options.map((option) {
                    final isSelected = selectedItems.contains(option['label']);
                    return GestureDetector(
                      onTap: () => onItemToggle(option['label']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue.shade100
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? Colors.blue.shade400
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              option['icon'],
                              size: 18,
                              color: isSelected
                                  ? Colors.blue.shade800
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              option['label'],
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.blue.shade800
                                    : Colors.grey.shade700,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferred Job Type'),
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
                      children: [
                        _buildPreferenceSection(
                          title: 'Preferred Shifts',
                          options: shiftOptions,
                          selectedItems: preferredShifts,
                          onItemToggle: (label) =>
                              _togglePreference(label, preferredShifts),
                        ),
                        const SizedBox(height: 16),
                        _buildPreferenceSection(
                          title: 'Preferred Workplace',
                          options: workplaceOptions,
                          selectedItems: preferredWorkplaces,
                          onItemToggle: (label) =>
                              _togglePreference(label, preferredWorkplaces),
                        ),
                        const SizedBox(height: 16),
                        _buildPreferenceSection(
                          title: 'Preferred Employment Type',
                          options: employmentTypeOptions,
                          selectedItems: preferredEmploymentTypes,
                          onItemToggle: (label) =>
                              _togglePreference(label, preferredEmploymentTypes),
                        ),
                      ],
                    ),
                  ),
                ),
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
                          child: ElevatedButton(
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
}
