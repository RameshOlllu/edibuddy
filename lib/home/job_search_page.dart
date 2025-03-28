import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../model/location_model.dart';
import '../service/location_service.dart';
import '../widgets/job_card_for_recent_jobs.dart';
import '../widgets/location_search_screen.dart';
import '../widgets/location_selector.dart';
import 'employee_job_details_page.dart';

class JobSearchPage extends StatefulWidget {
  final String? defaultLocation; // new parameter for default city

  const JobSearchPage({Key? key, this.defaultLocation}) : super(key: key);

  @override
  _JobSearchPageState createState() => _JobSearchPageState();
}

class _JobSearchPageState extends State<JobSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<DocumentSnapshot> _jobs = [];
  bool _isLoading = false;

  // Filter states
  String? _selectedLocation;
  String? _selectedJobType;
  String? _selectedDatePosted;

  @override
  void initState() {
    super.initState();
    if (widget.defaultLocation != null && widget.defaultLocation!.isNotEmpty) {
      _selectedLocation = widget.defaultLocation; // Use passed-in city string
    } else {
      _loadCurrentLocation();
    }
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    setState(() => _isLoading = true);

    try {
      Query query = FirebaseFirestore.instance.collection('jobs');

      if (_searchQuery.isNotEmpty) {
        query = query
            .where('jobTitle', isGreaterThanOrEqualTo: _searchQuery)
            .where('jobTitle', isLessThan: '${_searchQuery}z');
      }

      // If a location is selected, filter by that location
      if (_selectedLocation != null && _selectedLocation!.isNotEmpty) {
        // Assuming your job document stores the city in either locationDetails.city or jobLocation.
        // Here, we check the 'locationDetails.city'. Adjust if needed.
        query = query.where('locationDetails.city',
            isEqualTo: _selectedLocation!.toUpperCase());
      }

      if (_selectedJobType != null) {
        query = query.where('jobType', isEqualTo: _selectedJobType);
      }

      if (_selectedDatePosted != null) {
        DateTime filterDate = DateTime.now()
            .subtract(Duration(days: int.parse(_selectedDatePosted!)));
        query = query.where('postedAt', isGreaterThanOrEqualTo: filterDate);
      }

      // Order by postedAt descending and limit to 10 jobs
      query = query.orderBy('postedAt', descending: true).limit(10);

      QuerySnapshot querySnapshot = await query.get();

      print('selected Location is $_selectedLocation');

      // If no jobs found and location filter is active and not "Remote", try fallback to "Remote" jobs
      if (querySnapshot.docs.isEmpty &&
          _selectedLocation != null &&
          _selectedLocation!.toLowerCase() != 'remote') {
        query = FirebaseFirestore.instance
            .collection('jobs')
            .where('jobLocation', isEqualTo: 'Remote')
            .orderBy('postedAt', descending: true)
            .limit(10);
        querySnapshot = await query.get();
      }

      setState(() {
        _jobs = querySnapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching jobs: $e');
      setState(() => _isLoading = false);
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search for teaching jobs...',
          prefixIcon: Icon(Icons.search),
          suffixIcon: IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
              _fetchJobs();
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
          _fetchJobs();
        },
      ),
    );
  }

Widget _buildFilterChips() {
  final filtersActive = _selectedLocation != null ||
      _selectedJobType != null ||
      _selectedDatePosted != null;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 8.0),
    child: Wrap(
      spacing: 2.0,
      runSpacing: 1.0,
      crossAxisAlignment: WrapCrossAlignment.center, // Align items properly
      children: [
        // Clear All Filters Icon - Only if filters are active
        if (filtersActive)
          IconButton(
            icon: Icon(Icons.clear_all, color: Theme.of(context).colorScheme.primary),
            onPressed: () {
              setState(() {
                _selectedJobType = null;
                _selectedDatePosted = null;
                _selectedLocation = ""; // Clear location filter
              });
              _fetchJobs();
            },
          ),

        // Location Filter Chip
        ChoiceChip(
          label: const Text('Location'),
          selected: _selectedLocation != null && _selectedLocation!.isNotEmpty,
          onSelected: (selected) {
            _showFilterDialog('Location', ['Remote', 'On-site', 'Hybrid'], (value) {
              setState(() {
                if (_selectedLocation == value) {
                  _selectedLocation = null;
                } else {
                  _selectedLocation = value;
                }
              });
              _fetchJobs();
            });
          },
        ),

        // Job Type Filter Chip
        ChoiceChip(
          label: const Text('Job Type'),
          selected: _selectedJobType != null,
          onSelected: (selected) {
            _showFilterDialog('Job Type', ['Full-time', 'Part-time', 'Contract'], (value) {
              setState(() {
                if (_selectedJobType == value) {
                  _selectedJobType = null;
                } else {
                  _selectedJobType = value;
                }
              });
              _fetchJobs();
            });
          },
        ),

        // Date Posted Filter Chip
        ChoiceChip(
          label: const Text('Date Posted'),
          selected: _selectedDatePosted != null,
          onSelected: (selected) {
            _showFilterDialog('Date Posted', ['1', '7', '30'], (value) {
              setState(() {
                if (_selectedDatePosted == value) {
                  _selectedDatePosted = null;
                } else {
                  _selectedDatePosted = value;
                }
              });
              _fetchJobs();
            });
          },
        ),
      ],
    ),
  );
}

  void _showFilterDialog(
      String title, List<String> options, Function(String) onSelected) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: options
                  .map((option) => ListTile(
                        title: Text(option),
                        onTap: () {
                          onSelected(option);
                          Navigator.of(context).pop();
                        },
                      ))
                  .toList(),
            ),
          ),
        );
      },
    );
  }

Widget _buildJobList() {
  if (_isLoading) {
    return Center(child: CircularProgressIndicator());
  }

  if (_jobs.isEmpty) {
    return Center(child: Text('No jobs found'));
  }

  return ListView.builder(
    itemCount: _jobs.length,
    itemBuilder: (context, index) {
      final jobSnapshot = _jobs[index];
      final job = jobSnapshot.data() as Map<String, dynamic>;

      // Add job ID to the jobData map
      job['id'] = jobSnapshot.id;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: JobCard(jobData: job), // Use the JobCard widget
      );
    },
  );
}

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Date not available';
    return DateFormat('MMM d, yyyy').format(timestamp.toDate());
  }
Widget _buildLocationHeader() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    child: Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        child: Row(
          children: [
            Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: (_selectedLocation != null && _selectedLocation!.isNotEmpty)
                  ? Text(
                      _selectedLocation!,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    )
                  : Text(
                      "All Locations",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
                    ),
            ),
            TextButton(
              onPressed: () async {
                // Directly push a full-screen location selector.
                LocationModel? newLocation = await Navigator.push<LocationModel>(
                  context,
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (context) => LocationSearchScreen(),
                  ),
                );
                if (newLocation != null) {
                  setState(() {
                    _selectedLocation = newLocation.city;
                  });
                  _fetchJobs(); // Refresh jobs after location change
                }
              },
              child: Text('Change', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            ),
          ],
        ),
      ),
    ),
  );
}

  void _loadCurrentLocation() async {
    if (_selectedLocation != null && _selectedLocation!.isNotEmpty)
      return; // already set
    try {
      final locationData = await LocationService().detectCurrentLocation();
      if (locationData.isNotEmpty &&
          locationData["city"] != null &&
          locationData["city"].toString().isNotEmpty) {
        setState(() {
          _selectedLocation = locationData["city"];
        });
      } else {
        setState(() {
          _selectedLocation = "Remote"; // fallback if detection fails
        });
      }
    } catch (e) {
      print("Error loading current location: $e");
      setState(() {
        _selectedLocation = "Remote";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Job Search'),
      ),
      body: Column(
        children: [
          _buildLocationHeader(),
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(child: _buildJobList()),
        ],
      ),
    );
  }
}
