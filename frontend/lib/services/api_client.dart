import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_storage.dart';

/// Generic result wrapper used by the Member 1 / Member 2 services.
class ApiResult<T> {
  final bool success;
  final String message;
  final T? data;

  const ApiResult({required this.success, required this.message, this.data});

  factory ApiResult.failure(String message) =>
      ApiResult(success: false, message: message);
}

/// Thin HTTP helper shared by the Profile (Member 1) and Content (Member 2)
/// services. The JWT saved by the login flow is attached automatically, so the
/// feature services only deal with JSON <-> model mapping.
class ApiClient {
  /// One long-lived client for the whole app.
  ///
  /// `http.get(...)` and friends create (and immediately close) a brand new
  /// client per call, which throws away the underlying connection pool. Every
  /// call then paid for a fresh TCP/TLS handshake, and with the Home screen
  /// firing a dozen requests at once those handshakes queued up - the main
  /// reason the first screen felt like it was "loading forever". A shared
  /// client keeps the connections alive and reuses them.
  static final http.Client _client = http.Client();

  /// Per-request ceiling so a stalled backend can never freeze a screen.
  static const Duration timeout = Duration(seconds: 15);

  /// The shared, connection-reusing client.
  ///
  /// Every feature service (shop, events, community, AI, profile, content)
  /// sends through this one instance, so the app keeps a single warm
  /// connection pool instead of opening a brand new connection per request.
  static http.Client get client => _client;

  static Map<String, String> headers() {
    // Served from memory by AuthStorage - no storage round trip per request.
    final token = AuthStorage.tokenOrNull;
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Sends a request and returns the decoded JSON body (or null on failure).
  static Future<Map<String, dynamic>?> send(
    String method,
    String url, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
  }) async {
    final uri = Uri.parse(url).replace(
      queryParameters: query?.map((k, v) => MapEntry(k, v?.toString() ?? '')),
    );

    final requestHeaders = headers();
    final encoded = body == null ? null : jsonEncode(body);

    late final http.Response response;
    switch (method) {
      case 'POST':
        response = await _client
            .post(uri, headers: requestHeaders, body: encoded)
            .timeout(timeout);
        break;
      case 'PUT':
        response = await _client
            .put(uri, headers: requestHeaders, body: encoded)
            .timeout(timeout);
        break;
      case 'DELETE':
        response = await _client
            .delete(uri, headers: requestHeaders, body: encoded)
            .timeout(timeout);
        break;
      default:
        response =
            await _client.get(uri, headers: requestHeaders).timeout(timeout);
    }

    if (response.body.isEmpty) {
      return {'success': false, 'message': 'Empty response from server'};
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return {'success': false, 'message': 'Unexpected response from server'};
    }

    // Normalise non-2xx responses into the {success, message} shape.
    if (response.statusCode >= 300 && decoded['success'] == null) {
      decoded['success'] = false;
      decoded['message'] ??= 'Request failed (${response.statusCode})';
    }
    return decoded;
  }

  /// Convenience wrapper that maps a JSON body into a model.
  static Future<ApiResult<T>> request<T>(
    String method,
    String url, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
    T Function(Map<String, dynamic> json)? parser,
  }) async {
    try {
      final json = await send(method, url, body: body, query: query);

      if (json == null) {
        return ApiResult.failure('No response from the server.');
      }
      if (json['success'] != true) {
        return ApiResult.failure(json['message']?.toString() ?? 'Request failed');
      }

      return ApiResult(
        success: true,
        message: json['message']?.toString() ?? 'OK',
        data: parser == null ? null : parser(json),
      );
    } catch (error) {
      return ApiResult.failure('Unable to reach the server. ($error)');
    }
  }
}
