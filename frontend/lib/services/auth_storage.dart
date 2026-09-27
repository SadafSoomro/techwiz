import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Session storage for the JWT + cached user payload.
///
/// The token used to be read from `SharedPreferences` on *every* API call
/// (`ApiClient.headers()` -> `AuthStorage.getToken()`), which meant every
/// request in the app waited on a platform-channel round trip before it could
/// even start. The values are now held in memory after a single [preload], so
/// building request headers is effectively free.
class AuthStorage {
  static const String _keyToken = 'jwt_token';
  static const String _keyUser = 'user_data';

  static SharedPreferences? _prefs;

  /// In-memory mirror of the two values, kept in sync by the setters below.
  static String? _token;
  static String? _userJson;
  static bool _loaded = false;

  /// Reads the session once. Called from `main()` before the first frame so no
  /// later request has to wait for disk.
  static Future<void> preload() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      _token = _prefs!.getString(_keyToken);
      _userJson = _prefs!.getString(_keyUser);
    } catch (_) {
      // If storage is unavailable the app still runs, just without a session.
    }
    _loaded = true;
  }

  static Future<SharedPreferences> _instance() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  /// Save Token & User Info
  static Future<void> saveSession(
    String token,
    Map<String, dynamic>? user,
  ) async {
    _token = token;
    _userJson = user == null ? null : jsonEncode(user);
    _loaded = true;

    try {
      final prefs = await _instance();
      await prefs.setString(_keyToken, token);
      if (user != null) {
        await prefs.setString(_keyUser, _userJson!);
      }
    } catch (_) {
      // The in-memory copy is already updated, so the session still works.
    }
  }

  /// Get Token - served from memory whenever available.
  static Future<String?> getToken() async {
    if (!_loaded) await preload();
    return _token;
  }

  /// Synchronous token access for hot paths such as request headers.
  static String? get tokenOrNull => _loaded ? _token : null;

  /// Get User Data
  static Future<Map<String, dynamic>?> getUser() async {
    if (!_loaded) await preload();
    final userStr = _userJson;
    if (userStr != null && userStr.isNotEmpty) {
      try {
        return jsonDecode(userStr) as Map<String, dynamic>;
      } catch (_) {}
    }
    return null;
  }

  /// Clear Session (Logout)
  static Future<void> clearSession() async {
    _token = null;
    _userJson = null;
    _loaded = true;

    try {
      final prefs = await _instance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyUser);
    } catch (_) {}
  }

  /// Check if logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
