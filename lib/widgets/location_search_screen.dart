import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../model/location_model.dart';

class LocationSearchScreen extends StatefulWidget {
  @override
  _LocationSearchScreenState createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<LocationModel> _allLocations = [];
  List<LocationModel> _filteredLocations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  /// Load location data from assets
  Future<void> _loadLocations() async {
    try {
      final String response =
          await rootBundle.loadString('assets/data/india_locations.json');
      final data = json.decode(response);

      _allLocations = (data as List)
          .map((item) => LocationModel.fromJson(item))
          .toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading locations: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Filters locations based on user input
  void _filterLocations(String query) {
    setState(() {
      _filteredLocations = _allLocations
          .where((location) =>
              location.city.toLowerCase().contains(query.toLowerCase()) ||
              location.state.toLowerCase().contains(query.toLowerCase()) ||
              location.pincode.toString().contains(query))
          .take(10)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Location"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search city, state, or pincode',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _filterLocations,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredLocations.isEmpty
                      ? const Center(child: Text("No results found"))
                      : ListView.builder(
                          itemCount: _filteredLocations.length,
                          itemBuilder: (context, index) {
                            final location = _filteredLocations[index];
                            return ListTile(
                              leading: const Icon(Icons.location_on_outlined),
                              title: Text(location.city),
                              subtitle: Text('${location.state} - ${location.pincode}'),
                              onTap: () {
                                Navigator.pop(context, location);
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
