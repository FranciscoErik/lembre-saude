import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// URL base da API Node.js (`/api/v1`).
class ApiConfig {
  static String get baseUrl {
    if (const String.fromEnvironment('API_BASE_URL').isNotEmpty) {
      return const String.fromEnvironment('API_BASE_URL');
    }
    if (kIsWeb) {
      return 'http://localhost:3000/api/v1';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api/v1';
    }
    return 'http://localhost:3000/api/v1';
  }
}
