import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/language_data.dart';

class JobPreferencesScreen extends StatefulWidget {
  final String userId;
   final void Function(bool isEarned) onNext;
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
  String? currentPackage;
  String? expectedSalary;

   String englishProficiency = 'Intermediate';
  List<String> otherLanguages = [];


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

      if (doc.exists) {
        final data = doc.data();
        if (data?['jobPreferences'] != null) {
          final jobPreferences = data!['jobPreferences'];
          setState(() {
            preferredShifts = List<String>.from(jobPreferences['shifts'] ?? []);
            preferredWorkplaces =
                List<String>.from(jobPreferences['workplaces'] ?? []);
            preferredEmploymentTypes =
                List<String>.from(jobPreferences['employmentTypes'] ?? []);
            currentPackage = jobPreferences['currentPackage'];
            expectedSalary = jobPreferences['expectedSalary'];
          });
        }

        if (data?['languageDetails'] != null) {
          final languageDetails = data!['languageDetails'];
          setState(() {
            englishProficiency =
                languageDetails['englishProficiency'] ?? 'Intermediate';
            otherLanguages =
                List<String>.from(languageDetails['otherLanguages'] ?? []);
          });
        }
      }

      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar('Failed to load preferences and languages');
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
    if (currentPackage == null || expectedSalary == null) {
      _showErrorSnackBar("Please fill out all fields.");
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'jobPreferences': {
          'shifts': preferredShifts,
          'workplaces': preferredWorkplaces,
          'employmentTypes': preferredEmploymentTypes,
          'currentPackage': currentPackage,
          'expectedSalary': expectedSalary,
        },
        'languageDetails': {
          'englishProficiency': englishProficiency,
          'otherLanguages': otherLanguages,
        },
        'badges.jobpreferences': {
          'earned': preferredShifts.length>1|| preferredWorkplaces.length>1 || preferredEmploymentTypes.isNotEmpty,
          'earnedAt': FieldValue.serverTimestamp(),
        },
        'badges.language': {
          'earned': englishProficiency.isNotEmpty,
          'earnedAt': FieldValue.serverTimestamp(),
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (mounted) widget.onNext(preferredShifts.length>1|| preferredWorkplaces.length>1 || preferredEmploymentTypes.isNotEmpty);
    } catch (e) {
      _showErrorSnackBar('Failed to save preferences and languages');
    }
  }


Widget _buildCompensationSection() {
  final colorScheme = Theme.of(context).colorScheme;
  
  return Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 600,
        minWidth: 300,
      ),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.surface,
                colorScheme.surface.withOpacity(0.8),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.payments_rounded,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Compensation Details',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Enter your salary expectations',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Current Package
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: !_isValidNumber(currentPackage) 
                          ? colorScheme.error 
                          : colorScheme.outline.withOpacity(0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'Current Package',
                              hintText: 'Enter amount in LPA',
                              prefixIcon: Icon(
                                Icons.currency_rupee_rounded,
                                color: colorScheme.primary,
                              ),
                              suffixIcon: Tooltip(
                                message: "Enter your current annual salary in INR (e.g., 8.5 LPA).",
                                child: Icon(
                                  Icons.info_outline_rounded,
                                  color: colorScheme.primary,
                                ),
                              ),
                              filled: true,
                              fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              floatingLabelStyle: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (value) {
                              setState(() {
                                currentPackage = value.trim();
                              });
                            },
                          ),
                        ],
                      ),
                      if (!_isValidNumber(currentPackage))
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: 16,
                                color: colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Enter a valid number',
                                style: TextStyle(
                                  color: colorScheme.error,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Expected Salary
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: !_isValidNumber(expectedSalary) 
                          ? colorScheme.error 
                          : colorScheme.outline.withOpacity(0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'Expected Package',
                              hintText: 'Enter amount in LPA',
                              prefixIcon: Icon(
                                Icons.trending_up_rounded,
                                color: colorScheme.secondary,
                              ),
                              suffixIcon: Tooltip(
                                message: "Enter your expected annual salary in INR (e.g., ₹12.0 LPA).",
                                child: Icon(
                                  Icons.info_outline_rounded,
                                  color: colorScheme.secondary,
                                ),
                              ),
                              filled: true,
                              fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              floatingLabelStyle: TextStyle(
                                color: colorScheme.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (value) {
                              setState(() {
                                expectedSalary = value.trim();
                              });
                            },
                          ),
                        ],
                      ),
                      if (!_isValidNumber(expectedSalary))
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: 16,
                                color: colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Enter a valid number',
                                style: TextStyle(
                                  color: colorScheme.error,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
bool _isValidNumber(String? value) {
  if (value == null || value.isEmpty) return true; // Allow empty input
  final regex = RegExp(r'^\d+(\.\d{1,2})?$'); // Allow up to 2 decimal places
  return regex.hasMatch(value);
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

// Previous imports and class declaration remain the same...

Widget _buildPreferenceSection({
  required String title,
  required String subtitle,
  required IconData headerIcon,
  required List<Map<String, dynamic>> options,
  required List<String> selectedItems,
  required Function(String) onItemToggle,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  
  return Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 600,
        minWidth: 300,
      ),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.surface,
                colorScheme.surface.withOpacity(0.8),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        headerIcon,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: options.map((option) {
                    final isSelected = selectedItems.contains(option['label']);
                    return InkWell(
                      onTap: () => onItemToggle(option['label']),
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.outline.withOpacity(0.2),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: colorScheme.shadow.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              option['icon'],
                              size: 20,
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              option['label'],
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
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
                if (selectedItems.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.secondary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          color: colorScheme.secondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${selectedItems.length} option${selectedItems.length > 1 ? 's' : ''} selected',
                            style: TextStyle(
                              color: colorScheme.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}


Widget _buildLanguageSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Languages',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        SizedBox(height: 16),
        // English Proficiency
        Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'English Proficiency',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...LanguageData.proficiencyLevels.map((level) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Radio<String>(
                      value: level,
                      groupValue: englishProficiency,
                      onChanged: (value) {
                        setState(() {
                          englishProficiency = value!;
                        });
                      },
                    ),
                    title: Text(
                      level,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        // Other Languages
        Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Other Languages',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 1,
                  children: LanguageData.getAllLanguages().map((lang) {
                    final isSelected = otherLanguages.contains(lang);
                    return ChoiceChip(
                      label: Text(lang,  style: Theme.of(context)
                      .textTheme
                      .labelSmall),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            otherLanguages.add(lang);
                          } else {
                            otherLanguages.remove(lang);
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
      ],
    );
  }

  
@override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildCompensationSection(),
                        const SizedBox(height: 16),
                        _buildPreferenceSection(
                          title: 'Preferred Shifts',
                          subtitle: 'Select your preferred working hours',
                          headerIcon: Icons.schedule,
                          options: shiftOptions,
                          selectedItems: preferredShifts,
                          onItemToggle: (label) =>
                              _togglePreference(label, preferredShifts),
                        ),
                        const SizedBox(height: 16),
                        _buildPreferenceSection(
                          title: 'Preferred Workplace',
                          subtitle: 'Choose your ideal work environment',
                          headerIcon: Icons.work,
                          options: workplaceOptions,
                          selectedItems: preferredWorkplaces,
                          onItemToggle: (label) =>
                              _togglePreference(label, preferredWorkplaces),
                        ),
                        const SizedBox(height: 16),
                        _buildPreferenceSection(
                          title: 'Employment Type',
                          subtitle: 'Select your preferred work arrangement',
                          headerIcon: Icons.business,
                          options: employmentTypeOptions,
                          selectedItems: preferredEmploymentTypes,
                          onItemToggle: (label) =>
                              _togglePreference(label, preferredEmploymentTypes),
                        ),
                        const SizedBox(height: 16),
                        _buildLanguageSection(context),
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