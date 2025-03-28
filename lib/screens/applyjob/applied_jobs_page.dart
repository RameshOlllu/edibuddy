import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../home/employee_job_details_page.dart';
import '../../widgets/job_card_for_recent_jobs.dart';
import 'applied_job_details_page.dart';

class AppliedJobsPage extends StatelessWidget {
  const AppliedJobsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the current user's UID.
    final String employeeId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Applications'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // You can add refresh logic here if needed.
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('job_applications')
              .where('employeeId', isEqualTo: employeeId)
              .orderBy('appliedAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Something went wrong.'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  'No applications found.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final appDoc = snapshot.data!.docs[index];
                final appData = appDoc.data() as Map<String, dynamic>;

                // Retrieve basic application fields.
                final String jobId = appData['jobId'];
                final Timestamp appliedTimestamp = appData['appliedAt'];
                final DateTime appliedAt = appliedTimestamp.toDate();
                final String status = appData['status'] ?? 'Unknown';

                // Fetch the job details using a FutureBuilder.
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('jobs')
                      .doc(jobId)
                      .get(),
                  builder: (context, jobSnapshot) {
                    if (jobSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: const Text('Loading job details...'),
                        ),
                      );
                    }
                    if (jobSnapshot.hasError ||
                        !jobSnapshot.hasData ||
                        !jobSnapshot.data!.exists) {
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: const Text('Job details not available'),
                        ),
                      );
                    }
                    final jobData =
                        jobSnapshot.data!.data() as Map<String, dynamic>;
                    final String jobTitle = jobData['jobTitle'] ?? 'Job Title';
                    final String companyName =
                        jobData['schoolName'] ?? 'Company Name';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          jobTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                companyName,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Applied on: ${DateFormat.yMMMd().format(appliedAt)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Status: $status',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EmployeeJobDetailsPage(jobId: jobId),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
