import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../model/location_model.dart';
import '../screens/profilesetup/location_search_sheet.dart';

class LocationSelectorWidget extends StatefulWidget {
  final Function(LocationModel?) onLocationChanged;
final LocationModel? initialLocation; 
  const LocationSelectorWidget({
    Key? key,
    required this.onLocationChanged,
    this.initialLocation, // ✅ Accept initial location
  }) : super(key: key);


  @override
  _LocationSelectorWidgetState createState() => _LocationSelectorWidgetState();
}

class _LocationSelectorWidgetState extends State<LocationSelectorWidget> {
  String _currentLocation = "Fetching location...";
  LocationModel? _selectedLocation;

  @override
  void initState() {
    super.initState();
    
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation; // Load initial location
      _currentLocation = _selectedLocation.toString();
    } else {
      _fetchUserLocation();
    }
  }

  @override
  void didUpdateWidget(covariant LocationSelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLocation != oldWidget.initialLocation) {
      setState(() {
        _selectedLocation = widget.initialLocation;
        _currentLocation = widget.initialLocation?.toString() ?? _currentLocation;
      });
    }
  }

  /// Fetches user's current location
  Future<void> _fetchUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _currentLocation = "Location services are disabled.");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _currentLocation = "Location permission denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _currentLocation = "Permission permanently denied.");
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isNotEmpty) {
      Placemark place = placemarks[0];
      setState(() {
        _selectedLocation = LocationModel(
          city: place.locality ?? "",
          state: place.administrativeArea ?? "",
          pincode: int.tryParse(place.postalCode ?? "0") ?? 0,
          area: place.subLocality ?? "", // Ensure area is also included
        );
        _currentLocation = _selectedLocation.toString();
      });

      // Send back to HomeScreen
      widget.onLocationChanged(_selectedLocation);
    }
  }

  /// Opens the location search modal
Future<void> _openLocationSearch(BuildContext context) async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => LocationSearchScreen(),
    ),
  );

  print('inside _openLocationSearch  $result ${(result != null)}');

  if (result != null) {
    LocationModel selectedLocation;

    if (result is Map) {
      selectedLocation = LocationModel(
        city: result['name'] ?? '',
        state: result['region'] ?? '',
        pincode: int.tryParse(result['pincode']?.toString() ?? '0') ?? 0,
        area:  result['description']?? '',
        // latitude: double.tryParse(result['latitude']?.toString() ?? ''),
        // longitude: double.tryParse(result['longitude']?.toString() ?? ''),
      );
    } else if (result is LocationModel) {
      selectedLocation = result;
    } else {
      // Handle unexpected type
      return;
    }

    setState(() {
      _selectedLocation = selectedLocation;
      _currentLocation = selectedLocation.toString();
    });

    debugPrint("Updating Location in LocationSelectorWidget: $_selectedLocation");
    widget.onLocationChanged(selectedLocation);
  }
}

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(Icons.location_on,
                  color: Theme.of(context).colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedLocation?.toString() ?? _currentLocation,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () => _openLocationSearch(context),
          child: Text(
            'Change',
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          ),
        ),
      ],
    );
  }
}
