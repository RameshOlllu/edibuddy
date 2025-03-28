import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Map<String, dynamic>> fetchUserLocation(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists && userDoc.data()?['locationDetails'] != null) {
        return Map<String, dynamic>.from(userDoc.data()?['locationDetails'] ?? {});
      }
    } catch (e) {
      print("Error fetching user location: $e");
    }
    return {};
  }


  Future<void> updateUserLocation(
    String userId, {
    required Map<String, dynamic> currentLocation,
    required List<Map<String, dynamic>> preferredCities,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'locationDetails': {
          'currentLocation': currentLocation,
          'preferredCities': preferredCities,
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error updating user location: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> detectCurrentLocation() async {
    try {
      // Ensure location services are enabled.
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      // Check and request permissions.
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      // Get current position.
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      // Use geocoding to get placemark information.
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      final place = placemarks.first;

      return {
        "name": place.locality ?? '',
        "region": place.administrativeArea ?? '',
        "latitude": position.latitude,
        "longitude": position.longitude,
        "pincode": place.postalCode ?? '',
      };
    } catch (e) {
      print("Error detecting current location: $e");
      return {}; // Return empty map if error occurs.
    }
  }
}
