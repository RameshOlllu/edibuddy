import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shimmer/shimmer.dart';

import 'location_search_sheet.dart';

class LocationDetailsScreen extends StatefulWidget {
  final String userId;
  final void Function(bool isEarned) onNext;
  final VoidCallback onPrevious;

  const LocationDetailsScreen({
    Key? key,
    required this.userId,
    required this.onNext,
    required this.onPrevious,
  }) : super(key: key);

  @override
  State<LocationDetailsScreen> createState() => _LocationDetailsScreenState();
}

class _LocationDetailsScreenState extends State<LocationDetailsScreen> {
  Map<String, dynamic>? currentLocation;
  List<Map<String, dynamic>> preferredCities = [];
  bool isLoading = true;
  bool locationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _checkPermissions();
    _fetchData();
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.location.request();
    setState(() {
      locationPermissionGranted = status.isGranted;
    });
    if (!locationPermissionGranted) {
      _showPermissionDialog();
    }
  }

Future<void> _fetchData() async {
  try {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();

    if (userDoc.exists && userDoc.data()?['locationDetails'] != null) {
      final locationData = userDoc.data()!['locationDetails'];
      if (mounted) {
        setState(() {
          currentLocation = locationData['currentLocation'];
          preferredCities = List<Map<String, dynamic>>.from(
              locationData['preferredCities'] ?? []);
        });
      }
    }
  } catch (e) {
    if (mounted) {
      _showErrorSnackBar('Failed to load location details.');
    }
  } finally {
    if (mounted) {
      setState(() => isLoading = false);
    }
  }
}


  

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _detectCurrentLocation() async {
    if (!locationPermissionGranted) {
      _showPermissionDialog();
      return;
    }

    setState(() => isLoading = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          currentLocation = {
            "name": place.locality ?? '',
            "region": place.administrativeArea ?? '',
            "latitude": position.latitude,
            "longitude": position.longitude,
            "pincode": place.postalCode ?? '',
          };
        });
      }
    } catch (e) {
      _showErrorSnackBar('Unable to detect location.');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _showLocationSearch() async {
    if (preferredCities.length >= 3) {
      _showErrorSnackBar('Maximum 3 preferred cities allowed.');
      return;
    }

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LocationSearchScreen(),
    );

    if (result != null) {
      setState(() => preferredCities.add(result));
    }
  }

  Future<void> _saveAndNext() async {
    if (currentLocation == null) {
      _showErrorSnackBar('Please select your current location.');
      return;
    }

    setState(() => isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'locationDetails': {
          'currentLocation': currentLocation,
          'preferredCities': preferredCities,
        },
          'badges.locationdetails': {
          'earned': true,
          'earnedAt': FieldValue.serverTimestamp(),
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        widget.onNext(preferredCities.isNotEmpty);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to save location details.');
    } finally {
      setState(() => isLoading = false);
    }
  }

 void _showPermissionDialog() {
  final theme = Theme.of(context);
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.location_on, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded( // Ensure text does not overflow
            child: Text(
              'Location Access Required',
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis, // Add ellipsis if text overflows
            ),
          ),
        ],
      ),
      content: const Text(
        'This app needs location access to detect your current location for job suggestions and recruiter recommendations.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () async {
            Navigator.pop(context);
            await openAppSettings();
          },
          icon: const Icon(Icons.settings),
          label: const Text('Open Settings'),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
   
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildBannerInfo(),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Current Location'),
                          const SizedBox(height: 8),
                          if (isLoading)
                            _buildShimmerLoading()
                          else if (currentLocation != null)
                            _buildLocationCard(
                              currentLocation!,
                              onAction: _detectCurrentLocation,
                              actionIcon: Icons.refresh,
                            )
                          else
                            _buildEmptyLocationCard(),
                          const SizedBox(height: 24),
                          _buildPreferredCities(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          _buildBottomNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildBannerInfo() {
    return 
    
      Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Icon(
                        Icons.info_outline,
                        size: 36,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Locaiton Inforamtion",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Your location helps recruiters find you for better job suggestions and recommendations.",
                            style: TextStyle(fontSize: 14, color: Colors.black54),
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

Widget _buildPreferredCities() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionTitle('Preferred Cities'),
      const SizedBox(height: 8),
      if (preferredCities.isEmpty)
        _buildEmptyPreferredCities()
      else
        Padding(
          padding: EdgeInsets.only(bottom: (preferredCities.length==3?60:1),),
          child: Column(
            children: preferredCities.map((city) {
              return _buildLocationCard(city, onDelete: () {
                setState(() => preferredCities.remove(city));
              });
            }).toList(),
          ),
        ),
      if (preferredCities.length < 3)
        Padding(
          padding: const EdgeInsets.only(bottom: 16,top: 20), // Avoid overlap with navigation bar
          child: SafeArea(
            child: FilledButton.icon(
              onPressed: _showLocationSearch,
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Add Preferred City'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        ),
          if (preferredCities.length < 3)
          SizedBox(height: 60,),
    ],
  );
}

Widget _buildEmptyPreferredCities() {
  return Center(
    child: Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off,
              size: 30,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Preferred Cities',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add up to 3 preferred cities.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}


  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationCard(
    Map<String, dynamic> location, {
    VoidCallback? onAction,
    VoidCallback? onDelete,
    IconData actionIcon = Icons.delete,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.location_city,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          location['name'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${location['region']} - ${location['pincode']}',
        ),
        trailing: IconButton(
          icon: Icon(actionIcon),
          onPressed: onAction ?? onDelete,
          color: onDelete != null ? Colors.red : null,
        ),
      ),
    );
  }

Widget _buildEmptyLocationCard() {
  return Center(
    child: Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: _detectCurrentLocation,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_searching,
                size: 30,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ),
              const SizedBox(height: 16),
              const Text(
                'Detect Current Location',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the button to fetch your current location and improve your job recommendations.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildBottomNavigationBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
          top: 16,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onPrevious,
                child: const Text('Previous'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton(
                onPressed: isLoading ? null : _saveAndNext,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
