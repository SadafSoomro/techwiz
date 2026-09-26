import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/admin_service.dart';
import '../services/admin_storage.dart';

enum AdminAuthStatus { unknown, signedOut, signedIn }

/// Holds the admin portal session.
///
/// Only the session lives here - each section screen owns its own list state
/// and talks to [AdminService] directly, which keeps this provider small and
/// means one failing section can never wipe the rest of the panel.
class AdminProvider extends ChangeNotifier {
  static const String _themePrefKey = 'admin_light_mode';

  AdminAuthStatus _status = AdminAuthStatus.unknown;
  Map<String, dynamic>? _admin;
  bool _busy = false;
  String? _error;
  bool _lightMode = false;

  AdminAuthStatus get status => _status;
  Map<String, dynamic>? get admin => _admin;
  bool get signedIn => _status == AdminAuthStatus.signedIn;
  bool get busy => _busy;
  String? get error => _error;

  /// When true the panel renders with [AdminTheme.light]. Persisted so the
  /// choice survives a reload.
  bool get lightMode => _lightMode;

  String get adminName => (_admin?['name'] ?? 'Administrator').toString();
  String get adminEmail => (_admin?['email'] ?? '').toString();

  AdminProvider() {
    // Bounce back to the login screen whenever the server rejects the token.
    AdminService.onUnauthorized = () {
      if (_status == AdminAuthStatus.signedIn) {
        signOut();
      }
    };
    Future.microtask(restoreSession);
    Future.microtask(loadThemePreference);
  }

  /// Restores the saved dark/light choice.
  Future<void> loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lightMode = prefs.getBool(_themePrefKey) ?? false;
      notifyListeners();
    } catch (_) {
      // Preference storage unavailable - keep the dark default.
    }
  }

  /// Flips the panel between dark and light and remembers the choice.
  Future<void> toggleTheme() async {
    _lightMode = !_lightMode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themePrefKey, _lightMode);
    } catch (_) {
      // Non-fatal: the toggle still works for this session.
    }
  }

  /// Reuses a saved admin token so the panel survives a hot restart.
  Future<void> restoreSession() async {
    try {
      if (!await AdminStorage.isLoggedIn()) {
        _status = AdminAuthStatus.signedOut;
        notifyListeners();
        return;
      }

      _admin = await AdminStorage.getAdmin();

      // Verify against the server: the token may have expired or the account
      // may have been demoted since it was saved.
      final response = await AdminService.me();
      if (response['success'] == true) {
        _admin = Map<String, dynamic>.from(response['admin'] ?? {});
        await AdminStorage.saveSession(
          (await AdminStorage.getToken()) ?? '',
          _admin,
        );
        _status = AdminAuthStatus.signedIn;
      } else {
        await AdminStorage.clearSession();
        _admin = null;
        _status = AdminAuthStatus.signedOut;
      }
    } catch (_) {
      await AdminStorage.clearSession();
      _admin = null;
      _status = AdminAuthStatus.signedOut;
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();

    final response = await AdminService.login(email: email, password: password);

    if (response['success'] == true) {
      final token = (response['token'] ?? '').toString();
      _admin = Map<String, dynamic>.from(response['admin'] ?? {});
      await AdminStorage.saveSession(token, _admin);
      _status = AdminAuthStatus.signedIn;
    } else {
      _error = (response['message'] ?? 'Admin login failed').toString();
    }

    _busy = false;
    notifyListeners();
    return response;
  }

  Future<void> updateAdminData(Map<String, dynamic> updatedAdmin) async {
    _admin = Map<String, dynamic>.from(updatedAdmin);
    final token = (await AdminStorage.getToken()) ?? '';
    await AdminStorage.saveSession(token, _admin);
    notifyListeners();
  }

  Future<void> signOut() async {
    await AdminStorage.clearSession();
    _admin = null;
    _error = null;
    _status = AdminAuthStatus.signedOut;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
