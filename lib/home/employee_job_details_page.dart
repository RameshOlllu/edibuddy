import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../screens/applyjob/online_application_page.dart';
import '../screens/applyjob/walkin_application_page.dart';
import 'employer/message_page.dart';

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
  bool _isSaved = false;
  bool _hasApplied = false;
  Map<String, dynamic>? _applicationData;
  @override
  void initState() {
    super.initState();
    _jobFuture =
        FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).get();
    _tabController = TabController(length: 3, vsync: this);
    _checkIfJobSaved();
    _checkIfUserApplied();
  }

  void _checkIfUserApplied() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final query = await FirebaseFirestore.instance
        .collection('job_applications')
        .where('jobId', isEqualTo: widget.jobId)
        .where('employeeId', isEqualTo: userId)
        .get();

    if (query.docs.isNotEmpty) {
      setState(() {
        _hasApplied = true;
        _applicationData = {
          ...query.docs.first.data(),
          'id': query.docs.first.id, // Add the document ID to the data
        };
      });
    }
  }

  void _checkIfJobSaved() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final savedJobDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('savedJobs')
        .doc(widget.jobId)
        .get();
    setState(() {
      _isSaved = savedJobDoc.exists;
    });
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
                      icon: Icon(
                        _isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: theme.colorScheme.primary,
                      ),
                      iconSize: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      constraints: const BoxConstraints(),
                      onPressed:
                          _toggleSaveJob, // Function to toggle job save state
                    ),
                    //                 IconButton(
                    //                   icon: Icon(Icons.share, color: theme.colorScheme.primary),
                    //                   iconSize: 20,
                    // padding: const EdgeInsets.symmetric(horizontal: 4),
                    //                   onPressed: () {
                    //                     // Share job details
                    //                   },
                    //                 ),
                    IconButton(
                      icon: Icon(Icons.chat, color: theme.colorScheme.primary),
                      iconSize: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        if (!_hasApplied) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "Please apply to the job before initiating a chat."),
                            ),
                          );
                          return;
                        }
                        // Navigate to CommunicationMessagesPage.
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CommunicationMessagesPage(
                              applicationId: _applicationData!['id'],
                              jobId: widget.jobId,
                              employeeId:
                                  FirebaseAuth.instance.currentUser!.uid,
                              employerId: jobData[
                                  'userId'], // from your jobData fetched from Firestore
                            ),
                          ),
                        );
                      },
                    ),
                    //                 IconButton(
                    //                   icon: Icon(Icons.more_vert,
                    //                       color: theme.colorScheme.onSurface),
                    //                       iconSize: 20,
                    // padding: const EdgeInsets.symmetric(horizontal: 4),
                    //                   onPressed: () {
                    //                     // More options
                    //                   },
                    //                 ),
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
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                if (_hasApplied) {
                  _showApplicationStatusModal(context);
                } else {
                  _handleApplyNow(context, jobData);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                _hasApplied ? 'View Application Status' : 'Apply Now',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.onPrimary),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showApplicationStatusModal(BuildContext context) {
    final theme = Theme.of(context);
    if (_applicationData == null) return;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              /// **Header**
              Center(
                child: Text(
                  "Application Status",
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),

              /// **Application Date**
              Row(
                children: [
                  Icon(Icons.date_range, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    "Applied on: ${DateFormat('dd MMM yyyy').format((_applicationData!['appliedAt'] as Timestamp).toDate())}",
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              /// **Application Status**
              Row(
                children: [
                  Icon(Icons.info, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    "Status: ${_applicationData!['status']}",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _getStatusColor(_applicationData!['status']),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              /// **Interview Slot (If Available)**
              if (_applicationData!['selectedSlot'] != null) ...[
                Row(
                  children: [
                    Icon(Icons.schedule, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Interview Slot: ${_formatInterviewSlot(_applicationData!['selectedSlot'])}",
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              /// **Resume Link**
              if (_applicationData!['resumeUrl'] != null) ...[
                Row(
                  children: [
                    Icon(Icons.file_present, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _openResume(_applicationData!['resumeUrl']),
                      child: Text(
                        "View Resume",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              /// **Additional Details**
              if (_applicationData!['additionalDetails'] != null &&
                  _applicationData!['additionalDetails']
                      .toString()
                      .isNotEmpty) ...[
                Text(
                  "Additional Details:",
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _applicationData!['additionalDetails'],
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
              ],

              /// **Close Button**
              /// **Close Button - Enhanced Design**
              Center(
                child: SizedBox(
                  width: double.infinity, // Make button full width
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          theme.colorScheme.primary, // Use theme color
                      foregroundColor:
                          theme.colorScheme.onPrimary, // Text color
                      padding: const EdgeInsets.symmetric(
                          vertical: 14), // Increase padding
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12), // Rounded corners
                      ),
                      elevation: 2, // Subtle shadow effect
                    ),
                    child: Text(
                      "Close",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5, // Improve readability
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Applied":
        return Colors.blue;
      case "Shortlisted":
        return Colors.green;
      case "Rejected":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatInterviewSlot(Map<String, dynamic> slot) {
    final date = (slot['date'] as Timestamp).toDate();
    final startTime = TimeOfDay(
        hour: slot['startTime']['hour'], minute: slot['startTime']['minute']);
    final endTime = TimeOfDay(
        hour: slot['endTime']['hour'], minute: slot['endTime']['minute']);

    return "${DateFormat('EEEE, MMM d').format(date)}\n${startTime.format(context)} - ${endTime.format(context)}";
  }

  void _openResume(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open resume')),
      );
    }
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

  void _handleApplyNow(BuildContext context, Map<String, dynamic> jobData) {
    final walkInDetails = jobData['walkInDetails'];

    if (walkInDetails != null && walkInDetails['hasWalkIn'] == true) {
      // Navigate to Walk-In Page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WalkInApplicationPage(jobId: widget.jobId),
        ),
      );
    } else {
      // Navigate to New Online Application Page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OnlineApplicationPage(jobId: widget.jobId),
        ),
      );
    }
  }

  void _toggleSaveJob() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    if (_isSaved) {
      // Remove job from saved list
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('savedJobs')
          .doc(widget.jobId)
          .delete();
    } else {
      // Add job to saved list
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('savedJobs')
          .doc(widget.jobId)
          .set({'savedAt': FieldValue.serverTimestamp()});
    }

    setState(() {
      _isSaved = !_isSaved;
    });
  }
}
