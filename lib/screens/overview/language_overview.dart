import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/language_data.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LanguageOverviewScreen extends StatefulWidget {
  final String userId;
  final String englishProficiency;
  final List<String> otherLanguages;

  const LanguageOverviewScreen({
    Key? key,
    required this.userId,
    required this.englishProficiency,
    required this.otherLanguages,
  }) : super(key: key);

  @override
  _LanguageOverviewScreenState createState() => _LanguageOverviewScreenState();
}

class _LanguageOverviewScreenState extends State<LanguageOverviewScreen> {
  late String englishProficiency;
  late List<String> otherLanguages;

  @override
  void initState() {
    super.initState();
    englishProficiency = widget.englishProficiency;
    otherLanguages = List<String>.from(widget.otherLanguages);
  }

  void _saveLanguages() async {
    try {
      // Update Firestore with new language details
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'languageDetails': {
          'englishProficiency': englishProficiency,
          'otherLanguages': otherLanguages,
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context, {
        'englishProficiency': englishProficiency,
        'otherLanguages': otherLanguages,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save language details'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allLanguages = LanguageData.getAllLanguages();
    final proficiencyLevels = LanguageData.proficiencyLevels;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Languages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveLanguages,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              'English Proficiency',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...proficiencyLevels.map((level) {
              return RadioListTile<String>(
                title: Text(level),
                value: level,
                groupValue: englishProficiency,
                onChanged: (value) {
                  setState(() {
                    englishProficiency = value!;
                  });
                },
              );
            }).toList(),
            const Divider(height: 32, thickness: 1),
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
              runSpacing: 8,
              children: allLanguages.map((language) {
                final isSelected = otherLanguages.contains(language);
                return FilterChip(
                  label: Text(language),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        otherLanguages.add(language);
                      } else {
                        otherLanguages.remove(language);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}