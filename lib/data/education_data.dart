class EducationData {
  static const Map<String, List<String>> educationLevels = {
    "Graduate": [
      "Bachelor of Education (B.Ed)",
      "Bachelor of Arts (BA)",
      "Bachelor of Science (BSc)",
      "Bachelor of Commerce (BCom)",
      "Bachelor of Technology (BTech)",
      "Bachelor of Business Administration (BBA)",
      "Bachelor of Computer Applications (BCA)",
    ],
    "Postgraduate": [
      "Master of Education (M.Ed)",
      "Master of Arts (MA)",
      "Master of Science (MSc)",
      "Master of Commerce (MCom)",
      "Master of Technology (MTech)",
      "Master of Business Administration (MBA)",
      "Master of Computer Applications (MCA)",
    ],
    "Doctorate": [
      "Doctor of Philosophy (PhD)",
      "Doctor of Education (EdD)",
      "Doctor of Science (DSc)",
    ],
    "Diploma": [
      "Diploma in Education",
      "Diploma in Computer Applications (DCA)",
      "Diploma in Management",
    ],
    "Other": [
      "Certificate in Teaching",
      "Special Education Certification",
      "Professional Certification",
    ],
  };

  static const Map<String, List<String>> specializations = {
    "Bachelor of Education (B.Ed)": [
      "Elementary Education",
      "Secondary Education",
      "Special Education",
      "Physical Education",
      "Early Childhood Education",
    ],
    "Master of Education (M.Ed)": [
      "Educational Leadership",
      "Curriculum and Instruction",
      "Special Education",
      "Educational Technology",
      "Educational Psychology",
    ],
    "Bachelor of Arts (BA)": [
      "English",
      "History",
      "Geography",
      "Political Science",
      "Psychology",
      "Sociology",
      "Philosophy",
      "Journalism and Mass Communication",
    ],
    "Master of Arts (MA)": [
      "English Literature",
      "History",
      "Geography",
      "Political Science",
      "Psychology",
      "Sociology",
      "Philosophy",
      "Journalism and Mass Communication",
    ],
    "Bachelor of Science (BSc)": [
      "Mathematics",
      "Physics",
      "Chemistry",
      "Biology",
      "Computer Science",
      "Statistics",
      "Agriculture",
      "Environmental Science",
    ],
    "Master of Science (MSc)": [
      "Mathematics",
      "Physics",
      "Chemistry",
      "Biology",
      "Computer Science",
      "Statistics",
      "Agriculture",
      "Environmental Science",
    ],
    "Bachelor of Commerce (BCom)": [
      "Accounting",
      "Finance",
      "Business Administration",
      "Economics",
      "Taxation",
      "Marketing",
    ],
    "Master of Commerce (MCom)": [
      "Accounting",
      "Finance",
      "Business Administration",
      "Economics",
      "Taxation",
      "Marketing",
    ],
    "Bachelor of Business Administration (BBA)": [
      "Finance",
      "Marketing",
      "Human Resources",
      "Operations Management",
      "Entrepreneurship",
      "International Business",
    ],
    "Master of Business Administration (MBA)": [
      "Finance",
      "Marketing",
      "Human Resources",
      "Operations Management",
      "Entrepreneurship",
      "International Business",
      "Healthcare Management",
      "Supply Chain Management",
    ],
    "Bachelor of Computer Applications (BCA)": [
      "Software Development",
      "Data Analytics",
      "Web Development",
      "Cybersecurity",
      "Artificial Intelligence",
    ],
    "Master of Computer Applications (MCA)": [
      "Software Development",
      "Data Analytics",
      "Web Development",
      "Cybersecurity",
      "Artificial Intelligence",
    ],
    "Diploma in Education": [
      "Elementary Education",
      "Secondary Education",
      "Special Education",
    ],
    "Diploma in Computer Applications (DCA)": [
      "Software Basics",
      "Programming",
      "Internet Technologies",
    ],
    "Diploma in Management": [
      "Business Management",
      "Operations Management",
      "Organizational Behavior",
    ],
    "Certificate in Teaching": [
      "Early Childhood Education",
      "Online Teaching",
      "Language Teaching",
    ],
    "Special Education Certification": [
      "Learning Disabilities",
      "Autism Spectrum Disorders",
      "Behavioral Management",
    ],
    "Professional Certification": [
      "Project Management",
      "Data Science",
      "Digital Marketing",
      "Software Testing",
    ],
  };

  static const List<String> mediums = [
    "English",
    "Hindi",
    "Bengali",
    "Telugu",
    "Marathi",
    "Tamil",
    "Urdu",
    "Gujarati",
    "Kannada",
    "Malayalam",
    "Punjabi",
    "Odia",
    "Assamese",
  ];

  /// Returns a list of degrees for a given education level. If not found, returns "Other".
  static List<String> getDegrees(String educationLevel) {
    return educationLevels[educationLevel] ?? ["Other"];
  }

  /// Returns a list of specializations for a given degree. If not found, returns "General".
  static List<String> getSpecializations(String degree) {
    return specializations[degree] ?? ["General"];
  }
}
