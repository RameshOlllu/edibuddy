import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static final _storage = const FlutterSecureStorage();

  // Get the API key on demand
  static Future<String> getApiKey() async {
    // Check if the key is in secure storage
    String? apiKey = await _storage.read(key: 'GOOGLE_API_KEY');
    if (apiKey != null) {
      return apiKey; // Return cached key
    }

    // Fetch key from Firebase Remote Config
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(hours: 1),
    ));
    await remoteConfig.fetchAndActivate();
    apiKey = remoteConfig.getString('GOOGLE_API_KEY');

    // Store the key securely
    await _storage.write(key: 'GOOGLE_API_KEY', value: apiKey);
    return apiKey;
  }
}
