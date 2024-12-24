import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../data/language_data.dart';

class LanguageDetailsScreen extends StatefulWidget {
  final String userId;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const LanguageDetailsScreen({
    Key? key,
    required this.userId,
    required this.onNext,
    required this.onPrevious,
  }) : super(key: key);

  @override
  State<LanguageDetailsScreen> createState() => _LanguageDetailsScreenState();
}

class _LanguageDetailsScreenState extends State<LanguageDetailsScreen> {
  bool isLoading = true;
  String englishProficiency = 'Intermediate';
  List<String> otherLanguages = [];
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

      if (doc.exists && doc.data()?['languageDetails'] != null) {
        final languageData = doc.data()!['languageDetails'];
        setState(() {
          englishProficiency = languageData['englishProficiency'] ?? 'Intermediate';
          otherLanguages =
              List<String>.from(languageData['otherLanguages'] ?? []);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar('Failed to load language details');
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
    if (!_formKey.currentState!.saveAndValidate()) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'languageDetails': {
          'englishProficiency': englishProficiency,
          'otherLanguages': otherLanguages,
        },
        'badges.language': {
          'earned': true,
          'earnedAt': FieldValue.serverTimestamp(),
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (mounted) widget.onNext();
    } catch (e) {
      _showErrorSnackBar('Failed to save language details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferred Languages'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: FormBuilder(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // English Proficiency Section
                          Card(
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
                                    'English Proficiency',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
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
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                      subtitle: Text(LanguageData.proficiencyDescriptions[level] ?? ''),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Other Languages Section
                          Card(
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
                                    'Add other languages you can speak (Optional)',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: LanguageData.getAllLanguages()
                                        .map(
                                          (lang) => ChoiceChip(
                                            label: Text(lang),
                                            selected: otherLanguages.contains(lang),
                                            onSelected: (isSelected) {
                                              setState(() {
                                                if (isSelected) {
                                                  otherLanguages.add(lang);
                                                } else {
                                                  otherLanguages.remove(lang);
                                                }
                                              });
                                            },
                                            selectedColor: Colors.blue.shade100,
                                            labelStyle: TextStyle(
                                              color: otherLanguages.contains(lang)
                                                  ? Colors.blue.shade900
                                                  : Colors.grey.shade700,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
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

