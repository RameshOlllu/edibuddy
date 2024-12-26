import 'package:flutter/material.dart';

class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen({Key? key}) : super(key: key);

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isDescriptionExpanded = false;
  bool _isRequirementsExpanded = false;

  @override
  void initState() {
    super.initState();
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: theme.colorScheme.primary),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurface),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.7),
            indicatorColor: theme.colorScheme.primary,
            tabs: const [
              Tab(text: 'Job details'),
              Tab(text: 'Walk-in details'),
              Tab(text: 'About company'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildJobDetailsTab(theme),
                _buildWalkInDetailsTab(theme),
                _buildAboutCompanyTab(theme),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Read walk-in details before you register',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Register for walk-in'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobDetailsTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHighlightsCard(theme),
          const SizedBox(height: 16),
          _buildDescriptionSection(theme),
          const SizedBox(height: 16),
          _buildJobRoleSection(theme),
          const SizedBox(height: 16),
          _buildRequirementsSection(theme),
        ],
      ),
    );
  }

  Widget _buildHighlightsCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Job highlights',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.directions_walk, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Walk-in interview',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date: 04 Dec 2024 - 13 Dec 2024',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Time: 10.00 am - 04.00 pm',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'See details',
                          style: TextStyle(color: theme.colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle_outline,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Benefits include: PF, ESI (ESIC)',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Job description',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Teach children basic skills such as identifying colors, shapes, '
          'numbers, Strokes and letters. Work with children in groups or one on '
          'one, depending on the needs of children and on the subject matter...',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          maxLines: _isDescriptionExpanded ? null : 3,
          overflow: _isDescriptionExpanded ? null : TextOverflow.ellipsis,
        ),
        TextButton(
          onPressed: () =>
              setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
          child: Text(
            _isDescriptionExpanded ? 'Show less' : 'Show more',
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildJobRoleSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Job role',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          theme,
          Icons.location_city,
          'Work location',
          'Sriram Nagar Colony, Kondapur, Telangana, India',
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          theme,
          Icons.work_outline,
          'Department',
          'Teaching & Training',
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          theme,
          Icons.category_outlined,
          'Role / Category',
          'Preschool & Primary Education',
        ),
      ],
    );
  }

  Widget _buildRequirementsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Job requirements',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          theme,
          Icons.work_history_outlined,
          'Experience',
          'Any experience',
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          theme,
          Icons.school_outlined,
          'Education',
          'Graduate',
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          theme,
          Icons.category_outlined,
          'Past role/category experience',
          'Preschool & Primary Education, Teacher / Faculty / Tutor',
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          theme,
          Icons.language_outlined,
          'English level',
          'Basic English',
        ),
      ],
    );
  }

  Widget _buildWalkInDetailsTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Walk-in interview details',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Apply for the job and call HR to confirm your interview',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            theme,
            Icons.calendar_today_outlined,
            'Date',
            '04 Dec 2024 - 13 Dec 2024',
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            theme,
            Icons.access_time,
            'Time',
            '10.00 am - 04.00 pm',
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCompanyTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Text(
                  'G',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Launchpad School',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Educational Institution',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoRow(
            theme,
            Icons.location_on_outlined,
            'Address',
            'Sriram Nagar Colony, Kondapur, Telangana, India',
          ),
          const SizedBox(height: 24),
          Text(
            'Job posted by',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Launchpad Global School',
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      ThemeData theme, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onSurface.withOpacity(0.7),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
