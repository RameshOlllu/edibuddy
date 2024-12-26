// models/education_details.dart
class EducationDetails {
  final String collegeName;
  final String completionYear;
  final bool isPursuing;
  final String degree;
  final String specialization;
  final String highestEducationLevel;
  final String schoolMedium;

  EducationDetails({
    required this.collegeName,
    required this.completionYear,
    required this.isPursuing,
    required this.degree,
    required this.specialization,
    required this.highestEducationLevel,
    required this.schoolMedium,
  });

  factory EducationDetails.fromJson(Map<String, dynamic> json) {
    return EducationDetails(
      collegeName: json['collegeName'] ?? '',
      completionYear: json['completionYear'] ?? '',
      isPursuing: json['isPursuing'] ?? false,
      degree: json['degree'] ?? '',
      specialization: json['specialization'] ?? '',
      highestEducationLevel: json['highestEducationLevel'] ?? '',
      schoolMedium: json['schoolMedium'] ?? '',
    );
  }
}