import 'dart:convert';
import '../config/api_config.dart';
import 'api_client.dart';

class ApiResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });
}

class ApiService {
  static const Duration _timeout = Duration(seconds: 12);

  // Check System Status (Maintenance & Registration)
  static Future<Map<String, dynamic>> getSystemStatus() async {
    try {
      final response = await ApiClient.client
          .get(Uri.parse(ApiConfig.systemStatusUrl))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }
    } catch (_) {}
    return {'maintenance': false, 'registration': true};
  }

  // Register
  static Future<ApiResponse> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiClient.client.post(
        Uri.parse(ApiConfig.registerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
        }),
      ).timeout(_timeout);

      final body = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: body['message'] ?? 'Registration successful!',
          data: body,
        );
      } else {
        return ApiResponse(
          success: false,
          message: body['message'] ?? 'Registration failed',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error. Please check your backend connection.',
      );
    }
  }

  // Verify Email
  static Future<ApiResponse> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final response = await ApiClient.client.post(
        Uri.parse(ApiConfig.verifyEmailUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'code': code.trim(),
        }),
      ).timeout(_timeout);

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: body['message'] ?? 'Email verified successfully!',
          data: body,
        );
      } else {
        return ApiResponse(
          success: false,
          message: body['message'] ?? 'Invalid verification code',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error. Please try again.',
      );
    }
  }

  // Resend Verification Code
  static Future<ApiResponse> resendVerificationCode({
    required String email,
  }) async {
    try {
      final response = await ApiClient.client.post(
        Uri.parse(ApiConfig.resendCodeUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
        }),
      ).timeout(_timeout);

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: body['message'] ?? 'New verification code sent to your email!',
          data: body,
        );
      } else {
        return ApiResponse(
          success: false,
          message: body['message'] ?? 'Failed to resend verification code',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error. Please try again.',
      );
    }
  }

  // Login
  static Future<ApiResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiClient.client.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'password': password,
        }),
      ).timeout(_timeout);

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: body['message'] ?? 'Login successful!',
          data: body,
        );
      } else {
        return ApiResponse(
          success: false,
          message: body['message'] ?? 'Login failed',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Unable to connect to server ($e)',
      );
    }
  }

  // Forgot Password
  static Future<ApiResponse> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await ApiClient.client.post(
        Uri.parse(ApiConfig.forgotPasswordUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
        }),
      ).timeout(_timeout);

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: body['message'] ?? 'Reset code sent to your email!',
          data: body,
        );
      } else {
        return ApiResponse(
          success: false,
          message: body['message'] ?? 'Failed to send reset code',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error. Please try again.',
      );
    }
  }

  // Reset Password
  static Future<ApiResponse> resetPassword({
    required String email,
    required String resetCode,
    required String newPassword,
  }) async {
    try {
      final response = await ApiClient.client.post(
        Uri.parse(ApiConfig.resetPasswordUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'resetCode': resetCode.trim(),
          'newPassword': newPassword,
        }),
      ).timeout(_timeout);

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: body['message'] ?? 'Password reset successfully!',
          data: body,
        );
      } else {
        return ApiResponse(
          success: false,
          message: body['message'] ?? 'Failed to reset password',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error. Please try again.',
      );
    }
  }

  // Google Login
  static Future<ApiResponse> googleLogin({
    required String? idToken,
    String? email,
    String? name,
  }) async {
    try {
      final response = await ApiClient.client.post(
        Uri.parse(ApiConfig.googleLoginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': ?idToken,
          'email': ?email?.trim().toLowerCase(),
          'name': ?name,
        }),
      ).timeout(_timeout);

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse(
          success: true,
          message: body['message'] ?? 'Google sign in successful!',
          data: body,
        );
      } else {
        return ApiResponse(
          success: false,
          message: body['message'] ?? 'Google sign in failed',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error. Please try again. ($e)',
      );
    }
  }
}
