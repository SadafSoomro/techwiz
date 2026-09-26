import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'admin_storage.dart';

/// Thin HTTP layer for the Member 6 admin portal.
///
/// Every call attaches the admin JWT from [AdminStorage]. A 401/403 response
/// fires [onUnauthorized] so the shell can bounce back to the admin login
/// screen instead of leaving the panel in a broken half-loaded state.
class AdminService {
  /// Set by AdminProvider; invoked when the server rejects our token.
  static void Function()? onUnauthorized;

  static Future<Map<String, String>> _headers() async {
    final token = await AdminStorage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> _send(
    String method,
    String url, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
  }) async {
    try {
      final uri = Uri.parse(url).replace(
        queryParameters: query?.map((k, v) => MapEntry(k, v?.toString() ?? '')),
      );
      final headers = await _headers();
      final encoded = body == null ? null : jsonEncode(body);

      late final http.Response response;
      switch (method) {
        case 'POST':
          response = await http.post(uri, headers: headers, body: encoded);
          break;
        case 'PUT':
          response = await http.put(uri, headers: headers, body: encoded);
          break;
        case 'PATCH':
          response = await http.patch(uri, headers: headers, body: encoded);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers, body: encoded);
          break;
        default:
          response = await http.get(uri, headers: headers);
      }

      if (response.statusCode == 401) {
        onUnauthorized?.call();
      }

      if (response.body.isEmpty) {
        return {'success': false, 'message': 'Empty response from server.'};
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return {
          'success': false,
          'message': 'Unexpected response from server.',
        };
      }

      if (response.statusCode >= 300 && decoded['success'] == null) {
        decoded['success'] = false;
        decoded['message'] ??= 'Request failed (${response.statusCode})';
      }

      return decoded;
    } catch (error) {
      return {
        'success': false,
        'message': 'Unable to reach the server. ($error)',
      };
    }
  }

  // ------------------------------------------------------------------ auth

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) {
    return _send(
      'POST',
      ApiConfig.adminLoginUrl,
      body: {'email': email.trim(), 'password': password},
    );
  }

  static Future<Map<String, dynamic>> me() =>
      _send('GET', ApiConfig.adminMeUrl);

  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? currentPassword,
    String? newPassword,
  }) {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (currentPassword != null && currentPassword.isNotEmpty) {
      payload['current_password'] = currentPassword;
    }
    if (newPassword != null && newPassword.isNotEmpty) {
      payload['new_password'] = newPassword;
    }
    return _send('PUT', ApiConfig.adminProfileUrl, body: payload);
  }

  // ------------------------------------------------------------- dashboard

  static Future<Map<String, dynamic>> dashboard() =>
      _send('GET', ApiConfig.adminDashboardUrl);

  // ----------------------------------------------------------------- users

  static Future<Map<String, dynamic>> users({
    String search = '',
    String role = '',
    String status = '',
    int page = 1,
    int limit = 20,
  }) => _send(
    'GET',
    ApiConfig.adminUsersUrl,
    query: {
      'search': search,
      'role': role,
      'status': status,
      'page': page,
      'limit': limit,
    },
  );

  static Future<Map<String, dynamic>> userDetail(int id) =>
      _send('GET', ApiConfig.adminUserUrl(id));

  static Future<Map<String, dynamic>> createUser(Map<String, dynamic> body) =>
      _send('POST', ApiConfig.adminUsersUrl, body: body);

  static Future<Map<String, dynamic>> updateUser(
    int id,
    Map<String, dynamic> body,
  ) => _send('PUT', ApiConfig.adminUserUrl(id), body: body);

  static Future<Map<String, dynamic>> setUserStatus(int id, bool isActive) =>
      _send(
        'PATCH',
        ApiConfig.adminUserStatusUrl(id),
        body: {'is_active': isActive},
      );

  static Future<Map<String, dynamic>> deleteUser(int id) =>
      _send('DELETE', ApiConfig.adminUserUrl(id));

  // --------------------------------------------------------------- content

  static Future<Map<String, dynamic>> content({
    String search = '',
    String type = '',
    int page = 1,
    int limit = 20,
  }) => _send(
    'GET',
    ApiConfig.adminContentUrl,
    query: {'search': search, 'type': type, 'page': page, 'limit': limit},
  );

  static Future<Map<String, dynamic>> createContent(
    Map<String, dynamic> body,
  ) => _send('POST', ApiConfig.adminContentUrl, body: body);

  static Future<Map<String, dynamic>> updateContent(
    int id,
    Map<String, dynamic> body,
  ) => _send('PUT', ApiConfig.adminContentItemUrl(id), body: body);

  static Future<Map<String, dynamic>> deleteContent(int id) =>
      _send('DELETE', ApiConfig.adminContentItemUrl(id));

  // ---------------------------------------------------------------- events

  static Future<Map<String, dynamic>> events({
    String search = '',
    String status = '',
    int page = 1,
    int limit = 20,
  }) => _send(
    'GET',
    ApiConfig.adminEventsUrl,
    query: {'search': search, 'status': status, 'page': page, 'limit': limit},
  );

  static Future<Map<String, dynamic>> createEvent(Map<String, dynamic> body) =>
      _send('POST', ApiConfig.adminEventsUrl, body: body);

  static Future<Map<String, dynamic>> updateEvent(
    int id,
    Map<String, dynamic> body,
  ) => _send('PUT', ApiConfig.adminEventUrl(id), body: body);

  static Future<Map<String, dynamic>> deleteEvent(int id) =>
      _send('DELETE', ApiConfig.adminEventUrl(id));

  // -------------------------------------------------------------- products

  static Future<Map<String, dynamic>> products({
    String search = '',
    String status = '',
    int page = 1,
    int limit = 20,
  }) => _send(
    'GET',
    ApiConfig.adminProductsUrl,
    query: {'search': search, 'status': status, 'page': page, 'limit': limit},
  );

  static Future<Map<String, dynamic>> createProduct(
    Map<String, dynamic> body,
  ) => _send('POST', ApiConfig.adminProductsUrl, body: body);

  static Future<Map<String, dynamic>> updateProduct(
    int id,
    Map<String, dynamic> body,
  ) => _send('PUT', ApiConfig.adminProductUrl(id), body: body);

  static Future<Map<String, dynamic>> deleteProduct(int id) =>
      _send('DELETE', ApiConfig.adminProductUrl(id));

  // ------------------------------------------------------------ categories

  static Future<Map<String, dynamic>> categories({String kind = 'product'}) =>
      _send('GET', ApiConfig.adminCategoriesUrl, query: {'kind': kind});

  static Future<Map<String, dynamic>> createCategory(
    Map<String, dynamic> body,
  ) => _send('POST', ApiConfig.adminCategoriesUrl, body: body);

  static Future<Map<String, dynamic>> updateCategory(
    int id,
    Map<String, dynamic> body,
  ) => _send('PUT', ApiConfig.adminCategoryUrl(id), body: body);

  static Future<Map<String, dynamic>> deleteCategory(int id, String kind) =>
      _send('DELETE', ApiConfig.adminCategoryUrl(id), query: {'kind': kind});

  // --------------------------------------------------------- notifications

  static Future<Map<String, dynamic>> notifications() =>
      _send('GET', ApiConfig.adminNotificationsUrl);

  static Future<Map<String, dynamic>> sendNotification(
    Map<String, dynamic> body,
  ) => _send('POST', ApiConfig.adminNotificationsUrl, body: body);

  static Future<Map<String, dynamic>> deleteNotification(int id) =>
      _send('DELETE', ApiConfig.adminNotificationUrl(id));

  // -------------------------------------------------------------- security

  static Future<Map<String, dynamic>> security() =>
      _send('GET', ApiConfig.adminSecurityUrl);

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _send(
    'PUT',
    ApiConfig.adminPasswordUrl,
    body: {'current_password': currentPassword, 'new_password': newPassword},
  );

  static Future<Map<String, dynamic>> saveSecuritySettings(
    Map<String, dynamic> settings,
  ) => _send('PUT', ApiConfig.adminSecuritySettingsUrl, body: settings);

  // ---------------------------------------------------------------- backup

  static Future<Map<String, dynamic>> backupInfo() =>
      _send('GET', ApiConfig.adminBackupUrl);

  static Future<Map<String, dynamic>> createBackup() =>
      _send('POST', ApiConfig.adminBackupUrl);

  /// Direct link (token appended as a query param) so a browser can download it.
  static Future<String> backupDownloadUrl({String? file}) async {
    final token = await AdminStorage.getToken();
    final base = ApiConfig.adminBackupDownloadUrl;
    final query = <String>[
      if (token != null && token.isNotEmpty) 'token=$token',
      if (file != null && file.isNotEmpty) 'file=$file',
    ];
    return query.isEmpty ? base : '$base?${query.join('&')}';
  }

  // ------------------------------------------------------------------ logs

  static Future<Map<String, dynamic>> logs({
    String level = '',
    String search = '',
    int page = 1,
    int limit = 40,
  }) => _send(
    'GET',
    ApiConfig.adminLogsUrl,
    query: {'level': level, 'search': search, 'page': page, 'limit': limit},
  );

  static Future<Map<String, dynamic>> clearLogs({String level = ''}) =>
      _send('DELETE', ApiConfig.adminLogsUrl, query: {'level': level});
}
