import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/profilesetup/splash_screen_with_tabs.dart';
import 'employee_job_details_page.dart';

class SavedJobsPage extends StatelessWidget {
  const SavedJobsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Pinned App Bar to match your home screen style
            SliverAppBar(
              pinned: true,
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 2,
              leading: IconButton(
                icon:
                    Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SplashScreenWithTabs(initialTabIndex: 1),
                    ),
                  );
                },
              ),
              title: Text(
                'Saved Jobs',
                style: theme.textTheme.titleLarge,
              ),
            ),

            // StreamBuilder to fetch the saved jobs for the current user
            SliverFillRemaining(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('savedJobs')
                    .orderBy('savedAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }
                  if (snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'No saved jobs found.',
                        style: theme.textTheme.bodyLarge,
                      ),
                    );
                  }

                  // Use ListView.builder to create a list of job cards
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final savedJobDoc = snapshot.data!.docs[index];
                      // Use the document ID as the jobId
                      final jobId = savedJobDoc.id;
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('jobs')
                            .doc(jobId)
                            .get(),
                        builder: (context, jobSnapshot) {
                          if (jobSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text('Loading job details...'),
                              ),
                            );
                          }
                          if (jobSnapshot.hasError ||
                              !jobSnapshot.hasData ||
                              !jobSnapshot.data!.exists) {
                            return const SizedBox();
                          }
                          final jobData =
                              jobSnapshot.data!.data() as Map<String, dynamic>;
                          return _buildSavedJobCard(context, jobData, jobId);
                        },
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSavedJobCard(
      BuildContext context, Map<String, dynamic> jobData, String jobId) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EmployeeJobDetailsPage(jobId: jobId),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Company/School logo or initial in a circle
              CircleAvatar(
                radius: 30,
                backgroundColor: theme.colorScheme.primary,
                backgroundImage: jobData['companyLogo'] != null
                    ? NetworkImage(jobData['companyLogo'])
                    : null,
                child: jobData['companyLogo'] == null
                    ? Text(
                        jobData['schoolName'] != null &&
                                jobData['schoolName'].toString().isNotEmpty
                            ? jobData['schoolName'][0].toUpperCase()
                            : 'A',
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(color: Colors.white),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              // Job details: title, school, location
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jobData['jobTitle'] ?? 'Job Title',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      jobData['schoolName'] ?? 'School Name',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            jobData['jobLocation'] ?? 'Location not specified',
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
