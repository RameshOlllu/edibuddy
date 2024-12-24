class LanguageData {
  static const List<String> proficiencyLevels = [
    "No English",
    "Basic",
    "Intermediate",
    "Advanced",
  ];

  static const Map<String, String> proficiencyDescriptions = {
    "No English": "You do not understand or speak English.",
    "Basic": "You can understand/speak basic sentences.",
    "Intermediate": "You can have a conversation in English on some topics.",
    "Advanced": "You can do your entire job in English and speak fluently.",
  };

  static const List<String> languages = [
    "Hindi",
    "Telugu",
    "Bengali",
    "Kannada",
    "Marathi",
    "Tamil",
    "Oriya",
    "Gujarati",
    "Malayalam",
    "Urdu",
    "Punjabi",
    "Assamese",
    "Nepali",
    "Kashmiri",
    "Maithili",
    "Rajasthani",
    "Haryanvi",
    "French",
    "German",
    "Spanish",
    "Japanese",
    "Mandarin",
    "Arabic",
    "Russian",
    "Italian",
    "Korean",
    "Turkish",
  ];

  static List<String> getAllLanguages() {
    return languages.toList()..sort();
  }
}
