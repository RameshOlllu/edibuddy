import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../model/location_model.dart';
import '../screens/applyjob/applied_jobs_page.dart';
import '../screens/profilesetup/splash_screen_with_tabs.dart';
import '../widgets/job_card_for_recent_jobs.dart';
import '../widgets/location_selector.dart';
import 'career_advice_page.dart';
import 'job_search_page.dart';
import 'recently_viewed_jobs.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isSearchBarPinned = false;
  LocationModel? _selectedLocation;
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 100 && !_isSearchBarPinned) {
      setState(() => _isSearchBarPinned = true);
    } else if (_scrollController.offset <= 100 && _isSearchBarPinned) {
      setState(() => _isSearchBarPinned = false);
    }
  }

  void _updateLocation(LocationModel? location) {
    if (location != null) {
      setState(() {
        _selectedLocation = location;
      });

      debugPrint(
          "Selected Location Updated in HomeScreen: $_selectedLocation"); // ✅ Debugging
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          // Ensure content respects system status bar
          SafeArea(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeSection(theme),
                     // _buildLocationSection(theme),
                  //    if (!_isSearchBarPinned) _buildSearchBar(theme),
                   //   _buildFiltersSection(theme),
                      _buildQuickActions(theme),
                      _buildDepartments(theme),
                      _buildRecentJobsSection(theme),
                      _buildRecentlyViewedJobsSection(theme),
                      // _buildFeaturedJobs(theme),
                      //  _buildRecentJobListings(theme),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Custom AppBar when search bar is pinned
          if (_isSearchBarPinned)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top), // Add top padding
                color: theme.colorScheme.surface,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Center(
                          child: Image.asset(
                            'assets/icons/edibuddylogo.png',
                            width: 120, // Adjust width as needed
                            height: 50, // Adjust height as needed
                            fit: BoxFit
                                .contain, // Ensures the image fits properly
                          ),
                        ),

                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.center,
                        //   children: [
                        //     // Logo circle with 'e'
                        //     Container(
                        //       width: 40,
                        //       height: 40,
                        //       decoration: BoxDecoration(
                        //         gradient: LinearGradient(
                        //           begin: Alignment.topLeft,
                        //           end: Alignment.bottomRight,
                        //           colors: [
                        //             Color(0xFFFF6B9B), // Pink
                        //             Color(0xFF6E40C9), // Purple
                        //           ],
                        //         ),
                        //         shape: BoxShape.circle,
                        //       ),
                        //       child: Stack(
                        //         children: [
                        //           // Dots decoration
                        //           Positioned(
                        //             top: 2,
                        //             right: 2,
                        //             child: Container(
                        //               width: 6,
                        //               height: 6,
                        //               decoration: BoxDecoration(
                        //                 color: Colors.white.withOpacity(0.7),
                        //                 shape: BoxShape.circle,
                        //               ),
                        //             ),
                        //           ),
                        //           Center(
                        //             child: Text(
                        //               'e',
                        //               style: GoogleFonts.poppins(
                        //                 fontSize: 24,
                        //                 color: Colors.white,
                        //                 fontWeight: FontWeight.w600,
                        //               ),
                        //             ),
                        //           ),
                        //         ],
                        //       ),
                        //     ),
                        //     const SizedBox(width: 8),
                        //     // Main text
                        //     Column(
                        //       crossAxisAlignment: CrossAxisAlignment.start,
                        //       children: [
                        //         Text(
                        //           'dibuddy',
                        //           style: GoogleFonts.poppins(
                        //             fontSize: 24,
                        //             color: theme.colorScheme.primary,
                        //             fontWeight: FontWeight.w600,
                        //             letterSpacing: 0.5,
                        //           ),
                        //         ),
                        //         Text(
                        //           'K10 Academic Services',
                        //           style: GoogleFonts.poppins(
                        //             fontSize: 10,
                        //             color: theme.colorScheme.onBackground.withOpacity(0.7),
                        //             fontWeight: FontWeight.w400,
                        //             letterSpacing: 1.2,
                        //           ),
                        //         ),
                        //       ],
                        //     ),
                        //   ],
                        // ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.notifications_outlined,
                              color: theme.colorScheme.primary),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  //  _buildSearchBar(theme),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

Widget _buildRecentlyViewedJobsSection(ThemeData theme) {
  final userId = FirebaseAuth.instance.currentUser?.uid;

  if (userId == null) {
    return SizedBox.shrink(); // Hide if not logged in
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recently Viewed Jobs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RecentlyViewedJobsPage()),
                );
              },
              child: Text('View All', style: TextStyle(color: theme.colorScheme.primary)),
            ),
          ],
        ),
      ),
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('recentlyViewedJobs')
            .orderBy('viewedAt', descending: true)
            .limit(3) // Show only the last 3 viewed jobs
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading recently viewed jobs'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No recently viewed jobs'));
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var docSnapshot = snapshot.data!.docs[index];
              var jobData = docSnapshot.data() as Map<String, dynamic>;
              jobData['id'] = docSnapshot.id;

              return JobCard(jobData: jobData);
            },
          );
        },
      ),
    ],
  );
}

  Widget _buildRecentJobsSection(ThemeData theme) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trending Jobs For You',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JobSearchPage(
                          defaultLocation: _selectedLocation != null ? _selectedLocation!.city : ""),
                    ),
                  );
                },
                child: Text(
                  'View All',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('jobs')
              .orderBy('updatedAt', descending: true)
              .limit(3)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No recent job postings'));
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var docSnapshot = snapshot.data!.docs[index];
                var jobData = docSnapshot.data() as Map<String, dynamic>;
                jobData['id'] = docSnapshot.id;

                // Extract job details
                return JobCard(jobData: jobData);
              },
            );
          },
        ),
      ],
    );
  }

 
  Widget _buildWelcomeSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 5, bottom: 16, left: 16, right: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Welcome back,',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.notifications_outlined,
                    color: theme.colorScheme.primary),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Find your dream teaching job today!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search for teaching jobs...',
          prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
          suffixIcon: IconButton(
            icon: Icon(Icons.tune, color: theme.colorScheme.primary),
            onPressed: () {},
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: theme.colorScheme.primary),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide:
                BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: theme.colorScheme.primary),
          ),
          filled: true,
          fillColor: theme.colorScheme.surface,
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
            _buildActionButton(theme, Icons.edit_note, 'Update\nProfile', _navigateToProfileTab),
            _buildActionButton(theme, Icons.bookmark, 'Applied\nJobs', _navigateToAppliedJobsPage),
            _buildActionButton(theme, Icons.school, 'Skill\nTests', () {}),
            _buildActionButton(theme, Icons.chat, 'Career\nAdvice', _navigateToCareerAdvice),
          ],
        ),
      ],
    ),
  );
}

void _navigateToCareerAdvice() {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => CareerAdvicePage()),
  );
}

void _navigateToProfileTab() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => SplashScreenWithTabs(initialTabIndex: 3),
    ),
  );
}

void _navigateToAppliedJobsPage() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AppliedJobsPage(),
    ),
  );
}



Widget _buildActionButton(ThemeData theme, IconData icon, String label, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(icon, size: 24, color: theme.colorScheme.primary),
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
    ),
  );
}

  Widget _buildDepartments(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explore teaching departments',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDepartmentCard(theme, Icons.science, 'Science'),
                _buildDepartmentCard(theme, Icons.calculate, 'Mathematics'),
                _buildDepartmentCard(theme, Icons.language, 'Languages'),
                _buildDepartmentCard(
                    theme, Icons.history_edu, 'Social Studies'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentCard(ThemeData theme, IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 100,
      height: 100, // Fixed height
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: theme.colorScheme.primary),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: LocationSelectorWidget(
        onLocationChanged: _updateLocation,
        initialLocation: _selectedLocation, // ✅ Pass the selected location
      ),
    );
  }

  Widget _buildFiltersSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(theme, 'Posted in', Icons.access_time,
                ['Today', 'Last 3 days', 'Last week', 'Last month']),
            _buildFilterChip(theme, 'Distance', Icons.place,
                ['0-5 km', '5-10 km', '10-20 km', '20+ km']),
            _buildFilterChip(theme, 'Salary', Icons.attach_money,
                ['₹0-3 LPA', '₹3-6 LPA', '₹6-10 LPA', '₹10+ LPA']),
            _buildFilterChip(theme, 'Work mode', Icons.work,
                ['On-site', 'Remote', 'Hybrid']),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
      ThemeData theme, String label, IconData icon, List<String> options) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<String>(
        child: Chip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(color: theme.colorScheme.onSurface)),
              const Icon(Icons.arrow_drop_down, size: 16),
            ],
          ),
          backgroundColor: theme.colorScheme.surface,
          side: BorderSide(color: theme.colorScheme.primary),
        ),
        itemBuilder: (context) => options
            .map((option) => PopupMenuItem<String>(
                  value: option,
                  child: Text(option),
                ))
            .toList(),
        onSelected: (String value) {
          // Handle filter selection
        },
      ),
    );
  }

  // Widget _buildFeaturedJobs(ThemeData theme) {
  //   return Padding(
  //     padding: const EdgeInsets.all(16.0),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Text(
  //               'Featured Jobs',
  //               style: theme.textTheme.titleMedium?.copyWith(
  //                 fontWeight: FontWeight.bold,
  //                 color: theme.colorScheme.onSurface,
  //               ),
  //             ),
  //             TextButton(
  //               onPressed: () {},
  //               child: Text('View All',
  //                   style: TextStyle(color: theme.colorScheme.primary)),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 12),
  //         SingleChildScrollView(
  //           scrollDirection: Axis.horizontal,
  //           child: Row(
  //             children: [
  //               _buildFeaturedJobCard(
  //                 theme,
  //                 'Senior Math Teacher',
  //                 'International School',
  //                 'Hyderabad',
  //                 '₹75,000 - ₹95,000',
  //                 'Full Time',
  //                 'Min. 5 years',
  //               ),
  //               _buildFeaturedJobCard(
  //                 theme,
  //                 'Physics Faculty',
  //                 'Delhi Public School',
  //                 'Delhi',
  //                 '₹65,000 - ₹85,000',
  //                 'Full Time',
  //                 'Min. 3 years',
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildFeaturedJobCard(
  //   ThemeData theme,
  //   String title,
  //   String school,
  //   String location,
  //   String salary,
  //   String type,
  //   String experience,
  // ) {
  //   return InkWell(
  //     onTap: () => Navigator.push(
  //       context,
  //       MaterialPageRoute(builder: (context) => JobDetailScreen()),
  //     ),
  //     child: Container(
  //       width: 280,
  //       margin: const EdgeInsets.only(right: 12),
  //       child: Card(
  //         elevation: 2,
  //         shape:
  //             RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //         child: Padding(
  //           padding: const EdgeInsets.all(12),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Row(
  //                 children: [
  //                   CircleAvatar(
  //                     backgroundColor: theme.colorScheme.primaryContainer,
  //                     child: Text(
  //                       school[0],
  //                       style: TextStyle(
  //                         color: theme.colorScheme.primary,
  //                         fontWeight: FontWeight.bold,
  //                       ),
  //                     ),
  //                   ),
  //                   const SizedBox(width: 8),
  //                   Expanded(
  //                     child: Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: [
  //                         Text(
  //                           title,
  //                           style: theme.textTheme.titleSmall?.copyWith(
  //                             fontWeight: FontWeight.bold,
  //                           ),
  //                         ),
  //                         Text(
  //                           school,
  //                           style: theme.textTheme.bodySmall?.copyWith(
  //                             color:
  //                                 theme.colorScheme.onSurface.withOpacity(0.7),
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               const SizedBox(height: 8),
  //               Row(
  //                 children: [
  //                   Icon(Icons.location_on_outlined,
  //                       size: 14, color: theme.colorScheme.secondary),
  //                   const SizedBox(width: 4),
  //                   Text(location, style: theme.textTheme.bodySmall),
  //                   const Spacer(),
  //                   Text(
  //                     salary,
  //                     style: theme.textTheme.bodySmall?.copyWith(
  //                       color: theme.colorScheme.primary,
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               const SizedBox(height: 8),
  //               Row(
  //                 children: [
  //                   _buildJobTag(theme, type),
  //                   const SizedBox(width: 8),
  //                   _buildJobTag(theme, experience),
  //                 ],
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildJobTag(ThemeData theme, String text) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //     decoration: BoxDecoration(
  //       color: theme.colorScheme.surfaceContainerLowest.withOpacity(0.1),
  //       borderRadius: BorderRadius.circular(16),
  //       border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5)),
  //     ),
  //     child: Text(
  //       text,
  //       style: theme.textTheme.bodySmall?.copyWith(
  //         color: theme.colorScheme.primary,
  //         fontWeight: FontWeight.w500,
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildRecentJobListings(ThemeData theme) {
  //   return Padding(
  //     padding: const EdgeInsets.all(16.0),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Text(
  //               'Recent Job Listings',
  //               style: theme.textTheme.titleMedium?.copyWith(
  //                 fontWeight: FontWeight.bold,
  //                 color: theme.colorScheme.onSurface,
  //               ),
  //             ),
  //             TextButton(
  //               onPressed: () {},
  //               child: Text('View All',
  //                   style: TextStyle(color: theme.colorScheme.primary)),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 12),
  //         _buildJobCard(
  //           theme,
  //           'High School Math Teacher',
  //           'Springfield High School',
  //           'Springfield, IL',
  //           '\$50,000 - \$65,000',
  //           'Full Time',
  //           'Min. 2 years',
  //           true,
  //         ),
  //         const SizedBox(height: 12),
  //         _buildJobCard(
  //           theme,
  //           'Elementary School Teacher',
  //           'Sunshine Elementary',
  //           'Miami, FL',
  //           '\$45,000 - \$55,000',
  //           'Full Time',
  //           'Min. 1 year',
  //           false,
  //         ),
  //         const SizedBox(height: 12),
  //         _buildJobCard(
  //           theme,
  //           'ESL Instructor',
  //           'Global Language Center',
  //           'New York, NY',
  //           '\$55,000 - \$70,000',
  //           'Part Time',
  //           'Min. 3 years',
  //           true,
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildJobCard(
  //   ThemeData theme,
  //   String id,
  //   String title,
  //   String school,
  //   String location,
  //   String salary,
  //   String type,
  //   String experience,
  //   bool isUrgent,
  // ) {
  //   return InkWell(
  //     onTap: () => Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => EmployeeJobDetailsPage(jobId: id),
  //       ),
  //     ),
  //     child: Card(
  //       elevation: 2,
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //       child: Padding(
  //         padding: const EdgeInsets.all(12.0),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Row(
  //               children: [
  //                 Expanded(
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       if (isUrgent)
  //                         Container(
  //                           margin: const EdgeInsets.only(bottom: 4),
  //                           padding: const EdgeInsets.symmetric(
  //                               horizontal: 6, vertical: 2),
  //                           decoration: BoxDecoration(
  //                             color: theme.colorScheme.error.withOpacity(0.1),
  //                             borderRadius: BorderRadius.circular(4),
  //                           ),
  //                           child: Row(
  //                             mainAxisSize: MainAxisSize.min,
  //                             children: [
  //                               Icon(Icons.local_fire_department,
  //                                   size: 12, color: theme.colorScheme.error),
  //                               const SizedBox(width: 4),
  //                               Text(
  //                                 'Priority Hiring',
  //                                 style: theme.textTheme.bodySmall?.copyWith(
  //                                   color: theme.colorScheme.error,
  //                                   fontWeight: FontWeight.w500,
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                         ),
  //                       Text(
  //                         title,
  //                         style: theme.textTheme.titleSmall?.copyWith(
  //                           fontWeight: FontWeight.bold,
  //                           color: theme.colorScheme.primary,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //                 IconButton(
  //                   icon: Icon(Icons.bookmark_border,
  //                       color: theme.colorScheme.primary),
  //                   onPressed: () {},
  //                   constraints: BoxConstraints.tightFor(width: 32, height: 32),
  //                   padding: EdgeInsets.zero,
  //                 ),
  //               ],
  //             ),
  //             const SizedBox(height: 4),
  //             Text(
  //               school,
  //               style: theme.textTheme.bodySmall
  //                   ?.copyWith(color: theme.colorScheme.onSurface),
  //             ),
  //             const SizedBox(height: 8),
  //             Row(
  //               children: [
  //                 Icon(Icons.location_on_outlined,
  //                     size: 14, color: theme.colorScheme.secondary),
  //                 const SizedBox(width: 4),
  //                 Text(
  //                   location,
  //                   style: theme.textTheme.bodySmall?.copyWith(
  //                     color: theme.colorScheme.onSurface.withOpacity(0.7),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             const SizedBox(height: 8),
  //             Text(
  //               salary,
  //               style: theme.textTheme.bodySmall?.copyWith(
  //                 fontWeight: FontWeight.bold,
  //                 color: theme.colorScheme.secondary,
  //               ),
  //             ),
  //             const SizedBox(height: 8),
  //             Row(
  //               children: [
  //                 _buildJobTag(theme, type),
  //                 const SizedBox(width: 8),
  //                 _buildJobTag(theme, experience),
  //                 const SizedBox(width: 8),
  //                 _buildJobTag(theme, 'On-site'),
  //               ],
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildLocationSection(ThemeData theme) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 'Jobs near',
  //                 style: theme.textTheme.titleSmall?.copyWith(
  //                   fontWeight: FontWeight.w600,
  //                   color: theme.colorScheme.onSurface,
  //                 ),
  //               ),
  //               const SizedBox(height: 4),
  //               Row(
  //                 children: [
  //                   Icon(Icons.location_on,
  //                       color: theme.colorScheme.primary, size: 18),
  //                   const SizedBox(width: 8),
  //                   Expanded(
  //                     child: Text(
  //                       'Kondapur, Hyderabad',
  //                       style: theme.textTheme.bodyMedium?.copyWith(
  //                         fontWeight: FontWeight.w500,
  //                         color: theme.colorScheme.primary,
  //                       ),
  //                       overflow: TextOverflow.ellipsis,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           ),
  //         ),
  //         TextButton(
  //           onPressed: () {},
  //           child: Text(
  //             'Change',
  //             style: TextStyle(color: theme.colorScheme.secondary),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
