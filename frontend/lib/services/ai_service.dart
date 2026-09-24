import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/ai_models.dart';
import '../models/json_utils.dart';
import 'auth_storage.dart';

/// MEMBER 5 - AI Fan Helper
/// HTTP layer over the /api/ai routes.
///
/// The chat endpoint accepts anonymous callers too, so the assistant answers
/// even before login - the token is only needed to persist the history.
class AiResult<T> {
  final bool success;
  final String message;
  final T? data;

  AiResult({required this.success, required this.message, this.data});

  factory AiResult.failure(String message) =>
      AiResult(success: false, message: message);
}

class AiService {
  static Future<Map<String, String>> _headers() async {
    final token = await AuthStorage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>?> _send(
    String method,
    String url, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse(url);
    final headers = await _headers();
    final encoded = body == null ? null : jsonEncode(body);

    late final http.Response response;
    switch (method) {
      case 'POST':
        response = await http.post(uri, headers: headers, body: encoded);
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: headers);
        break;
      default:
        response = await http.get(uri, headers: headers);
    }

    if (response.body.isEmpty) {
      return {'success': false, 'message': 'Empty response from server'};
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<AiResult<T>> _guard<T>(
    Future<Map<String, dynamic>?> Function() request,
    T Function(Map<String, dynamic> json) parse,
    String fallbackMessage,
  ) async {
    try {
      final json = await request();

      if (json != null && json['success'] == true) {
        return AiResult(success: true, message: 'OK', data: parse(json));
      }
      return AiResult.failure(json?['message'] ?? fallbackMessage);
    } catch (e) {
      return AiResult.failure('Network error ($e)');
    }
  }

  /// Starter chips + the welcome line. Public - works without a token.
  static Future<AiResult<Map<String, dynamic>>> suggestions() {
    return _guard(
      () => _send('GET', ApiConfig.aiSuggestionsUrl),
      (json) => json,
      'Could not load the assistant',
    );
  }

  /// Knowledge base topics (used by the assistant's info sheet).
  static Future<AiResult<List<AiTopicCount>>> topics() {
    return _guard(
      () => _send('GET', ApiConfig.aiTopicsUrl),
      (json) => parseList(json['topics'], AiTopicCount.fromJson),
      'Could not load topics',
    );
  }

  /// Asks the assistant a question.
  /// [history] is not sent to the server - the backend keeps its own recent
  /// turns - so only the message itself is required here.
  static Future<AiResult<AiReply>> ask(String message) {
    return _guard(
      () => _send('POST', ApiConfig.aiChatUrl, body: {'message': message}),
      AiReply.fromJson,
      'The assistant could not answer right now',
    );
  }

  static Future<AiResult<List<AiMessage>>> history({int limit = 50}) {
    return _guard(
      () => _send('GET', '${ApiConfig.aiHistoryUrl}?limit=$limit'),
      (json) => parseList(json['messages'], AiMessage.fromJson),
      'Could not load your chat history',
    );
  }

  static Future<AiResult<String>> clearHistory() {
    return _guard(
      () => _send('DELETE', ApiConfig.aiHistoryUrl),
      (json) => json['message']?.toString() ?? 'Chat history cleared',
      'Could not clear the chat history',
    );
  }
}
