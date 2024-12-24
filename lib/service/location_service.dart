import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Map<String, dynamic>> fetchUserLocation(String userId) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists && userDoc.data()?['locationDetails'] != null) {
      return Map<String, dynamic>.from(userDoc.data()?['locationDetails'] ?? {});
    }
    return {};
  }

  Future<void> updateUserLocation(
    String userId, {
    required Map<String, dynamic> currentLocation,
    required List<Map<String, dynamic>> preferredCities,
  }) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'locationDetails': {
        'currentLocation': currentLocation,
        'preferredCities': preferredCities,
      },
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>> detectCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    final place = placemarks.first;

    return {
      "name": place.locality ?? '',
      "region": place.administrativeArea ?? '',
      "latitude": position.latitude,
      "longitude": position.longitude,
      "pincode": place.postalCode ?? '',
    };
  }
}
