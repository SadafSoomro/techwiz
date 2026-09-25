import 'package:flutter/material.dart';

import '../models/ai_models.dart';
import '../services/ai_service.dart';
import '../services/auth_storage.dart';

/// MEMBER 5 - AI Fan Helper
/// Keeps the assistant conversation, the starter suggestions and the
/// knowledge-base metadata.
///
/// The conversation lives in memory so the chat feels instant; the backend
/// additionally persists it in `ai_chat_messages` for signed-in users.
class AiProvider extends ChangeNotifier {
  // ----------------------------- state -----------------------------
  bool _loading = false;
  bool _sending = false;
  bool _clearing = false;
  String? _errorMessage;

  final List<AiMessage> _messages = [];
  List<AiSuggestion> _suggestions = [];
  List<AiTopicCount> _topics = [];

  String _greeting = "Hi! I'm your Fandom AI assistant. How can I help you?";
  bool _externalAiEnabled = false;
  String? _lastTopic;

  // ---------------------------- getters ----------------------------
  bool get loading => _loading;
  bool get sending => _sending;
  bool get clearing => _clearing;
  String? get errorMessage => _errorMessage;

  List<AiMessage> get messages => List.unmodifiable(_messages);
  List<AiSuggestion> get suggestions => _suggestions;
  List<AiTopicCount> get topics => _topics;
  String get greeting => _greeting;
  bool get externalAiEnabled => _externalAiEnabled;
  String? get lastTopic => _lastTopic;

  bool get hasConversation => _messages.any((message) => message.isUser);
  int get messageCount => _messages.length;

  /// Follow-up chips for the newest answer, shown above the input.
  List<String> get latestFollowUps {
    for (final message in _messages.reversed) {
      if (message.isAi && message.followUps.isNotEmpty) {
        return message.followUps;
      }
    }
    return const [];
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ==================================================================
  // LOADING
  // ==================================================================

  /// Loads the welcome message, starter chips and the topic list.
  /// Restores the persisted conversation when the user is signed in.
  Future<void> initialise({bool restoreHistory = true}) async {
    _loading = true;
    notifyListeners();

    final suggestionsResult = await AiService.suggestions();

    if (suggestionsResult.success && suggestionsResult.data != null) {
      final json = suggestionsResult.data!;

      _suggestions = (json['suggestions'] as List? ?? [])
          .whereType<Map>()
          .map((item) => AiSuggestion.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      _greeting = json['greeting']?.toString() ?? _greeting;
      _externalAiEnabled = json['external_ai_enabled'] == true;
      _errorMessage = null;
    } else {
      _errorMessage = suggestionsResult.message;
    }

    _topics = (await AiService.topics()).data ?? [];

    // Seed the chat with the welcome bubble when it is empty.
    if (_messages.isEmpty) {
      _messages.add(AiMessage.welcome(_greeting));
    }

    if (restoreHistory && await AuthStorage.isLoggedIn()) {
      final history = await AiService.history(limit: 40);

      if (history.success && history.data != null && history.data!.isNotEmpty) {
        // Replace the seeded welcome bubble with the real transcript.
        _messages
          ..clear()
          ..add(AiMessage.welcome(_greeting))
          ..addAll(
            history.data!.where((message) => message.message.isNotEmpty),
          );
      }
    }

    _loading = false;
    notifyListeners();
  }

  // ==================================================================
  // CHAT
  // ==================================================================

  /// Sends a question and appends both the user bubble and the reply.
  Future<AiReply?> send(String text) async {
    final question = text.trim();
    if (question.isEmpty || _sending) return null;
    _errorMessage = null;
    _messages.add(AiMessage(sender: 'user', message: question));
    _messages.add(AiMessage.thinking);
    _sending = true;
    notifyListeners();

    final result = await AiService.ask(question);

    // Remove the typing placeholder.
    _messages.removeWhere((message) => message.isPending);

    if (!result.success || result.data == null) {
      _errorMessage = result.message;
      _messages.add(
        AiMessage(
          sender: 'ai',
          message: "I couldn't reach the Fandom Verse assistant just now. Please check that the backend is running and try again.",
          topic: 'Error',
          source: 'fallback',
        ),
      );
      _sending = false;
      notifyListeners();
      return null;
    }

    final reply = result.data!;

    _messages.add(
      AiMessage(
        sender: 'ai',
        message: reply.reply,
        topic: reply.topic,
        source: reply.source,
        imageUrl: reply.imageUrl,
        followUps: reply.followUps,
        createdAgo: 'just now',
      ),
    );

    _lastTopic = reply.topic;
    _sending = false;
    notifyListeners();

    return reply;
  }

  /// Clears the conversation locally, and on the server when signed in.
  Future<String?> clearConversation() async {
    _clearing = true;
    notifyListeners();

    String? message;

    if (await AuthStorage.isLoggedIn()) {
      final result = await AiService.clearHistory();
      message = result.success ? result.data : result.message;
    }

    _messages
      ..clear()
      ..add(AiMessage.welcome(_greeting));

    _lastTopic = null;
    _clearing = false;
    notifyListeners();

    return message ?? 'Conversation cleared';
  }

  /// Called on logout so the next user does not see the previous transcript.
  void reset() {
    _messages
      ..clear()
      ..add(AiMessage.welcome(_greeting));
    _lastTopic = null;
    _errorMessage = null;
    notifyListeners();
  }
}
