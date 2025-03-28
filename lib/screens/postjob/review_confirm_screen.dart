import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'add_basic_details.dart';
import 'add_job_details.dart';
import 'job_description_screen.dart';
import 'pay_benefits_screen.dart';
import 'set_preferences_screen.dart';
import 'walk_in_interview_screen.dart';

class ReviewAndConfirmScreen extends StatefulWidget {
  final String jobId;

  const ReviewAndConfirmScreen({Key? key, required this.jobId}) : super(key: key);

  @override
  _ReviewAndConfirmScreenState createState() => _ReviewAndConfirmScreenState();
}

class _ReviewAndConfirmScreenState extends State<ReviewAndConfirmScreen> {
  Map<String, dynamic>? _jobData;
  bool _isLoading = true;
  final currencyFormatter = NumberFormat.currency(symbol: '\$');

  @override
  void initState() {
    super.initState();
    _fetchJobData();
  }

  Future<void> _fetchJobData() async {
    try {
      setState(() => _isLoading = true);
      final doc = await FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.jobId)
          .get();

      if (doc.exists) {
        setState(() {
          _jobData = doc.data();
          _isLoading = false;
        });
      } else {
        _showError('Job not found.');
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Error fetching job data: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _navigateToEdit(String section) async {
    Widget screen;
    switch (section) {
      case 'walkin':
        screen = WalkInInterviewScreen(
          jobId: widget.jobId,
          jobData: _jobData,
          isEdit: true,
        );
        break;
      case 'basics':
        screen = AddJobBasicsScreen(jobId: widget.jobId, jobData: _jobData);
        break;
      case 'details':
        screen = JobDetailsScreen(jobId: widget.jobId, jobData: _jobData,isEdit: true,);
        break;
      case 'description':
        screen = JobDescriptionScreen(jobId: widget.jobId, jobData: _jobData,isEdit: true,);
        break;
      case 'compensation':
        screen = PayBenefitsScreen(jobId: widget.jobId, jobData: _jobData,isEdit: true,);
        break;
      case 'preferences':
        screen = SetPreferencesScreen(jobId: widget.jobId, jobData: _jobData,isEdit: true,);
        break;
      default:
        return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );

    if (result == true) {
      _fetchJobData(); // Refresh data after edit
    }
  }

  Future<void> _postJob() async {
    try {
      setState(() => _isLoading = true);

      User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showError('User not logged in.');
      setState(() => _isLoading = false);
      return;
    }
    String userId = currentUser.uid;

    // 2. Fetch the user's record from the "users" collection
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (!userDoc.exists) {
      _showError('User record not found.');
      setState(() => _isLoading = false);
      return;
    }

    // 3. Get the schoolName from the user's record
    final userData = userDoc.data() as Map<String, dynamic>;
    String schoolName = userData['schoolName'] ?? 'Not Specified';

    
      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.jobId)
          .update({
        'status': 'posted',
        'postedAt': Timestamp.now(),
        'schoolName': schoolName,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job posted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      _showError('Error posting job: $e');
      setState(() => _isLoading = false);
    }
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
    required String editSection,
    Widget? trailing,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        initiallyExpanded: true, // Make sections expanded by default
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null) trailing,
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _navigateToEdit(editSection),
              tooltip: 'Edit $title',
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Not specified',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipsList(List<dynamic>? items) {
    if (items == null || items.isEmpty) {
      return const Text('None selected');
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) => Chip(label: Text(item.toString()))).toList(),
    );
  }

  Widget _buildBasicInfo() {
    return _buildSectionCard(
      title: 'Basic Information',
      editSection: 'basics',
      children: [
        _buildInfoRow('Job Title', _jobData?['jobTitle']),
        _buildInfoRow('Company Description', _jobData?['companyDescription']),
        _buildInfoRow(
          'Location',
          _jobData?['jobLocation'] == 'Remote'
              ? 'Remote'
              : _jobData?['address'],
        ),
      ],
    );
  }

  Widget _buildJobDetails() {
    return _buildSectionCard(
      title: 'Job Details',
      editSection: 'details',
      children: [
        _buildInfoRow('Job Type', _jobData?['jobType']),
        _buildInfoRow('Positions', _jobData?['positions']?.toString()),
        const SizedBox(height: 8),
        Text(
          'Work Schedule',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _buildChipsList(_jobData?['schedules']),
      ],
    );
  }

  Widget _buildJobDescription() {
    return _buildSectionCard(
      title: 'Job Description',
      editSection: 'description',
      children: [
        _buildInfoRow('Description', _jobData?['description']),
        _buildInfoRow('Qualifications', _jobData?['qualifications']),
        const SizedBox(height: 8),
        Text(
          'Required Skills',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _buildChipsList(_jobData?['requiredSkills']),
      ],
    );
  }

  Widget _buildCompensation() {
    final minSalary = _jobData?['minSalary'];
    final maxSalary = _jobData?['maxSalary'];
    
    return _buildSectionCard(
      title: 'Compensation & Benefits',
      editSection: 'compensation',
      children: [
        _buildInfoRow(
          'Salary Range',
          '${minSalary != null ? currencyFormatter.format(minSalary) : 'Not specified'} - ${maxSalary != null ? currencyFormatter.format(maxSalary) : 'Not specified'}',
        ),
        const SizedBox(height: 8),
        Text(
          'Additional Compensation',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _buildChipsList(_jobData?['compensation']),
        const SizedBox(height: 16),
        Text(
          'Benefits',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _buildChipsList(_jobData?['benefits']),
      ],
    );
  }

  Widget _buildPreferences() {
    return _buildSectionCard(
      title: 'Application Preferences',
      editSection: 'preferences',
      children: [
        _buildInfoRow('Contact Number', _jobData?['applicantContact']),
        _buildInfoRow('Updates Email', _jobData?['dailyUpdatesEmail']),
        _buildInfoRow(
          'CV Required',
          _jobData?['requireCV'] == true ? 'Yes' : 'No',
        ),
        _buildInfoRow(
          'Optional CV',
          _jobData?['allowOptionalCV'] == true ? 'Allowed' : 'Not Allowed',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Job Posting'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _fetchJobData,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      Text(
                        'Review your job posting',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please review all details carefully before posting.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 24),
                      _buildBasicInfo(),
                      _buildJobDetails(),
                      _buildWalkInDetails(), 
                      _buildJobDescription(),
                      _buildCompensation(),
                      _buildPreferences(),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Back'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _postJob,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Confirm & Post'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildWalkInDetails() {
    final walkInDetails = _jobData?['walkInDetails'];
    if (walkInDetails == null || walkInDetails['hasWalkIn'] != true) {
      return _buildSectionCard(
        title: 'Walk-in Interview',
        editSection: 'walkin',
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No walk-in interviews scheduled',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ),
        ],
      );
    }

    return _buildSectionCard(
      title: 'Walk-in Interview Details',
      editSection: 'walkin',
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: Icon(
                  Icons.location_on,
                  color: Theme.of(context).primaryColor,
                ),
                title: Text(
                  walkInDetails['venue'] ?? 'Venue not specified',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(walkInDetails['interviewMode'] ?? ''),
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                  Icons.person,
                  color: Theme.of(context).primaryColor,
                ),
                title: Text(
                  walkInDetails['contactPerson'] ?? 'Contact not specified',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(walkInDetails['contactNumber'] ?? ''),
              ),
              if (walkInDetails['additionalInfo']?.isNotEmpty ?? false) ...[
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Additional Information',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(walkInDetails['additionalInfo']),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Interview Slots',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        _buildInterviewSlots(walkInDetails['slots']),
        if (walkInDetails['requiresDocuments'] == true) ...[
          const SizedBox(height: 24),
          Text(
            'Required Documents',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          _buildRequiredDocuments(walkInDetails['requiredDocuments']),
        ],
      ],
    );
  }

  Widget _buildInterviewSlots(List<dynamic>? slots) {
    if (slots == null || slots.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No interview slots specified'),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: slots.length,
        itemBuilder: (context, index) {
          final slot = slots[index];
          final date = (slot['date'] as Timestamp).toDate();
          final startTime = TimeOfDay(
            hour: slot['startTime']['hour'],
            minute: slot['startTime']['minute'],
          );
          final endTime = TimeOfDay(
            hour: slot['endTime']['hour'],
            minute: slot['endTime']['minute'],
          );

          return Column(
            children: [
              if (index > 0) const Divider(height: 1),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      DateFormat('dd').format(date),
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(date),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(
                  '${startTime.format(context)} - ${endTime.format(context)}',
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRequiredDocuments(List<dynamic>? documents) {
    if (documents == null || documents.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No documents specified'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: documents.map((doc) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 20,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(doc.toString()),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

}