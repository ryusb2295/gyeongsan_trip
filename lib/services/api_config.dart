import 'dart:io';

class ApiConfig {
  static const configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

  // Android Emulator reaches the host PC through 10.0.2.2.
  // Set API_BASE_URL to an HTTPS deployment URL for a published app.
  static String get baseUrl {
    if (configuredBaseUrl.isNotEmpty) {
      return configuredBaseUrl.replaceFirst(RegExp(r'/$'), '');
    }
    return Platform.isAndroid
        ? 'http://10.0.2.2:8000'
        : 'http://127.0.0.1:8000';
  }
}
