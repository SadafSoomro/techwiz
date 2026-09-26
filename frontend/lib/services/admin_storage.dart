import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Session storage for the admin portal.
///
/// Deliberately kept in different SharedPreferences keys than [AuthStorage]:
/// an administrator signing into the panel must not silently log the fan-facing
/// app in as that account (and vice versa), so the two sessions are independent.
class AdminStorage {
  static const String _keyToken = 'admin_jwt_token';
  static const String _keyAdmin = 'admin_user';

  static Future<void> saveSession(
    String token,
    Map<String, dynamic>? admin,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    if (admin != null) {
      await prefs.setString(_keyAdmin, jsonEncode(admin));
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<Map<String, dynamic>?> getAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyAdmin);
    if (raw != null && raw.isNotEmpty) {
      try {
        return jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {}
    }
    return null;
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyAdmin);
  }
}
