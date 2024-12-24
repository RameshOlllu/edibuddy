import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';

import 'location_search_sheet.dart';


class LocationDetailsScreen extends ConsumerStatefulWidget {
  final String userId;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const LocationDetailsScreen({
    Key? key,
    required this.userId,
    required this.onNext,
    required this.onPrevious,
  }) : super(key: key);

  @override
  ConsumerState<LocationDetailsScreen> createState() => _LocationDetailsScreenState();
}

class _LocationDetailsScreenState extends ConsumerState<LocationDetailsScreen> {
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
    await _fetchData();
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

  Future<void> _showPermissionDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Location Access Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/animations/location-permission.json',
              height: 150,
              repeat: true,
            ),
            const SizedBox(height: 16),
            const Text(
              'This app needs location access to detect your current location.',
              style: TextStyle(fontSize: 16),
            ),
          ],
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

  Future<void> _fetchData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists && userDoc.data()?['locationDetails'] != null) {
        final locationData = userDoc.data()!['locationDetails'];
        setState(() {
          currentLocation = locationData['currentLocation'];
          preferredCities = List<Map<String, dynamic>>.from(
              locationData['preferredCities'] ?? []);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar('Failed to load location details');
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
      _showErrorSnackBar('Unable to detect location');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _showLocationSearch() async {
    if (preferredCities.length >= 3) {
      _showErrorSnackBar('Maximum 3 preferred cities allowed');
      return;
    }

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>  LocationSearchScreen(),
    );

    if (result != null) {
      setState(() {
        preferredCities.add(result);
      });
    }
  }

  Future<void> _saveAndNext() async {
    if (currentLocation == null) {
      _showErrorSnackBar('Please select your current location');
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
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        widget.onNext();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to save location details');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Details'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
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
                      _buildSectionTitle('Preferred Cities'),
                      const SizedBox(height: 8),
                      ...preferredCities.asMap().entries.map(
                            (entry) => _buildLocationCard(
                              entry.value,
                              onDelete: () {
                                setState(() {
                                  preferredCities.removeAt(entry.key);
                                });
                              },
                            ),
                          ),
                      if (preferredCities.isEmpty) _buildEmptyPreferredCities(),
                      if (preferredCities.length < 3)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: FilledButton.icon(
                            onPressed: _showLocationSearch,
                            icon: const Icon(Icons.add_location),
                            label: const Text('Add Preferred City'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                        ),
                      const SizedBox(height: 80), // Space for bottom buttons
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
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
          ),
          if (isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
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
    return Card(
      child: InkWell(
        onTap: _detectCurrentLocation,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.location_searching,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              const Text(
                'Detect Current Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to get your current location',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPreferredCities() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Lottie.asset(
              'assets/animations/empty-location.json',
              height: 120,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Preferred Cities',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Add up to 3 preferred cities',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}