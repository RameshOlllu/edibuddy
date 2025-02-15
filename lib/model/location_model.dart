class LocationModel {
  final String city;
  final String state;
  final int pincode;
  final String area; // New field for localities/neighborhoods
  final double? latitude; // Optional latitude
  final double? longitude; // Optional longitude

  LocationModel({
    required this.city,
    required this.state,
    required this.pincode,
    this.area = '', // Default to empty string if not provided
    this.latitude,
    this.longitude,
  });

  /// Factory constructor to create a LocationModel from JSON
  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      city: json['city'] ?? 'Unknown City',
      state: json['state'] ?? 'Unknown State',
      pincode: json['pincode'] ?? 0,
      area: json['area'] ?? '', // Handle missing area gracefully
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
    );
  }

  /// Converts the LocationModel to JSON format
  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'state': state,
      'pincode': pincode,
      'area': area,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  /// Checks if latitude and longitude are available
  bool hasCoordinates() {
    return latitude != null && longitude != null;
  }

  @override
  String toString() {
    String locationString = area.isNotEmpty ? '$area, $city' : city;
    return hasCoordinates()
        ? '$locationString, $state - $pincode (Lat: $latitude, Long: $longitude)'
        : '$locationString, $state - $pincode';
  }
}
