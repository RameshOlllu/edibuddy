// models/basic_details.dart
class BasicDetails {
  final String fullName;
  final String gender;
  final DateTime dob;
  final String email;

  BasicDetails({
    required this.fullName,
    required this.gender,
    required this.dob,
    required this.email,
  });

  factory BasicDetails.fromJson(Map<String, dynamic> json) {
    return BasicDetails(
      fullName: json['fullName'] ?? '',
      gender: json['gender'] ?? '',
      dob: DateTime.parse(json['dob']),
      email: json['email'] ?? '',
    );
  }
}