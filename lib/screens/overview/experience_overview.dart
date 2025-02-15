import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../profilesetup/add_experience_screen.dart';

class ExperienceOverviewScreen extends StatefulWidget {
  final String userId;
  final List<Map<String, dynamic>> experiences;

  const ExperienceOverviewScreen({
    Key? key,
    required this.userId,
    required this.experiences,
  }) : super(key: key);

  @override
  _ExperienceOverviewScreenState createState() =>
      _ExperienceOverviewScreenState();
}

class _ExperienceOverviewScreenState extends State<ExperienceOverviewScreen> {
  late List<Map<String, dynamic>> experienceDetails;
  bool isUpdated = false; // Flag to track if changes were made

  @override
  void initState() {
    super.initState();
    experienceDetails = List<Map<String, dynamic>>.from(widget.experiences);
  }

  Future<void> _navigateToAddExperienceScreen(
      {Map<String, dynamic>? experience}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExperienceScreen(
          userId: widget.userId,
          existingExperience: experience,
        ),
      ),
    );

    if (result == true) {
      isUpdated = true; // Mark as updated
      await _fetchExperienceDetails();
    }
  }

  Future<void> _fetchExperienceDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (doc.exists && doc.data()?['experienceDetails'] != null) {
        setState(() {
          experienceDetails =
              List<Map<String, dynamic>>.from(doc.data()!['experienceDetails']);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load experience details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteExperience(int index) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Experience"),
        content: const Text("Are you sure you want to delete this experience?"),
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
        experienceDetails.removeAt(index);
        isUpdated = true; // Mark as updated
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'experienceDetails': experienceDetails});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Experience deleted successfully."),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

@override
Widget build(BuildContext context) {
  return WillPopScope(
    onWillPop: () async {
      Navigator.pop(context, experienceDetails); // Always return the list
      return false;
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text('All Experiences'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, experienceDetails); // Return updated list
          },
        ),
      ),
      body: experienceDetails.isEmpty
          ? const Center(
              child: Text(
                "No experience details available.",
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: experienceDetails.length,
              itemBuilder: (context, index) =>
                  _buildExperienceCard(experienceDetails[index], index),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddExperienceScreen(),
        child: const Icon(Icons.add),
      ),
    ),
  );
}

  Widget _buildExperienceCard(Map<String, dynamic> experience, int index) {
    final startDate = experience['startDate'] is Timestamp
        ? (experience['startDate'] as Timestamp).toDate()
        : DateTime.tryParse(experience['startDate']) ?? DateTime.now();

    final endDate = experience['isCurrentlyWorking'] == true
        ? DateTime.now()
        : experience['endDate'] is Timestamp
            ? (experience['endDate'] as Timestamp).toDate()
            : DateTime.tryParse(experience['endDate']) ?? DateTime.now();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.business, size: 40, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        experience['jobTitle'] ?? "N/A",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        experience['institutionName'] ?? "N/A",
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteExperience(index),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${DateFormat('MMM yyyy').format(startDate)} - ${experience['isCurrentlyWorking'] == true ? 'Present' : DateFormat('MMM yyyy').format(endDate)}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
