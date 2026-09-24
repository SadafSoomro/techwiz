import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // Base URL auto-detection based on device/platform
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5000/api';
      }
    } catch (_) {}
    return 'http://localhost:5000/api';
  }

  // Google Client ID
  static const String googleClientId =
      '346283855204-tmhtfilf469h44b4jc8mri4oqokfk7jf.apps.googleusercontent.com';

  // Endpoints
  static String get registerUrl => '$baseUrl/auth/register';
  static String get verifyEmailUrl => '$baseUrl/auth/verify-email';
  static String get loginUrl => '$baseUrl/auth/login';
  static String get forgotPasswordUrl => '$baseUrl/auth/forgot-password';
  static String get resetPasswordUrl => '$baseUrl/auth/reset-password';
  static String get googleLoginUrl => '$baseUrl/auth/google';
  static String get getUsersUrl => '$baseUrl/users/getall';
}
