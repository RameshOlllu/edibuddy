import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'applicant_card.dart'; // Add this dependency

class JobManagementScreen extends StatefulWidget {
  final String jobId;

  const JobManagementScreen({Key? key, required this.jobId}) : super(key: key);

  @override
  _JobManagementScreenState createState() => _JobManagementScreenState();
}

class _JobManagementScreenState extends State<JobManagementScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _jobData;
  List<Map<String, dynamic>> _applicants = [];
  final _statusOptions = [
    "Open",
    "Not Accepting Applications",
    "Closed",
    "Inactive",
    "Draft",
  ];

  @override
  void initState() {
    super.initState();
    _loadJobData();
  }

  Future<void> _loadJobData() async {
    try {
      setState(() => _isLoading = true);

      // Fetch job data
      final jobDoc = await FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.jobId)
          .get();

      if (!jobDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job not found')),
        );
        Navigator.pop(context);
        return;
      }

      // Fetch applicants from the job_applications collection
      final applicantsSnapshot = await FirebaseFirestore.instance
          .collection('job_applications')
          .where('jobId', isEqualTo: widget.jobId)
          .get();

      setState(() {
        _jobData = jobDoc.data();
        _applicants = applicantsSnapshot.docs
            .map((doc) => {
                  ...doc.data(),
                  'id': doc.id,
                })
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading job data: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateJobStatus(String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.jobId)
          .update({
        'status': newStatus,
        'updatedAt': Timestamp.now(),
      });

      setState(() {
        if (_jobData != null) {
          _jobData!['status'] = newStatus;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Job status updated to $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Management'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _updateJobStatus,
            itemBuilder: (context) {
              return _statusOptions.map((status) {
                return PopupMenuItem(
                  value: status,
                  child: Text(status),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadJobData,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildJobHeader(),
              _buildStatisticsSection(),
              _buildJobDetailsSection(),
              _buildApplicantsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJobHeader() {
    final status = _jobData?['status'] ?? 'Draft';
    final statusColor = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _jobData?['jobTitle'] ?? 'Untitled Job',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _jobData?['schoolName'] ?? 'School name not available',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            _jobData?['jobLocation'] ?? 'Location not specified',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Posted on ${DateFormat('MMM d, yyyy').format(
              _jobData?['postedAt'] != null
                ? (_jobData!['postedAt'] as Timestamp).toDate()
                : DateTime.now()
            )}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.visibility,
                  title: 'Views',
                  value: _jobData?['views']?.toString() ?? '0',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.people,
                  title: 'Applications',
                  value: _applicants.length.toString(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.work,
                  title: 'Positions',
                  value: _jobData?['positions']?.toString() ?? '0',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildJobDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Job Details',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Job Type', _jobData?['jobType'] ?? 'Not specified'),
          _buildDetailRow(
              'Schedule', _formatList(_jobData?['schedules'] ?? [])),
          _buildDetailRow('Salary Range',
              '${_formatSalary(_jobData?['minSalary'])} - ${_formatSalary(_jobData?['maxSalary'])}'),
          _buildDetailRow('Benefits', _formatList(_jobData?['benefits'] ?? [])),
          if (_jobData?['walkInDetails']?['hasWalkIn'] == true)
            _buildWalkInDetails(),
        ],
      ),
    );
  }

  Widget _buildWalkInDetails() {
    final walkInDetails = _jobData!['walkInDetails'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Walk-in Interview Details',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        _buildDetailRow('Venue', walkInDetails['venue'] ?? 'Not specified'),
        _buildDetailRow(
            'Contact', walkInDetails['contactPerson'] ?? 'Not specified'),
        _buildDetailRow(
            'Phone', walkInDetails['contactNumber'] ?? 'Not specified'),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildApplicantsSection() {
    if (_applicants.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('No applications yet',
                  style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Applicants',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _applicants.length,
            itemBuilder: (context, index) {
              final application = _applicants[index];
              return ApplicantCard(
                application: application,
                onStatusChanged: _loadJobData,
                jobId: widget.jobId, // Refresh data on status update
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatList(List<dynamic> items) {
    if (items.isEmpty) return 'None';
    return items.join(', ');
  }

  String _formatSalary(dynamic salary) {
    if (salary == null) return 'Not specified';
    return NumberFormat.currency(symbol: '\$').format(salary);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.green;
      case 'not accepting applications':
        return Colors.orange;
      case 'closed':
        return Colors.red;
      case 'inactive':
        return Colors.grey;
      case 'draft':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
