import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'message_page.dart';
import 'update_applicant_status_page.dart';

class ApplicantDetailsPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Map<String, dynamic> application;
 final String jobId;
  const ApplicantDetailsPage({
    Key? key,
    required this.userData,
    required this.application,
    required this.jobId
  }) : super(key: key);

  @override
  _ApplicantDetailsPageState createState() => _ApplicantDetailsPageState();
}

class _ApplicantDetailsPageState extends State<ApplicantDetailsPage> {
  late String _selectedStatus;
  final List<String> statusOptions = [
    'Applied',
    'Shortlisted',
    'Interview',
    'Rejected',
    'Hired'
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.application['status'] ?? 'Applied';
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _updateStatus() async {
    try {
      // Update the status in the job_applications collection.
      await FirebaseFirestore.instance
          .collection('job_applications')
          .doc(widget.application['id'])
          .update({'status': _selectedStatus});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $_selectedStatus')),
      );
      Navigator.pop(context, true); // Return true to indicate an update.
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final basicDetails = widget.userData['basicDetails'] ?? {};
    final awards = widget.userData['awards'] as List<dynamic>? ?? [];
    final educationDetails =
        widget.userData['educationDetails'] as List<dynamic>? ?? [];
    final experienceDetails =
        widget.userData['experienceDetails'] as List<dynamic>? ?? [];
    final photoUrl = widget.userData['photoURL'] ?? '';

    return WillPopScope(
      onWillPop: () async {
      // This code runs when the user tries to pop (go back)
      Navigator.pop(context, true); // Pass true to the previous screen
      return false; // Prevent the default pop since we've already popped
    },
      child: Scaffold(
        appBar: AppBar(
          title: Text(basicDetails['fullName'] ?? 'Applicant Details'),
        ),
        // Leave extra space at the bottom so that content isn't hidden behind the bottom bar.
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: photoUrl.isNotEmpty
                        ? CachedNetworkImageProvider(photoUrl)
                        : null,
                    child: photoUrl.isEmpty
                        ? const Icon(Icons.person, size: 40)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          basicDetails['fullName'] ?? 'Unknown',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(basicDetails['email'] ?? 'No Email'),
                        const SizedBox(height: 4),
                        Text(basicDetails['mobileNumber'] ?? 'No Mobile Number'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Basic Details Section
              _buildSectionTitle(context, 'Basic Details'),
              _buildDetailRow(
                  'Full Name', basicDetails['fullName'] ?? 'Unknown'),
              _buildDetailRow(
                  'Email', basicDetails['email'] ?? 'Not Provided'),
              _buildDetailRow(
                  'Mobile', basicDetails['mobileNumber'] ?? 'Not Provided'),
              _buildDetailRow(
                  'Gender', basicDetails['gender'] ?? 'Not Specified'),
              // Awards Section
              if (awards.isNotEmpty) ...[
                _buildSectionTitle(context, 'Awards'),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: awards.length,
                  itemBuilder: (context, index) {
                    final award = awards[index] as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(award['title'] ?? 'No Title'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(award['organization'] ?? ''),
                            Text(award['description'] ?? ''),
                            Text('Received: ${award['receivedDate'] ?? ''}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
              // Education Details Section
              if (educationDetails.isNotEmpty) ...[
                _buildSectionTitle(context, 'Education Details'),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: educationDetails.length,
                  itemBuilder: (context, index) {
                    final education =
                        educationDetails[index] as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(education['degree'] ?? 'Unknown Degree'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(education['collegeName'] ?? ''),
                            Text(
                                'Completion Year: ${education['completionYear'] ?? ''}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
              // Experience Details Section
              if (experienceDetails.isNotEmpty) ...[
                _buildSectionTitle(context, 'Experience Details'),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: experienceDetails.length,
                  itemBuilder: (context, index) {
                    final experience =
                        experienceDetails[index] as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title:
                            Text(experience['jobTitle'] ?? 'Unknown Job Title'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Institution: ${experience['institutionName'] ?? ''}'),
                            Text(
                                'Employment Type: ${experience['employmentType'] ?? ''}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
        // Fixed bottom bar for status update.
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
           Expanded(
        child: ElevatedButton(
      onPressed: () async {
        bool? updated = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UpdateApplicantStatusPage(
              application: widget.application,
              userData: widget.userData,
              employerId: FirebaseAuth.instance.currentUser!.uid, // current employer id
              jobId: widget.jobId, // Adjust as needed
              employeeId: widget.application['employeeId'],
            ),
          ),
        );
        if (updated == true) {
          setState(() {
            // Optionally refresh the local application data from Firestore
            // or simply mark that an update occurred so that when ApplicantDetailsPage is popped,
            // JobManagementScreen gets a "true" result.
          });
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text('Update Status & Message', style: TextStyle(color: Colors.white),),
        ),
      ),
        const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to CommunicationMessagesPage.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CommunicationMessagesPage(
                          applicationId: widget.application['id'],
                          jobId: widget.jobId, // Replace with your job id.
                          employeeId: widget.application['employeeId'],
                          employerId: FirebaseAuth.instance.currentUser!.uid, // Replace with your employer id.
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('View Conversation', style: TextStyle(color: Colors.white),),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}