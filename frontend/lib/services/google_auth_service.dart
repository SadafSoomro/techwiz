import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: ApiConfig.googleClientId,
    scopes: ['email', 'profile'],
  );

  static Future<ApiResponse> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return ApiResponse(
          success: false,
          message: 'Google Sign-In was cancelled.',
        );
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      return await ApiService.googleLogin(
        idToken: idToken,
        email: googleUser.email,
        name: googleUser.displayName,
      );
    } on PlatformException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Google Authorization Error: ${e.message ?? e.code}. (Google Console origin setup required)',
      );
    } catch (error) {
      return ApiResponse(
        success: false,
        message: 'Google Auth Error: $error',
      );
    }
  }

  // Direct Google Email Login Fallback (for local testing when Google Console popup is restricted)
  static Future<ApiResponse> loginWithGoogleEmail({
    required String email,
    String? name,
  }) async {
    return await ApiService.googleLogin(
      idToken: null,
      email: email,
      name: name ?? 'Google User',
    );
  }

  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
