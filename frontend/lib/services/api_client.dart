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
  static Future<Map<String, String>> headers() async {
    final token = await AuthStorage.getToken();
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

    final requestHeaders = await headers();
    final encoded = body == null ? null : jsonEncode(body);

    late final http.Response response;
    switch (method) {
      case 'POST':
        response = await http.post(uri, headers: requestHeaders, body: encoded);
        break;
      case 'PUT':
        response = await http.put(uri, headers: requestHeaders, body: encoded);
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: requestHeaders, body: encoded);
        break;
      default:
        response = await http.get(uri, headers: requestHeaders);
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
