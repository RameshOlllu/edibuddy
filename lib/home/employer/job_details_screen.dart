import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class JobDetailsScreen extends StatefulWidget {
  final String jobId;

  const JobDetailsScreen({Key? key, required this.jobId}) : super(key: key);

  @override
  _JobDetailsScreenState createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
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
      final doc = await FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.jobId)
          .get();

      if (doc.exists) {
        setState(() {
          _jobData = doc.data();
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching job data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit screen
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'pause',
                child: Text('Pause Listing'),
              ),
              const PopupMenuItem(
                value: 'close',
                child: Text('Close Job'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildJobHeader(theme),
            _buildJobStats(theme),
            _buildJobDetails(theme),
            _buildCandidateSection(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildJobHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _jobData?['jobTitle'] ?? 'Job Title',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _jobData?['companyDescription'] ?? 'Company Description',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.location_on_outlined, 
                  color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                _jobData?['jobLocation'] ?? 'Location',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJobStats(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(
            theme,
            'Total Views',
            '853',
            Icons.visibility_outlined,
          ),
          _buildStatCard(
            theme,
            'Applications',
            '12',
            Icons.people_outline,
          ),
          _buildStatCard(
            theme,
            'Shortlisted',
            '5',
            Icons.person_search_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobDetails(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Job Details',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Job Type', _jobData?['jobType'] ?? 'Not specified'),
            _buildDetailRow('Positions', 
                _jobData?['positions']?.toString() ?? 'Not specified'),
            _buildDetailRow(
              'Salary Range',
              '${_jobData?['minSalary'] != null ? currencyFormatter.format(_jobData?['minSalary']) : 'Not specified'} - ${_jobData?['maxSalary'] != null ? currencyFormatter.format(_jobData?['maxSalary']) : 'Not specified'}',
            ),
            const SizedBox(height: 16),
            Text(
              'Required Skills',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (_jobData?['requiredSkills'] as List?)
                      ?.map((skill) => Chip(label: Text(skill.toString())))
                      .toList() ??
                  [],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildCandidateSection(ThemeData theme) {
    // Hardcoded candidate data
    final candidates = [
      {
        'name': 'John Doe',
        'experience': '5 years',
        'status': 'Shortlisted',
        'appliedDate': '2024-01-03',
      },
      {
        'name': 'Jane Smith',
        'experience': '3 years',
        'status': 'Under Review',
        'appliedDate': '2024-01-04',
      },
      {
        'name': 'Mike Johnson',
        'experience': '4 years',
        'status': 'New',
        'appliedDate': '2024-01-05',
      },
    ];

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Applications',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to all applications
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: candidates.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final candidate = candidates[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(candidate['name']![0]),
                ),
                title: Text(candidate['name']!),
                subtitle: Text('${candidate['experience']} experience'),
                trailing: _buildStatusChip(candidate['status']!, theme),
                onTap: () {
                  // Navigate to candidate details
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, ThemeData theme) {
    Color color;
    switch (status.toLowerCase()) {
      case 'shortlisted':
        color = Colors.green;
        break;
      case 'under review':
        color = Colors.orange;
        break;
      default:
        color = Colors.blue;
    }

    return Chip(
      label: Text(
        status,
        style: TextStyle(
          color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
          fontSize: 12,
        ),
      ),
      backgroundColor: color.withOpacity(0.2),
    );
  }
}