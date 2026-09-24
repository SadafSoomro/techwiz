import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../services/google_auth_service.dart';

enum AuthStatus { initial, authenticating, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;
  String? _token;
  AuthStatus _status = AuthStatus.initial;
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic>? get user => _user;
  String? get token => _token;
  AuthStatus get status => _status;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _token != null;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    checkAuthStatus();
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

  // Check saved token on app start
  Future<bool> checkAuthStatus() async {
    _setLoading(true);
    try {
      final isLoggedIn = await AuthStorage.isLoggedIn();
      if (isLoggedIn) {
        _token = await AuthStorage.getToken();
        _user = await AuthStorage.getUser();
        _status = AuthStatus.authenticated;
        _setLoading(false);
        return true;
      } else {
        _status = AuthStatus.unauthenticated;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _setLoading(false);
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

    final response = await ApiService.verifyEmail(
      email: email,
      code: code,
    );

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
    await GoogleAuthService.signOut();
    _token = null;
    _user = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    _setLoading(false);
  }
}
