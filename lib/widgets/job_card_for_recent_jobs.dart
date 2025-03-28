import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../home/employee_job_details_page.dart';

class JobCard extends StatefulWidget {
  final Map<String, dynamic> jobData; // Accept jobData directly
  const JobCard({Key? key, required this.jobData}) : super(key: key);

  @override
  _JobCardState createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> {
  bool _isSaved = false;
  bool _isExpanded = false; // Controls the expanded section

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
  }

Future<void> _checkIfSaved() async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId != null) {
    DocumentSnapshot savedJob = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('savedJobs')
        .doc(widget.jobData['id'])
        .get();
    if (!mounted) return; // Ensure widget is still in the tree
    setState(() {
      _isSaved = savedJob.exists;
    });
  }
}


  Future<void> _toggleSaved() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    if (_isSaved) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('savedJobs')
          .doc(widget.jobData['id'])
          .delete();
    } else {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('savedJobs')
          .doc(widget.jobData['id'])
          .set({
        'savedAt': FieldValue.serverTimestamp(),
      });
    }

    setState(() {
      _isSaved = !_isSaved;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Extract details from jobData
    String jobTitle = widget.jobData['jobTitle'] ?? 'Untitled Job';
    String schoolName = widget.jobData['schoolName'] ?? 'Unknown School';
    String location = widget.jobData.containsKey('locationDetails') &&
            widget.jobData['locationDetails']?['city'] != null
        ? widget.jobData['locationDetails']['city']
        : 'Remote';
    String salary = (widget.jobData['minSalary'] != null &&
            widget.jobData['maxSalary'] != null)
        ? '₹${widget.jobData['minSalary']} - ₹${widget.jobData['maxSalary']}'
        : 'Salary not provided';
    String jobType = widget.jobData['jobType'] ?? 'Type not specified';
    int positions = widget.jobData['positions'] ?? 1;
    bool requireCV = widget.jobData['requireCV'] ?? false;
    List<String> requiredSkills = widget.jobData['requiredSkills'] != null
        ? List<String>.from(widget.jobData['requiredSkills'])
        : [];
    List<String> schedules = widget.jobData['schedules'] != null
        ? List<String>.from(widget.jobData['schedules'])
        : [];

    return InkWell(
      onTap: () {
        _trackJobView(); // Track job view when tapped
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                EmployeeJobDetailsPage(jobId: widget.jobData['id']),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// **Job Title & Save Button**
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          jobTitle,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          schoolName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: _toggleSaved,
                  ),
                ],
              ),

              /// **Location & Salary**
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 14, color: theme.colorScheme.secondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      location,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 10,
                      ),
                    ),
                  ),
                  Text(
                    salary,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              /// **Job Type, Positions, CV Requirement**
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _buildChip(theme, 'Positions: $positions', Icons.people),
                  if (requireCV) _buildChip(theme, 'CV Required', Icons.description),
                  if (jobType != 'Type not specified')
                    _buildChip(theme, jobType, Icons.work),
                ],
              ),
              const SizedBox(height: 8),

              /// **Expand Button for Schedules & Skills**
              GestureDetector(
                onTap: () => setState(() {
                  _isExpanded = !_isExpanded;
                }),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isExpanded ? "Show Less" : "Show More",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),

              /// **Expandable Section: Schedules & Skills**
              AnimatedSize(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _isExpanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),

                          /// **Schedules**
                          if (schedules.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Schedules:",
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12)),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  children: schedules
                                      .map((schedule) => _buildSmallTag(theme, schedule))
                                      .toList(),
                                ),
                              ],
                            ),

                          const SizedBox(height: 6),

                          /// **Skills Required**
                          if (requiredSkills.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Required Skills:",
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12)),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  children: requiredSkills
                                      .map((skill) => _buildSmallTag(theme, skill))
                                      .toList(),
                                ),
                              ],
                            ),
                        ],
                      )
                    : SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// **Job Type, Positions, CV Requirement Tag**
  Widget _buildChip(ThemeData theme, String text, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 12, color: theme.colorScheme.primary),
      label: Text(text, style: GoogleFonts.poppins(fontSize: 10)),
      backgroundColor: theme.colorScheme.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  /// **Skill & Schedule Small Tag**
  Widget _buildSmallTag(ThemeData theme, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }
  
  Future<void> _trackJobView() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final jobId = widget.jobData['id'];

    final jobRef = FirebaseFirestore.instance.collection('jobs').doc(jobId);
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('recentlyViewedJobs')
        .doc(jobId);

    // Increment views count in job document
    await jobRef.update({'views': FieldValue.increment(1)});

    // Add the job to recently viewed jobs
    await userRef.set({
      'jobId': jobId,
      'jobTitle': widget.jobData['jobTitle'],
      'schoolName': widget.jobData['schoolName'],
      'location': widget.jobData['locationDetails']?['city'] ?? 'Remote',
      'viewedAt': FieldValue.serverTimestamp(),
    });

    // Ensure only the last 10 jobs are stored in recently viewed
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('recentlyViewedJobs')
        .orderBy('viewedAt', descending: true)
        .get();

    if (querySnapshot.docs.length > 10) {
      for (int i = 10; i < querySnapshot.docs.length; i++) {
        await querySnapshot.docs[i].reference.delete();
      }
    }
  }
}
