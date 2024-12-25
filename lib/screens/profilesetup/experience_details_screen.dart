import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../data/experience_data.dart';
import 'add_experience_screen.dart';

class ExperienceDetailsScreen extends StatefulWidget {
  final String userId;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const ExperienceDetailsScreen({
    Key? key,
    required this.userId,
    required this.onNext,
    required this.onPrevious,
  }) : super(key: key);

  @override
  State<ExperienceDetailsScreen> createState() =>
      _ExperienceDetailsScreenState();
}

class _ExperienceDetailsScreenState extends State<ExperienceDetailsScreen> {
  List<Map<String, dynamic>> experienceDetails = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchExperienceDetails();
  }

  Future<void> _fetchExperienceDetails() async {
    setState(() => isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (doc.exists && doc.data()?['experienceDetails'] != null) {
        setState(() {
          experienceDetails =
              List<Map<String, dynamic>>.from(doc.data()!['experienceDetails']);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load experience details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
      _fetchExperienceDetails();
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
      setState(() => experienceDetails.removeAt(index));
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
  return Scaffold(
    appBar: AppBar(
      title: const Text('Experience Details'),
      centerTitle: true,
    ),
    body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : experienceDetails.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "You haven't added any experience yet.",
                      style: TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _navigateToAddExperienceScreen(),
                      icon: const Icon(Icons.add),
                      label: const Text("Add Experience"),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: experienceDetails.length,
                itemBuilder: (context, index) =>
                    _buildExperienceCard(experienceDetails[index], index),
              ),
    floatingActionButton: experienceDetails.isNotEmpty
        ? FloatingActionButton(
            onPressed: () => _navigateToAddExperienceScreen(),
            child: const Icon(Icons.add),
          )
        : null,
    bottomNavigationBar: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: widget.onPrevious,
              child: const Text("Previous"),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: experienceDetails.isNotEmpty ? widget.onNext : null,
              child: const Text("Next"),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildExperienceCard(Map<String, dynamic> experience, int index) {
  final startDate = DateTime.parse(experience['startDate']);
  final endDate = experience['endDate'] != null
      ? DateTime.parse(experience['endDate'])
      : null;

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
          // Job Title and Institution
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
                      experience['jobTitle'] ?? "",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_city, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          experience['institutionName'] ?? "",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () =>
                    _navigateToAddExperienceScreen(experience: experience),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Job Roles
          if (experience['jobRole'] != null &&
              (experience['jobRole'] as List).isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.work_outline, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      "Job roles",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: List.generate(
                    (experience['jobRole'] as List).length,
                    (i) => Chip(
                      label: Text(
                        experience['jobRole'][i],
                        style: const TextStyle(fontSize: 10),
                      ),
                      backgroundColor: Colors.blue.shade50,
                      avatar: const Icon(
                        Icons.label,
                        size: 16,
                        color: Colors.blue,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),

          // Industry
          if (experience['industry'] != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.domain, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      "Industry",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  experience['industry'] ?? "",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),

          // Description
          if (experience['description'] != null &&
              experience['description'].isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.description, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      "Description",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  experience['description'] ?? "",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),

          // Skills
          if (experience['skills'] != null &&
              (experience['skills'] as List).isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.star_outline, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      "Skills",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: List.generate(
                    (experience['skills'] as List).length,
                    (i) => Chip(
                      label: Text(
                        experience['skills'][i],
                        style: const TextStyle(fontSize: 10),
                      ),
                      backgroundColor: Colors.green.shade50,
                      avatar: const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),

          // Dates
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                experience['isCurrentlyWorking']
                    ? "${DateFormat.yMMM().format(startDate)} - Present"
                    : "${DateFormat.yMMM().format(startDate)} - ${DateFormat.yMMM().format(endDate!)}",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
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
