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

  static SharedPreferences? _prefs;
  static String? _token;
  static String? _adminJson;
  static bool _loaded = false;

  /// Loads the admin session once into memory.
  static Future<void> preload() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      _token = _prefs!.getString(_keyToken);
      _adminJson = _prefs!.getString(_keyAdmin);
    } catch (_) {}
    _loaded = true;
  }

  static Future<SharedPreferences> _instance() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<void> saveSession(
    String token,
    Map<String, dynamic>? admin,
  ) async {
    _token = token;
    _adminJson = admin == null ? null : jsonEncode(admin);
    _loaded = true;

    try {
      final prefs = await _instance();
      await prefs.setString(_keyToken, token);
      if (admin != null) {
        await prefs.setString(_keyAdmin, _adminJson!);
      }
    } catch (_) {}
  }

  static Future<String?> getToken() async {
    if (!_loaded) await preload();
    return _token;
  }

  /// Synchronous token access for hot paths such as request headers.
  static String? get tokenOrNull => _loaded ? _token : null;

  static Future<Map<String, dynamic>?> getAdmin() async {
    if (!_loaded) await preload();
    final raw = _adminJson;
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
    _token = null;
    _adminJson = null;
    _loaded = true;

    try {
      final prefs = await _instance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyAdmin);
    } catch (_) {}
  }
}
