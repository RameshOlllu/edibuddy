import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
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
  if (userData == null || userData!['experienceDetails'] == null) return '0y 0m';

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

    if (startDate == null || endDate == null) continue; // Skip if dates are invalid

    totalMonths += ((endDate.year - startDate.year) * 12) + (endDate.month - startDate.month);
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
      background: _buildProfileHeader(context, isSliver: true), // Embed profile header
    ),
  );
}

Widget _buildProfileHeader(BuildContext context, {bool isSliver = false}) {
  final experienceDetails = userData?['experienceDetails'] as List<dynamic>? ?? [];
  final currentJob = experienceDetails.isNotEmpty
      ? experienceDetails.firstWhere(
          (exp) => exp is Map<String, dynamic> && exp['isCurrentlyWorking'] == true,
          orElse: () => null,
        )
      : null;

  final location = userData?['locationDetails']?['currentLocation'] as Map<String, dynamic>?;

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
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userData?['basicDetails']?['fullName'] ?? '',
                    style: isSliver
                        ? Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white)
                        : Theme.of(context).textTheme.headlineMedium,
                  ),
                  if (currentJob != null) ...[
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          currentJob['jobTitle'] ?? '',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isSliver
                                    ? Colors.white70
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        Text('  |  ',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: isSliver
                                      ? Colors.white70
                                      : Theme.of(context).colorScheme.onSurface,
                                )),
                        Text(
                          calculateTotalExperience(),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isSliver
                                    ? Colors.white70
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 4),
                  if (location != null) ...[
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 16, color: isSliver ? Colors.white70 : null),
                        SizedBox(width: 4),
                        Text(
                          '${location['name']}, ${location['region']}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isSliver
                                    ? Colors.white70
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 4),
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
  final experiences = userData!['experienceDetails'];
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Experience',
       style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 16),
      ...experiences.map<Widget>((exp) {
        // Safely parse startDate
        DateTime? startDate;
        if (exp['startDate'] is Timestamp) {
          startDate = (exp['startDate'] as Timestamp).toDate();
        } else if (exp['startDate'] is String) {
          startDate = DateTime.tryParse(exp['startDate']);
        }

        // Safely parse endDate
        DateTime? endDate;
        if (exp['isCurrentlyWorking'] == true) {
          endDate = DateTime.now();
        } else if (exp['endDate'] is Timestamp) {
          endDate = (exp['endDate'] as Timestamp).toDate();
        } else if (exp['endDate'] is String) {
          endDate = DateTime.tryParse(exp['endDate']);
        }

        // Handle invalid dates
        if (startDate == null || endDate == null) {
          return SizedBox.shrink(); // Skip rendering this experience
        }

        return Card(
          elevation: 3,
          margin: EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Job Title and Institution Name
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
                    SizedBox(width: 16),
                    // Job Details
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
                          SizedBox(height: 4),
                          Text(
                            exp['institutionName'],
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    // Badge for Current or Past
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                SizedBox(height: 16),
                // Job Role and Industry
                if (exp['jobRole'] != null && (exp['jobRole'] as List).isNotEmpty) ...[
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
                  SizedBox(height: 8),
                ],
                if (exp['industry'] != null) ...[
                  Text(
                    'Industry',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  Text(
                    exp['industry'],
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  SizedBox(height: 8),
                ],
                // Description Placeholder
                Text(
                  'Add a description of your role to provide more details',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[400],
                        fontStyle: FontStyle.italic,
                      ),
                ),
                SizedBox(height: 16),
                // Skills Section
                if (exp['skills'] != null && (exp['skills'] as List).isNotEmpty) ...[
                  Text(
                    'Skills',
                       style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 1),
                  Wrap(
                    spacing: 8,
                    runSpacing: 0,
                    children: (exp['skills'] as List).map<Widget>((skill) {
                      return Chip(
                        label: Text(
                          skill,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        backgroundColor: Theme.of(context)
                            .primaryColor
                            .withOpacity(0.1),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16),
                ],
                // Start Date - End Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${DateFormat('MMM yyyy').format(startDate)} - ${exp['isCurrentlyWorking'] == true ? 'Present' : DateFormat('MMM yyyy').format(endDate)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ],
  );
}

Widget _buildEducationSection(BuildContext context) {
  final education = userData!['educationDetails'];
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Education',
        style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 16),
      ...education.map<Widget>((edu) {
        final bool isPursuing = edu['isPursuing'] == true;

        return Card(
          elevation: 3,
          margin: EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
                    SizedBox(width: 16),
                    // Degree and Institution
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            edu['degree'],
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            edu['collegeName'],
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    // Status Badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPursuing
                            ? Theme.of(context).colorScheme.secondaryContainer
                            : Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isPursuing ? 'Pursuing' : 'Completed',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isPursuing
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer
                                  : Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
               // SizedBox(height: 16),

                // Specialization as a Badge
                // Wrap(
                //   spacing: 8,
                //   runSpacing: 8,
                //   children: [
                //     Chip(
                //       label: Text(
                //         edu['specialization'],
                //         style: Theme.of(context).textTheme.bodySmall?.copyWith(
                //               fontWeight: FontWeight.bold,
                //               color:
                //                   Theme.of(context).colorScheme.onPrimaryContainer,
                //             ),
                //       ),
                //       backgroundColor:
                //           Theme.of(context).colorScheme.primaryContainer,
                //     ),
                //   ],
                // ),
                SizedBox(height: 16),

                // Completion Year and School Medium
                Row(
                  children: [
                    // Completion Year
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Completion Year',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            edu['completionYear'],
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    // School Medium
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
                          SizedBox(height: 4),
                          Text(
                            edu['schoolMedium'],
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Highlighted Highest Education Level
                Row(
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        edu['highestEducationLevel'],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onTertiaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    SizedBox(width: 10,),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        edu['specialization'],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
        );
      }).toList(),
    ],
  );
}

Widget _buildAwardsSection(BuildContext context) {
  final awards = userData!['awards'];
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Awards & Achievements',
        style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 16),
      ...awards.map<Widget>((award) {
        // Safely parse receivedDate
        DateTime? receivedDate;
        if (award['receivedDate'] is Timestamp) {
          receivedDate = (award['receivedDate'] as Timestamp).toDate();
        } else if (award['receivedDate'] is String) {
          receivedDate = DateTime.tryParse(award['receivedDate']);
        }

        // Handle invalid dates
        if (receivedDate == null) {
          return SizedBox.shrink(); // Skip rendering this award
        }

        return Card(
          elevation: 3,
          margin: EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Award Title
                      Text(
                        award['title'],
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                         
                      ),
                      SizedBox(height: 2),
                      // Award Organization
                      Text(
                        award['organization'],
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      SizedBox(height: 8),
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
                SizedBox(width: 16),
                // Date Badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    DateFormat('MMM yyyy').format(receivedDate),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ],
  );
}

Widget _buildLanguageSection(BuildContext context) {
  final languageDetails = userData!['languageDetails'];
  final englishProficiency = languageDetails['englishProficiency'] ?? 'Intermediate';
  final otherLanguages = List<String>.from(languageDetails['otherLanguages'] ?? []);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Languages',
             style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 16),
      Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // English Proficiency
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

              // Other Languages
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
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
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
        Text(
          'Resume',
      style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Card(
          child: InkWell(
         //   onTap: () => launchUrl(Uri.parse(userData!['resumeUrl'])),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.description),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'View Resume',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Icon(Icons.open_in_new),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

 Widget _buildJobPreferencesSection(BuildContext context) {
  final preferences = userData!['jobPreferences'];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Job Preferences',
      style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 16),
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