import 'package:flutter/material.dart';

import '../services/admin_storage.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../services/google_auth_service.dart';

enum AuthStatus {
  initial,
  authenticating,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;
  String? _token;
  AuthStatus _status = AuthStatus.initial;
  bool _isLoading = false;
  bool _sessionReady = false;
  String? _errorMessage;

  Map<String, dynamic>? get user => _user;
  String? get token => _token;
  AuthStatus get status => _status;
  bool get isLoading => _isLoading;

  /// False only while the saved session is being read on startup.
  /// Login / logout keep using [isLoading] and must not blank the whole app.
  bool get isSessionReady => _sessionReady;
  bool get isAuthenticated =>
      _status == AuthStatus.authenticated && _token != null;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    // Deferred: restoring the session calls notifyListeners(), which must not
    // happen while the widget tree is still building the provider.
    Future.microtask(_restoreSession);
  }

  /// Reads the saved session without ever flipping [isLoading].
  ///
  /// [isLoading] used to cover this path too, and the root gate treated any
  /// loading flag as "replace the app with a black screen". A slow or stuck
  /// storage read then left that black screen up. This path is capped so the
  /// login screen always appears.
  Future<void> _restoreSession() async {
    try {
      await checkAuthStatus().timeout(const Duration(seconds: 4));
    } catch (_) {
      if (_status == AuthStatus.initial) {
        _status = AuthStatus.unauthenticated;
      }
    } finally {
      _isLoading = false;
      _sessionReady = true;
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    if (message != null) {
      _status = AuthStatus.error;
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// The login screen is now the single door for both fans and administrators,
  /// but the admin panel keeps its session under a different storage key
  /// (AdminStorage) so the two never bleed into each other. Without this
  /// mirror an admin would open the panel and every admin API would 401.
  Future<void> _syncAdminSession() async {
    if (_token == null || _token!.isEmpty) return;

    final role = (_user?['role'] ?? 'user').toString().toLowerCase();
    if (role == 'admin') {
      await AdminStorage.saveSession(_token!, _user);
    } else {
      await AdminStorage.clearSession();
    }
  }

  // Check saved token on app start. Does not toggle [isLoading]: callers that
  // need a button spinner set that themselves. Storage is read once, in order,
  // so two parallel SharedPreferences opens cannot stall the first frame.
  Future<bool> checkAuthStatus() async {
    try {
      await AuthStorage.preload().timeout(const Duration(seconds: 2));
      await AdminStorage.preload().timeout(const Duration(seconds: 2));
      final isLoggedIn = await AuthStorage.isLoggedIn();
      if (isLoggedIn) {
        _token = await AuthStorage.getToken();
        _user = await AuthStorage.getUser();
        _status = AuthStatus.authenticated;
        await _syncAdminSession();
        notifyListeners();
        return true;
      }
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // Email & Password Login
  Future<ApiResponse> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    final response = await ApiService.login(email: email, password: password);

    if (response.success && response.data != null) {
      _token = response.data!['token'];
      _user = response.data!['user'];
      await AuthStorage.saveSession(_token ?? '', _user);
      await _syncAdminSession();
      _status = AuthStatus.authenticated;
    } else {
      _setError(response.message);
    }

    _setLoading(false);
    return response;
  }

  // Registration
  Future<ApiResponse> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    final response = await ApiService.register(
      name: name,
      email: email,
      password: password,
    );

    if (!response.success) {
      _setError(response.message);
    }

    _setLoading(false);
    return response;
  }

  // Verify Email Code
  Future<ApiResponse> verifyEmail({
    required String email,
    required String code,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    final response = await ApiService.verifyEmail(email: email, code: code);

    if (response.success && response.data != null) {
      _token = response.data!['token'];
      _user = response.data!['user'];
      if (_token != null && _user != null) {
        await AuthStorage.saveSession(_token ?? '', _user);
        await _syncAdminSession();
        _status = AuthStatus.authenticated;
      }
    } else if (!response.success) {
      _setError(response.message);
    }

    _setLoading(false);
    return response;
  }

  // Resend Verification Code
  Future<ApiResponse> resendVerificationCode({
    required String email,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    final response = await ApiService.resendVerificationCode(email: email);

    if (!response.success) {
      _setError(response.message);
    }

    _setLoading(false);
    return response;
  }

  // Forgot Password
  Future<ApiResponse> forgotPassword({required String email}) async {
    _setLoading(true);
    _errorMessage = null;

    final response = await ApiService.forgotPassword(email: email);

    if (!response.success) {
      _setError(response.message);
    }

    _setLoading(false);
    return response;
  }

  // Reset Password
  Future<ApiResponse> resetPassword({
    required String email,
    required String resetCode,
    required String newPassword,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    final response = await ApiService.resetPassword(
      email: email,
      resetCode: resetCode,
      newPassword: newPassword,
    );

    if (!response.success) {
      _setError(response.message);
    }

    _setLoading(false);
    return response;
  }

  // Google Sign-In
  Future<ApiResponse> loginWithGoogle() async {
    _setLoading(true);
    _errorMessage = null;

    final response = await GoogleAuthService.signInWithGoogle();

    if (response.success && response.data != null) {
      _token = response.data!['token'];
      _user = response.data!['user'];
      await AuthStorage.saveSession(_token ?? '', _user);
      await _syncAdminSession();
      _status = AuthStatus.authenticated;
    } else if (!response.message.contains('cancelled')) {
      _setError(response.message);
    }

    _setLoading(false);
    return response;
  }

  // Google Email Fallback Login
  Future<ApiResponse> loginWithGoogleEmail({
    required String email,
    String? name,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    final response = await GoogleAuthService.loginWithGoogleEmail(
      email: email,
      name: name,
    );

    if (response.success && response.data != null) {
      _token = response.data!['token'];
      _user = response.data!['user'];
      await AuthStorage.saveSession(_token ?? '', _user);
      await _syncAdminSession();
      _status = AuthStatus.authenticated;
    } else {
      _setError(response.message);
    }

    _setLoading(false);
    return response;
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);
    await AuthStorage.clearSession();
    await AdminStorage.clearSession();
    await GoogleAuthService.signOut();
    _token = null;
    _user = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    _setLoading(false);
  }
}
