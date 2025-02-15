import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'add_new_education.dart';

class EducationOverviewScreen extends StatefulWidget {
  final String userId;
  final List<Map<String, dynamic>> educationDetails;

  const EducationOverviewScreen({
    Key? key,
    required this.userId,
    required this.educationDetails,
  }) : super(key: key);

  @override
  _EducationOverviewScreenState createState() =>
      _EducationOverviewScreenState();
}

class _EducationOverviewScreenState extends State<EducationOverviewScreen> {
  late List<Map<String, dynamic>> educationDetails;
  bool isUpdated = false;

  @override
  void initState() {
    super.initState();
    educationDetails = List<Map<String, dynamic>>.from(widget.educationDetails);
  }

  Future<void> _navigateToAddOrEditEducation(
      {Map<String, dynamic>? education}) async {
    // Mocked example for demonstration
    final result = await Future.delayed(Duration(seconds: 1),
        () => {'degree': 'New Degree', 'collegeName': 'New College'});

    if (result != null) {
      setState(() {
        if (education != null) {
          // Update existing education
          final index = educationDetails.indexOf(education);
          educationDetails[index] = result;
        } else {
          // Add new education
          educationDetails.add(result);
        }
        isUpdated = true;
      });
    }
  }

  Future<void> _deleteEducation(int index) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Education"),
        content: const Text(
            "Are you sure you want to delete this education record?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      setState(() {
        educationDetails.removeAt(index);
        isUpdated = true;
      });

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'educationDetails': educationDetails});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Education Overview'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (isUpdated) {
                Navigator.pop(context, educationDetails);
              } else {
                Navigator.pop(context, null);
              }
            },
          )),
      body: educationDetails.isEmpty
          ? const Center(
              child: Text(
                "No education details available.",
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: educationDetails.length,
              itemBuilder: (context, index) =>
                  _buildEducationCard(educationDetails[index], index),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newEducation = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEducationScreen(userId: widget.userId),
            ),
          );

          if (newEducation != null) {
            setState(() {
              educationDetails.add(newEducation);
              isUpdated = true;
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEducationCard(Map<String, dynamic> education, int index) {
    final bool isPursuing = education['isPursuing'] == true;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Degree Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Placeholder for Degree
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.school,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 16),
                // Degree Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        education['degree'] ?? "N/A",
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      // College Name and Chip in Same Row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              education['collegeName'] ?? "N/A",
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          //    const SizedBox(width: 1),
                          //   Container(
                          //     padding: const EdgeInsets.symmetric(
                          //         horizontal: 8, vertical: 4),
                          //     decoration: BoxDecoration(
                          //       color: isPursuing
                          //           ? Theme.of(context)
                          //               .colorScheme
                          //               .secondaryContainer
                          //           : Theme.of(context)
                          //               .colorScheme
                          //               .primaryContainer,
                          //       borderRadius: BorderRadius.circular(12),
                          //     ),
                          //     child: Text(
                          //       isPursuing ? 'Pursuing' : 'Completed',
                          //       style: Theme.of(context)
                          //           .textTheme
                          //           .labelSmall
                          //           ?.copyWith(
                          //             color: isPursuing
                          //                 ? Theme.of(context)
                          //                     .colorScheme
                          //                     .onSecondaryContainer
                          //                 : Theme.of(context)
                          //                     .colorScheme
                          //                     .onPrimaryContainer,
                          //             fontWeight: FontWeight.bold,
                          //           ),
                          //     ),
                          //   ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Delete Icon
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteEducation(index),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Completion Year and School Medium
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Completion Year',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        education['completionYear'] ?? "N/A",
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'School Medium',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        education['schoolMedium'] ?? "N/A",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Highlighted Highest Education Level and Specialization
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    education['highestEducationLevel'] ?? "N/A",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    education['specialization'] ?? "N/A",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.bold,
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
}
