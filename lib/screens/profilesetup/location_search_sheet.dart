import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:lottie/lottie.dart';

class LocationSearchScreen extends StatefulWidget {
  const LocationSearchScreen({Key? key}) : super(key: key);

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _errorMessage = '';

  Future<void> _searchLocations(String query) async {
    debugPrint("Search query: $query"); // Debug log
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
        _errorMessage = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _hasSearched = true;
    });

    try {
      List<Location> locations = [];
      try {
        locations = await locationFromAddress(query);
      } catch (e) {
        debugPrint('First search failed: $e');
        try {
          locations = await locationFromAddress('$query, India');
        } catch (e) {
          debugPrint('Second search failed: $e');
        }
      }

      debugPrint('Locations found: ${locations.length}');
      List<Map<String, String>> suggestions = [];

      for (var location in locations) {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          );

          if (placemarks.isNotEmpty) {
            Placemark place = placemarks.first;
            String cityName = place.locality ?? place.subAdministrativeArea ?? '';

            debugPrint("Processing city: $cityName"); // Debug log
            if (!suggestions.any((s) => s['name'] == cityName)) {
              suggestions.add({
                'name': cityName,
                'description':
                    '${cityName}, ${place.administrativeArea ?? ''}, ${place.postalCode ?? ''}',
                'latitude': location.latitude.toString(),
                'longitude': location.longitude.toString(),
                'region': place.administrativeArea ?? '',
                'pincode': place.postalCode ?? '',
              });
            }
          }
        } catch (e) {
          debugPrint('Error processing location: $e');
        }
      }

      setState(() {
        _searchResults = suggestions;
        _isLoading = false;
        if (suggestions.isEmpty) {
          _errorMessage = 'No locations found for "$query"';
        }
      });
    } catch (e) {
      debugPrint('Error during search: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error searching for locations. Please try again.';
        _searchResults = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Location'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter city name or postal code',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchLocations('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant,
              ),
              onChanged: (value) {
                debugPrint('TextField value changed: $value');
                if (value.length >= 3) {
                  _searchLocations(value);
                } else if (value.isEmpty) {
                  _searchLocations('');
                }
              },
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: _buildSearchResults(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      debugPrint('Search is loading...');
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage.isNotEmpty) {
      debugPrint('Search error: $_errorMessage');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/no-results.json',
              height: 200,
              repeat: true,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (!_hasSearched) {
      debugPrint('No search initiated yet.');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
         
            const SizedBox(height: 16),
            const Text(
              'Search for a city or postal code',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    debugPrint('Building search results...');
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        debugPrint('Displaying result: $result');
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
            title: Text(result['name'] ?? 'Unknown City'),
            subtitle: Text(result['description'] ?? 'Description not available'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              debugPrint('Selected city: $result');
              Navigator.pop(context, {
                'name': result['name'] ?? '',
                'region': result['region'] ?? '',
                'latitude': result['latitude'] != null
                    ? double.tryParse(result['latitude']!) ?? 0.0
                    : 0.0,
                'longitude': result['longitude'] != null
                    ? double.tryParse(result['longitude']!) ?? 0.0
                    : 0.0,
                'pincode': result['pincode'] ?? '',
              });
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
