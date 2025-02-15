import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../screens/postjob/add_basic_details.dart';
import 'jobs_posted_by_me.dart';




class EmployerHomeScreen extends StatefulWidget {
  const EmployerHomeScreen({Key? key}) : super(key: key);

  @override
  State<EmployerHomeScreen> createState() => _EmployerHomeScreenState();
}

class _EmployerHomeScreenState extends State<EmployerHomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isAppBarPinned = false;
  String? _contactName; // Store contact name

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchContactName(); // Fetch contact name on initialization
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 100 && !_isAppBarPinned) {
      setState(() => _isAppBarPinned = true);
    } else if (_scrollController.offset <= 100 && _isAppBarPinned) {
      setState(() => _isAppBarPinned = false);
    }
  }

  Future<void> _fetchContactName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _contactName = userDoc.data()?['contactName'] ?? 'User';
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching contactName: $e');
      setState(() {
        _contactName = 'User'; // Fallback if fetching fails
      });
    }
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(theme),
                      _buildWelcomeCard(theme), 
                      const JobsPostedByMe(),// Updated Greeting Card
                      _buildPostJobCard(theme),
                      _buildQuickActions(theme),
                      _buildRecentlyPostedJobs(theme),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isAppBarPinned) _buildPinnedHeader(theme),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddJobBasicsScreen()),
            );
          },
        icon: const Icon(Icons.add),
        label: const Text('Post a Job'),
        backgroundColor:
            const Color(0xFFF58D8D), // Matching pink gradient start color
        foregroundColor: Colors.white, // Ensure text and icon are visible
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12), // To match card's rounded corners
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFF58D8D), // Pink gradient color from your website
              Colors.white, // To create a subtle gradient
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              // Illustration or Icon Section
              Expanded(
                flex: 1,
                child: Image.asset(
                  'assets/images/logo.png', // Add an appropriate illustration or icon
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 16),
              // Text Section
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Teacher' ?? 'User',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('EEEE, MMMM d').format(DateTime.now()),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Logo circle with 'e'
          // Container(
          //   width: 40,
          //   height: 40,
          //   decoration: BoxDecoration(
          //     gradient: const LinearGradient(
          //       begin: Alignment.topLeft,
          //       end: Alignment.bottomRight,
          //       colors: [
          //         Color(0xFFFF6B9B), // Pink
          //         Color(0xFF6E40C9), // Purple
          //       ],
          //     ),
          //     shape: BoxShape.circle,
          //   ),
          //   child: Stack(
          //     children: [
          //       Positioned(
          //         top: 2,
          //         right: 2,
          //         child: Container(
          //           width: 6,
          //           height: 6,
          //           decoration: BoxDecoration(
          //             color: Colors.white.withOpacity(0.7),
          //             shape: BoxShape.circle,
          //           ),
          //         ),
          //       ),
          //       Center(
          //         child: Text(
          //           'e',
          //           style: GoogleFonts.poppins(
          //             fontSize: 24,
          //             color: Colors.white,
          //             fontWeight: FontWeight.w600,
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          // const SizedBox(width: 8),
          // Column(
          //   crossAxisAlignment: CrossAxisAlignment.start,
          //   children: [
          //     Text(
          //       'dibuddy',
          //       style: GoogleFonts.poppins(
          //         fontSize: 24,
          //         color: theme.colorScheme.primary,
          //         fontWeight: FontWeight.w600,
          //         letterSpacing: 0.5,
          //       ),
          //     ),
          //     Text(
          //       'Employer Portal',
          //       style: GoogleFonts.poppins(
          //         fontSize: 10,
          //         color: theme.colorScheme.onBackground.withOpacity(0.7),
          //         fontWeight: FontWeight.w400,
          //         letterSpacing: 1.2,
          //       ),
          //     ),
          //   ],
          // ),
         Center(
  child: Image.asset(
    'assets/icons/edibuddylogo.png',
    width: 120, // Adjust width as needed
    height: 50, // Adjust height as needed
    fit: BoxFit.contain, // Ensures the image fits properly
  ),
),

          const Spacer(),
          IconButton(
            icon: Icon(Icons.notifications_outlined,
                color: theme.colorScheme.primary),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildPostJobCard(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap:  () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddJobBasicsScreen()),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ready to hire?',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Post a job and find the perfect candidate',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.add_circle_outline,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                theme,
                Icons.description_outlined,
                'Active\nJobs',
                '5',
              ),
              _buildActionButton(
                theme,
                Icons.people_outline,
                'Total\nApplications',
                '28',
              ),
              _buildActionButton(
                theme,
                Icons.person_search_outlined,
                'Candidate\nSearch',
              ),
              _buildActionButton(
                theme,
                Icons.analytics_outlined,
                'Job\nAnalytics',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(ThemeData theme, IconData icon, String label,
      [String? badge]) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(icon, size: 24, color: theme.colorScheme.primary),
            ),
            if (badge != null)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badge,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentlyPostedJobs(ThemeData theme) {
    // Only show if there are posted jobs
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recently Posted Jobs',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'View All',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildJobCard(
            theme,
            'Mathematics Teacher',
            'Posted 2 days ago',
            '12 applications',
            '853 views',
          ),
          const SizedBox(height: 12),
          _buildJobCard(
            theme,
            'Physics Faculty',
            'Posted 5 days ago',
            '8 applications',
            '621 views',
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(
    ThemeData theme,
    String title,
    String postedTime,
    String applications,
    String views,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                PopupMenuButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: theme.colorScheme.primary,
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit Job'),
                    ),
                    const PopupMenuItem(
                      value: 'pause',
                      child: Text('Pause Listing'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              postedTime,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildJobStat(
                  theme,
                  Icons.people_outline,
                  applications,
                  theme.colorScheme.primary,
                ),
                const SizedBox(width: 16),
                _buildJobStat(
                  theme,
                  Icons.visibility_outlined,
                  views,
                  theme.colorScheme.secondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobStat(
    ThemeData theme,
    IconData icon,
    String text,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPinnedHeader(ThemeData theme) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _buildHeader(theme),
      ),
    );
  }
}
