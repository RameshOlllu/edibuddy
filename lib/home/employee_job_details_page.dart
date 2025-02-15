import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../screens/applyjob/walkin_application_page.dart';

class EmployeeJobDetailsPage extends StatefulWidget {
  final String jobId;

  const EmployeeJobDetailsPage({Key? key, required this.jobId})
      : super(key: key);

  @override
  _EmployeeJobDetailsPageState createState() => _EmployeeJobDetailsPageState();
}

class _EmployeeJobDetailsPageState extends State<EmployeeJobDetailsPage>
    with SingleTickerProviderStateMixin {
  late Future<DocumentSnapshot> _jobFuture;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _jobFuture =
        FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).get();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<DocumentSnapshot>(
      future: _jobFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error: ${snapshot.error}',
                  style: theme.textTheme.bodyMedium),
            ),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            body: Center(
              child: Text('Job not found', style: theme.textTheme.bodyMedium),
            ),
          );
        }

        final jobData = snapshot.data!.data() as Map<String, dynamic>;

        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  floating: false,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back,
                        color: theme.colorScheme.onSurface),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.share, color: theme.colorScheme.primary),
                      onPressed: () {
                        // Share job details
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.more_vert,
                          color: theme.colorScheme.onSurface),
                      onPressed: () {
                        // More options
                      },
                    ),
                  ],
                  title: Text(
                    jobData['jobTitle'] ?? 'Job Details',
                    style: theme.textTheme.titleLarge,
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primaryContainer,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Opacity(
                          opacity: 0.15,
                          child: Icon(
                            Icons.work_outline,
                            size: 120,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  bottom: TabBar(
                    controller: _tabController,
                    labelColor: theme.colorScheme.onSurface,
                    unselectedLabelColor:
                        theme.colorScheme.onSurface.withOpacity(0.7),
                    indicatorColor: theme.colorScheme.secondary,
                    tabs: const [
                      Tab(text: 'Job Details'),
                      Tab(text: 'Walk‑In'),
                      Tab(text: 'About Employer'),
                    ],
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildJobDetailsTab(jobData),
                _buildWalkInTab(jobData),
                _buildAboutEmployerTab(jobData),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomBar(),
        );
      },
    );
  }

  Widget _buildJobDetailsTab(Map<String, dynamic> jobData) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildJobHeader(jobData),
          const SizedBox(height: 16),
          _buildJobDescription(jobData),
          const SizedBox(height: 16),
          _buildJobRequirements(jobData),
          const SizedBox(height: 16),
          _buildSalaryAndBenefits(jobData),
        ],
      ),
    );
  }

  Widget _buildWalkInTab(Map<String, dynamic> jobData) {
    final theme = Theme.of(context);
    final walkInDetails = jobData['walkInDetails'];
    if (walkInDetails == null || walkInDetails['hasWalkIn'] != true) {
      return Center(
        child: Text('No walk‑in interview details available',
            style: theme.textTheme.bodyMedium),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Walk‑In Interview Details',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWalkInItem(
                      Icons.location_on, 'Venue', walkInDetails['venue']),
                  _buildWalkInItem(
                      Icons.person, 'Contact', walkInDetails['contactPerson']),
                  _buildWalkInItem(
                      Icons.phone, 'Phone', walkInDetails['contactNumber']),
                  const SizedBox(height: 8),
                  Text(
                    'Interview Slots:',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ..._buildInterviewSlots(walkInDetails['slots']),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutEmployerTab(Map<String, dynamic> jobData) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About the Employer',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildEmployerProfileSection(jobData),
        ],
      ),
    );
  }

  Widget _buildEmployerProfileSection(Map<String, dynamic> jobData) {
    final theme = Theme.of(context);
    final employerId =
        jobData['userId']; // Ensure your job document contains this field
    if (employerId == null) return const SizedBox.shrink();

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(employerId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Text('Employer info not available',
              style: theme.textTheme.bodyMedium);
        }
        final employerData = snapshot.data!.data() as Map<String, dynamic>;
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with profile picture and employer name.
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: employerData['profileImageUrl'] != null
                          ? NetworkImage(employerData['profileImageUrl'])
                          : null,
                      child: employerData['profileImageUrl'] == null
                          ? const Icon(Icons.business, size: 30)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        employerData['schoolName'] ?? 'Employer Name',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Website (if available).
                if (employerData['website'] != null &&
                    employerData['website'].toString().isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.link,
                          size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          employerData['website'],
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                // Phone contact.
                Row(
                  children: [
                    Icon(Icons.phone,
                        size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      employerData['phone'] ?? 'N/A',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Location details.
                Row(
                  children: [
                    Icon(Icons.location_on,
                        size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        employerData['location'] != null
                            ? "${employerData['location']['city'] ?? ''}, ${employerData['location']['state'] ?? ''}"
                            : 'Location not specified',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Employer description.
                Text(
                  employerData['companyDescription'] ??
                      'No description provided',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildJobHeader(Map<String, dynamic> jobData) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          jobData['jobTitle'] ?? 'Job Title',
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          jobData['schoolName'] ?? 'School Name',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.location_on, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              jobData['jobLocation'] ?? 'Location',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            Chip(
              label: Text(jobData['jobType'] ?? 'Job Type'),
              backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
            ),
            Chip(
              label: Text('${jobData['positions'] ?? 'N/A'} openings'),
              backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildJobDescription(Map<String, dynamic> jobData) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Job Description',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          jobData['description'] ?? 'No description provided',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildJobRequirements(Map<String, dynamic> jobData) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Requirements',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          jobData['qualifications'] ?? 'No specific qualifications mentioned',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        if (jobData['requiredSkills'] != null)
          Wrap(
            spacing: 8,
            children: (jobData['requiredSkills'] as List)
                .map<Widget>(
                  (skill) => Chip(
                    label: Text(skill.toString()),
                    backgroundColor:
                        theme.colorScheme.secondary.withOpacity(0.1),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildSalaryAndBenefits(Map<String, dynamic> jobData) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Salary and Benefits',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Salary Range: ${formatter.format(jobData['minSalary'] ?? 0)} - ${formatter.format(jobData['maxSalary'] ?? 0)} per year',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        if (jobData['benefits'] != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Benefits:',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              ...((jobData['benefits'] as List)
                  .map<Widget>(
                    (benefit) => Text(
                      '• $benefit',
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                  .toList()),
            ],
          ),
      ],
    );
  }

  List<Widget> _buildInterviewSlots(List? slots) {
    final theme = Theme.of(context);
    if (slots == null || slots.isEmpty) {
      return [
        Text('No slots specified', style: theme.textTheme.bodyMedium),
      ];
    }
    return slots.map<Widget>((slot) {
      final date = (slot['date'] as Timestamp).toDate();
      final startTime = TimeOfDay(
          hour: slot['startTime']['hour'], minute: slot['startTime']['minute']);
      final endTime = TimeOfDay(
          hour: slot['endTime']['hour'], minute: slot['endTime']['minute']);
      return Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: Text(
          '• ${DateFormat('EEEE, MMMM d').format(date)}: ${startTime.format(context)} - ${endTime.format(context)}',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }).toList();
  }

  Widget _buildWalkInItem(IconData icon, String label, String? value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value ?? 'Not specified',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        WalkInApplicationPage(jobId: widget.jobId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Apply Now',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.onPrimary),
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: Icon(Icons.bookmark_border, color: theme.colorScheme.primary),
            onPressed: () {
              // Implement save job logic
            },
          ),
        ],
      ),
    );
  }
}
