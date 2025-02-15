import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppliedJobDetailsPage extends StatefulWidget {
  final String applicationId;

  const AppliedJobDetailsPage({Key? key, required this.applicationId})
      : super(key: key);

  @override
  _AppliedJobDetailsPageState createState() => _AppliedJobDetailsPageState();
}

class _AppliedJobDetailsPageState extends State<AppliedJobDetailsPage>
    with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _dataFuture;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchData();
    _tabController = TabController(length: 2, vsync: this);
  }

  /// Fetch both the application details and the corresponding job details.
  Future<Map<String, dynamic>> _fetchData() async {
    // Fetch application document.
    DocumentSnapshot appSnapshot = await FirebaseFirestore.instance
        .collection('job_applications')
        .doc(widget.applicationId)
        .get();
    if (!appSnapshot.exists) {
      throw Exception('Application not found');
    }
    Map<String, dynamic> applicationData =
        appSnapshot.data() as Map<String, dynamic>;
    String jobId = applicationData['jobId'];

    // Fetch job document.
    DocumentSnapshot jobSnapshot = await FirebaseFirestore.instance
        .collection('jobs')
        .doc(jobId)
        .get();
    if (!jobSnapshot.exists) {
      throw Exception('Job not found');
    }
    Map<String, dynamic> jobData = jobSnapshot.data() as Map<String, dynamic>;

    return {'application': applicationData, 'job': jobData};
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Build the job details tab (similar to your EmployeeJobDetailsPage).
  Widget _buildJobDetailsTab(Map<String, dynamic> jobData) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Job header.
          Text(
            jobData['jobTitle'] ?? 'Job Title',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            jobData['schoolName'] ?? 'Company Name',
            style: theme.textTheme.titleSmall,
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
          const SizedBox(height: 16),
          // Job description.
          Text(
            'Job Description',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            jobData['description'] ?? 'No description provided',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          // You can add additional sections (requirements, benefits, etc.) here.
        ],
      ),
    );
  }

  /// Build the application details tab.
  Widget _buildApplicationDetailsTab(Map<String, dynamic> applicationData) {
    final theme = Theme.of(context);
    final Timestamp appliedAtTimestamp = applicationData['appliedAt'];
    final DateTime appliedAt = appliedAtTimestamp.toDate();
    final String status = applicationData['status'] ?? 'Unknown';
    final selectedSlot = applicationData['selectedSlot'];
    String slotInfo = 'Not specified';
    if (selectedSlot != null) {
      final date = (selectedSlot['date'] as Timestamp).toDate();
      final startTime = TimeOfDay(
        hour: selectedSlot['startTime']['hour'],
        minute: selectedSlot['startTime']['minute'],
      );
      final endTime = TimeOfDay(
        hour: selectedSlot['endTime']['hour'],
        minute: selectedSlot['endTime']['minute'],
      );
      slotInfo =
          '${DateFormat('EEEE, MMMM d').format(date)}\n${startTime.format(context)} - ${endTime.format(context)}';
    }
    final resumeUrl = applicationData['resumeUrl'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Application Details',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Applied On: ${DateFormat.yMMMd().format(appliedAt)}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Status: $status',
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (selectedSlot != null) ...[
            Text(
              'Selected Interview Slot:',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              slotInfo,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
          ],
          if (resumeUrl != null) ...[
            Text(
              'Resume:',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                // TODO: Open the resume (e.g., launch URL or open in PDF viewer).
              },
              child: Text(
                'View Resume',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.primaryColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<Map<String, dynamic>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Applied Job Details')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Applied Job Details')),
            body: const Center(child: Text('Error loading details')),
          );
        }
        final applicationData = snapshot.data!['application'] as Map<String, dynamic>;
        final jobData = snapshot.data!['job'] as Map<String, dynamic>;

        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  floating: false,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
                    onPressed: () => Navigator.pop(context),
                  ),
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
                            theme.primaryColor,
                            theme.primaryColorLight,
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
                    unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.7),
                    indicatorColor: theme.colorScheme.secondary,
                    tabs: const [
                      Tab(text: 'Job Details'),
                      Tab(text: 'Application Details'),
                    ],
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildJobDetailsTab(jobData),
                _buildApplicationDetailsTab(applicationData),
              ],
            ),
          ),
        );
      },
    );
  }
}
