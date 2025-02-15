import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../model/location_model.dart';

class LocationSearchWidget extends StatefulWidget {
  final Function(LocationModel) onLocationSelected;
  final LocationModel? initialLocation;

  const LocationSearchWidget({
    Key? key,
    required this.onLocationSelected,
    this.initialLocation,
  }) : super(key: key);

  @override
  _LocationSearchWidgetState createState() => _LocationSearchWidgetState();
}

class _LocationSearchWidgetState extends State<LocationSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<LocationModel> _allLocations = [];
  List<LocationModel> _filteredLocations = [];
  bool _isLoading = true;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _loadLocations();
    _focusNode.addListener(() {
      setState(() {
        _showSuggestions = _focusNode.hasFocus;
      });
    });
  }

  Future<void> _loadLocations() async {
    try {
      // Load the JSON file from assets
      final String response = 
          await rootBundle.loadString('assets/data/india_locations.json');
      final data = await json.decode(response);
      
      _allLocations = (data as List)
          .map((item) => LocationModel.fromJson(item))
          .toList();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading locations: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterLocations(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredLocations = [];
      });
      return;
    }

    setState(() {
      _filteredLocations = _allLocations
          .where((location) {
            final queryLower = query.toLowerCase();
            return location.city.toLowerCase().contains(queryLower) ||
                   location.state.toLowerCase().contains(queryLower) ||
                   location.pincode.toString().contains(query);
          })
          .take(5) // Limit to 5 suggestions
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: 'Search Location',
            hintText: 'Enter city, state or pincode',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _filterLocations('');
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: _filterLocations,
        ),
        if (_showSuggestions && _filteredLocations.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _filteredLocations.length,
              itemBuilder: (context, index) {
                final location = _filteredLocations[index];
                return ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(location.city),
                  subtitle: Text('${location.state} - ${location.pincode}'),
                  onTap: () {
                    widget.onLocationSelected(location);
                    _searchController.text = location.toString();
                    setState(() {
                      _showSuggestions = false;
                      _filteredLocations = [];
                    });
                    _focusNode.unfocus();
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}