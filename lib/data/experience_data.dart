class ExperienceData {
  static const Map<String, List<String>> jobCategories = {
    "Teaching": [
      "Primary School Teacher",
      "Secondary School Teacher",
      "High School Teacher",
      "Special Education Teacher",
      "ESL Teacher",
      "Mathematics Teacher",
      "Science Teacher",
      "Language Teacher",
      "Physical Education Teacher",
      "Art Teacher",
      "Music Teacher",
      "Computer Science Teacher",
      "Principal",
      "Vice Principal",
      "Department Head",
      "Academic Coordinator",
      "Educational Consultant",
    ],
    "Administration": [
      "School Administrator",
      "Administrative Assistant",
      "Office Manager",
      "Education Program Coordinator",
      "Student Affairs Coordinator",
      "Admissions Officer",
    ],
    "Support Staff": [
      "School Counselor",
      "Educational Psychologist",
      "Library Assistant",
      "Lab Assistant",
      "Teaching Assistant",
      "Student Support Specialist",
    ],
  };

  static const List<String> companies = [
    "Delhi Public School",
    "Kendriya Vidyalaya",
    "Ryan International School",
    "DAV Public School",
    "Army Public School",
    "Navodaya Vidyalaya",
    "Modern School",
    "The Heritage School",
    "Sanskriti School",
    "Amity International School",
    "Cambridge International School",
    "Seth M.R. Jaipuria School",
    "City Montessori School",
    "Bharatiya Vidya Bhavan",
    "Lotus Valley International School",
  ];

  static const List<String> cities = [
    "Mumbai",
    "Delhi",
    "Bangalore",
    "Hyderabad",
    "Chennai",
    "Kolkata",
    "Pune",
    "Ahmedabad",
    "Jaipur",
    "Lucknow",
    "Chandigarh",
    "Bhopal",
    "Indore",
    "Nagpur",
    "Kochi",
  ];

  static List<String> getAllJobTitles() {
    return jobCategories.values.expand((titles) => titles).toList()..sort();
  }

  static String? getCategoryForJob(String jobTitle) {
    for (var entry in jobCategories.entries) {
      if (entry.value.contains(jobTitle)) {
        return entry.key;
      }
    }
    return null;
  }
}