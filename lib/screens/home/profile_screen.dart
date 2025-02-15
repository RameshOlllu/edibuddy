import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../overview/awards_overview.dart';
import '../overview/education_overview.dart';
import '../overview/job_preferences_overview.dart';
import '../overview/language_overview.dart';
import '../overview/resume_overview_screen.dart';
import '../profilesetup/add_experience_screen.dart';
import '../overview/experience_overview.dart';
// import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  const ProfileScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      setState(() {
        userData = doc.data();
      });
    } catch (e) {
      print("Error fetching user profile: $e");
    }
  }

  String calculateTotalExperience() {
    if (userData == null || userData!['experienceDetails'] == null)
      return '0y 0m';

    final experienceDetails = userData!['experienceDetails'] as List<dynamic>;
    int totalMonths = 0;

    for (var exp in experienceDetails) {
      if (exp is! Map<String, dynamic>) continue; // Skip invalid data

      DateTime? startDate;
      DateTime? endDate;

      if (exp['startDate'] is Timestamp) {
        startDate = (exp['startDate'] as Timestamp).toDate();
      } else if (exp['startDate'] is String) {
        startDate = DateTime.tryParse(exp['startDate']);
      }

      if (exp['isCurrentlyWorking'] == true) {
        endDate = DateTime.now();
      } else if (exp['endDate'] is Timestamp) {
        endDate = (exp['endDate'] as Timestamp).toDate();
      } else if (exp['endDate'] is String) {
        endDate = DateTime.tryParse(exp['endDate']);
      }

      if (startDate == null || endDate == null)
        continue; // Skip if dates are invalid

      totalMonths += ((endDate.year - startDate.year) * 12) +
          (endDate.month - startDate.month);
    }

    int years = totalMonths ~/ 12;
    int months = totalMonths % 12;
    return '${years}y ${months}m';
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // _buildProfileHeader(context),
                  // SizedBox(height: 24),
                  // _buildTotalExperience(context),
                  SizedBox(height: 24),
                  _buildExperienceSection(context),
                  SizedBox(height: 24),
                  _buildEducationSection(context),
                  SizedBox(height: 24),
                  _buildAwardsSection(context),
                  SizedBox(height: 24),
                  _buildLanguageSection(context),
                  SizedBox(height: 24),
                  _buildResumeSection(context),
                  SizedBox(height: 24),
                  _buildJobPreferencesSection(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 160, // Adjusted height to accommodate the profile header
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: _buildProfileHeader(context,
            isSliver: true), // Embed profile header
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, {bool isSliver = false}) {
    // Fetch experience details safely
    final experienceDetails =
        userData?['experienceDetails'] as List<dynamic>? ?? [];

    // Find the current job
    Map<String, dynamic>? currentJob = experienceDetails
        .whereType<
            Map<String,
                dynamic>>() // Safely filter valid Map<String, dynamic> items
        .firstWhere(
          (exp) => exp['isCurrentlyWorking'] == true,
          orElse: () => {}, // Return null if no current job found
        );
    debugPrint(experienceDetails
        .toString()); // If no current job, pick the first record ordered by start date
    if (currentJob.isEmpty) {
      final sortedExperiences = experienceDetails
          .whereType<
              Map<String,
                  dynamic>>() // Safely filter valid Map<String, dynamic> items
          .where((exp) => exp['startDate'] != null)
          .toList()
        ..sort((a, b) {
          final aStartDate = a['startDate'] is Timestamp
              ? (a['startDate'] as Timestamp).toDate()
              : DateTime.tryParse(a['startDate']) ?? DateTime.now();
          final bStartDate = b['startDate'] is Timestamp
              ? (b['startDate'] as Timestamp).toDate()
              : DateTime.tryParse(b['startDate']) ?? DateTime.now();
          return aStartDate.compareTo(bStartDate);
        });
      currentJob =
          sortedExperiences.isNotEmpty ? sortedExperiences.first : null;
    }

    // Fetch location details
    final location = userData?['locationDetails']?['currentLocation']
        as Map<String, dynamic>?;

    return Container(
      padding: isSliver
          ? const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 16)
          : const EdgeInsets.all(16),
      decoration: isSliver
          ? BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Picture and Basic Details
          Row(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: CachedNetworkImageProvider(
                  userData?['photoURL'] ?? '',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Full Name
                    Text(
                      userData?['basicDetails']?['fullName'] ?? '',
                      style: isSliver
                          ? Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: Colors.white)
                          : Theme.of(context).textTheme.headlineMedium,
                    ),
                    // Current Job and Experience
                    if (currentJob != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Current Job Title
                          Text(
                            currentJob['jobTitle'] ?? '',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: isSliver
                                      ? Colors.white70
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                          // Separator
                          const Text('  |  '),
                          // Total Experience
                          Text(
                            calculateTotalExperience(),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: isSliver
                                      ? Colors.white70
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                        ],
                      ),
                    ],
                    // Location Details
                    if (location != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 16,
                              color: isSliver ? Colors.white70 : null),
                          const SizedBox(width: 4),
                          Text(
                            '${location['name']}, ${location['region']}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: isSliver
                                          ? Colors.white70
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ],
                    // Current Package
                    const SizedBox(height: 4),
                    Text(
                      '₹${userData?['jobPreferences']?['currentPackage'] ?? '0'}/year',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isSliver
                                ? Colors.white
                                : Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceSection(BuildContext context) {
    List<Map<String, dynamic>> experiences =
        List<Map<String, dynamic>>.from(userData!['experienceDetails']);

    // Sort by most recent or current experience
    experiences.sort((a, b) {
      final DateTime aEndDate = a['isCurrentlyWorking'] == true
          ? DateTime.now()
          : a['endDate'] is Timestamp
              ? (a['endDate'] as Timestamp).toDate()
              : DateTime.tryParse(a['endDate']) ?? DateTime.now();
      final DateTime bEndDate = b['isCurrentlyWorking'] == true
          ? DateTime.now()
          : b['endDate'] is Timestamp
              ? (b['endDate'] as Timestamp).toDate()
              : DateTime.tryParse(b['endDate']) ?? DateTime.now();
      return bEndDate.compareTo(aEndDate);
    });

    // Limit to top 2 experiences
    final limitedExperiences = experiences.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Experience',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge!
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () async {
                final updatedExperiences = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExperienceOverviewScreen(
                      userId: widget.userId,
                      experiences: experiences,
                    ),
                  ),
                );

                if (updatedExperiences != null) {
                  setState(() {
                    userData!['experienceDetails'] = updatedExperiences;
                  });
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...limitedExperiences.map((exp) {
          return _buildExperienceCard(exp, context);
        }),
        if (experiences.length >
            2) // Show 'View More' if there are more experiences
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () async {
                final updatedExperiences = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExperienceOverviewScreen(
                      userId: widget.userId,
                      experiences: List<Map<String, dynamic>>.from(
                        userData?['experienceDetails'] ?? [],
                      ),
                    ),
                  ),
                );

                if (updatedExperiences != null) {
                  setState(() {
                    userData!['experienceDetails'] = updatedExperiences;
                  });
                }
              },
              child: const Text(
                'View More',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildExperienceCard(Map<String, dynamic> exp, BuildContext context) {
    // Safely parse dates
    final startDate = exp['startDate'] is Timestamp
        ? (exp['startDate'] as Timestamp).toDate()
        : DateTime.tryParse(exp['startDate']) ?? DateTime.now();

    final endDate = exp['isCurrentlyWorking'] == true
        ? DateTime.now()
        : exp['endDate'] is Timestamp
            ? (exp['endDate'] as Timestamp).toDate()
            : DateTime.tryParse(exp['endDate']) ?? DateTime.now();

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Placeholder for Company
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.apartment, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exp['jobTitle'],
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        exp['institutionName'],
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                // Badge for Current or Past
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: exp['isCurrentlyWorking'] == true
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    exp['isCurrentlyWorking'] == true ? 'Current' : 'Past',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: exp['isCurrentlyWorking'] == true
                              ? Colors.green
                              : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Job Roles
            if (exp['jobRole'] != null && (exp['jobRole'] as List).isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Job roles',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  Text(
                    (exp['jobRole'] as List).join(' • '),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            const SizedBox(height: 8),
            // Dates
            Text(
              '${DateFormat('MMM yyyy').format(startDate)} - ${exp['isCurrentlyWorking'] == true ? 'Present' : DateFormat('MMM yyyy').format(endDate)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationSection(BuildContext context) {
    List<Map<String, dynamic>> educationDetails =
        List<Map<String, dynamic>>.from(userData?['educationDetails'] ?? []);

    // Limit to top 2 education entries
    final limitedEducation = educationDetails.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Education',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge!
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () async {
                final updatedEducations = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EducationOverviewScreen(
                      userId: widget.userId,
                      educationDetails: List<Map<String, dynamic>>.from(
                        userData?['educationDetails'] ?? [],
                      ),
                    ),
                  ),
                );

                if (updatedEducations != null) {
                  print(
                      'Updated education details received: ${updatedEducations.length}');
                  setState(() {
                    userData!['educationDetails'] = updatedEducations;
                  });
                } else {
                  print('No updated education details received.');
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...limitedEducation.map((edu) => _buildEducationCard(edu, context)),
        if (educationDetails.length > 2)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () async {
                final updatedEducations = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EducationOverviewScreen(
                      userId: widget.userId,
                      educationDetails: List<Map<String, dynamic>>.from(
                        userData?['educationDetails'] ?? [],
                      ),
                    ),
                  ),
                );

                if (updatedEducations != null) {
                  setState(() {
                    userData!['educationDetails'] = updatedEducations;
                  });
                }
              },
              child: const Text(
                'View More',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          )
      ],
    );
  }

  Widget _buildEducationCard(
      Map<String, dynamic> education, BuildContext context) {
    final bool isPursuing = education['isPursuing'] == true;

    return Stack(
      children: [
        Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Degree and Institution
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon Placeholder for Degree
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.school,
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                    const SizedBox(width: 16),
                    // Degree and Institution
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            education['degree'] ?? "N/A",
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            education['collegeName'] ?? "N/A",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
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
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
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
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
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

                // Highlighted Highest Education Level
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        education['highestEducationLevel'] ?? "N/A",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onTertiaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        education['specialization'] ?? "N/A",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onTertiaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Status Badge Positioned at the Top-Right Corner
        Positioned(
          top: 22,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isPursuing
                  ? Theme.of(context).colorScheme.secondaryContainer
                  : Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isPursuing ? 'Pursuing' : 'Completed',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isPursuing
                        ? Theme.of(context).colorScheme.onSecondaryContainer
                        : Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
      ],
    );
  }

Widget _buildAwardsSection(BuildContext context) {
  List<Map<String, dynamic>> awards = List<Map<String, dynamic>>.from(userData?['awards'] ?? []);

  // Limit to top 2 awards for display
  final limitedAwards = awards.take(2).toList();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Awards & Achievements',
            style: Theme.of(context)
                .textTheme
                .bodyLarge!
                .copyWith(fontWeight: FontWeight.bold),
          ),
          TextButton.icon(
            onPressed: () async {
              final updatedAwards = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AwardsOverviewScreen(
                    userId: widget.userId,
                    awards: List<Map<String, dynamic>>.from(userData?['awards'] ?? []),
                  ),
                ),
              );

              if (updatedAwards != null) {
                setState(() {
                  userData!['awards'] = updatedAwards;
                });
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          ),
        ],
      ),
      const SizedBox(height: 16),
      ...limitedAwards.map((award) => _buildAwardCard(award, context)),
      if (awards.length > 2)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () async {
              final updatedAwards = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AwardsOverviewScreen(
                    userId: widget.userId,
                    awards: List<Map<String, dynamic>>.from(userData?['awards'] ?? []),
                  ),
                ),
              );

              if (updatedAwards != null) {
                setState(() {
                  userData!['awards'] = updatedAwards;
                });
              }
            },
            child: const Text(
              'View More',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
    ],
  );
}

Widget _buildAwardCard(Map<String, dynamic> award, BuildContext context) {
  DateTime? receivedDate;
  if (award['receivedDate'] is String) {
    receivedDate = DateTime.tryParse(award['receivedDate']);
  }

  return Stack(
    children: [
      Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Icon for Award
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.emoji_events, // Icon representing an award
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Award Title
                    Text(
                      award['title'] ?? 'Untitled',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 4),
                    // Award Organization
                    Text(
                      award['organization'] ?? 'Unknown Organization',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    // Description (if available)
                    if (award['description'] != null)
                      Text(
                        award['description'],
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // Date Badge Positioned at the Top-Right Corner
      if (receivedDate != null)
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              DateFormat('MMM yyyy').format(receivedDate),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
    ],
  );
}

Widget _buildLanguageSection(BuildContext context) {
  final languageDetails = userData!['languageDetails'];
  final englishProficiency =
      languageDetails['englishProficiency'] ?? 'Intermediate';
  final otherLanguages =
      List<String>.from(languageDetails['otherLanguages'] ?? []);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Languages',
            style: Theme.of(context)
                .textTheme
                .bodyLarge!
                .copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updatedLanguageDetails = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LanguageOverviewScreen(
                    userId: widget.userId,
                    englishProficiency: englishProficiency,
                    otherLanguages: otherLanguages,
                  ),
                ),
              );

              if (updatedLanguageDetails != null) {
                setState(() {
                  userData!['languageDetails'] = updatedLanguageDetails;
                });
              }
            },
          ),
        ],
      ),
      const SizedBox(height: 16),
      Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              Text(
                englishProficiency,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Divider(height: 24, thickness: 1),
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
                children: otherLanguages.map((language) {
                  return Chip(
                    label: Text(
                      language,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
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

Widget _buildResumeSection(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Resume',
            style: Theme.of(context)
                .textTheme
                .bodyLarge!
                .copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ResumeOverviewScreen(
                    userId: widget.userId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      const SizedBox(height: 16),
      Card(
        child: InkWell(
          onTap: () {
            if (userData != null && userData!['resumeUrl'] != null) {
              // Open resume if URL exists
              debugPrint("Opening resume: ${userData!['resumeUrl']}");
              // Replace this with actual logic to open the resume file
            } else {
              _showSnackBar(context, "No resume available to view.");
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.description),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    userData != null && userData!['resumeUrl'] != null
                        ? 'View Resume'
                        : 'No Resume Uploaded',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const Icon(Icons.open_in_new),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
      duration: const Duration(seconds: 3),
    ),
  );
}



 Widget _buildJobPreferencesSection(BuildContext context) {
  final preferences = userData!['jobPreferences'];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Job Preferences',
            style: Theme.of(context)
                .textTheme
                .bodyLarge!
                .copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updatedPreferences = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => JobPreferencesOverviewScreen(
                    userId: widget.userId,
                    currentPreferences: userData!['jobPreferences'],
                  ),
                ),
              );

              if (updatedPreferences != null) {
                setState(() {
                  userData!['jobPreferences'] = updatedPreferences;
                });
              }
            },
          ),
        ],
      ),
      const SizedBox(height: 16),
      Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Expected Salary Section
              _buildJobPreferenceRow(
                context,
                title: 'Expected Salary',
                value: '₹${preferences['expectedSalary']}/year',
                icon: Icons.currency_rupee_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const Divider(height: 24, thickness: 1),

              // Workplaces Section
              _buildJobPreferenceRow(
                context,
                title: 'Preferred Workplaces',
                value: (preferences['workplaces'] as List).join(', '),
                icon: Icons.location_city_rounded,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const Divider(height: 24, thickness: 1),

              // Shifts Section
              _buildJobPreferenceRow(
                context,
                title: 'Preferred Shifts',
                value: (preferences['shifts'] as List).join(', '),
                icon: Icons.schedule_rounded,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              const Divider(height: 24, thickness: 1),

              // Employment Types Section
              _buildJobPreferenceRow(
                context,
                title: 'Employment Types',
                value: (preferences['employmentTypes'] as List).join(', '),
                icon: Icons.work_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

  Widget _buildJobPreferenceRow(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        SizedBox(width: 16),

        // Title and Value
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
