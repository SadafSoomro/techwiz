/// MEMBER 5 - AI Fan Helper
/// Data models for the fandom assistant chat.
library;

import 'json_utils.dart';

// ---------------------------------------------------------------------------
// AiMessage - one bubble in the conversation
// ---------------------------------------------------------------------------
class AiMessage {
  final int id;
  final String sender; // "user" | "ai"
  final String message;
  final String? topic;
  final String? source; // faq | catalogue | ai_api | smalltalk | fallback
  final String? imageUrl;
  final String createdAt;
  final String createdAgo;
  final List<String> followUps;

  /// True while the reply is still being fetched (drives the typing dots).
  final bool isPending;

  const AiMessage({
    this.id = 0,
    required this.sender,
    required this.message,
    this.topic,
    this.source,
    this.imageUrl,
    this.createdAt = '',
    this.createdAgo = '',
    this.followUps = const [],
    this.isPending = false,
  });

  bool get isUser => sender == 'user';
  bool get isAi => sender == 'ai';

  /// Human label for where the answer came from - shown as a small chip.
  String? get sourceLabel {
    switch (source) {
      case 'catalogue':
        return 'Live catalogue';
      case 'faq':
        return 'Fandom knowledge base';
      case 'ai_api':
        return 'AI API';
      case 'smalltalk':
        return null;
      default:
        return null;
    }
  }

  factory AiMessage.fromJson(Map<String, dynamic> json) {
    return AiMessage(
      id: asInt(json['id']),
      sender: asString(json['sender'], fallback: 'ai'),
      message: asString(json['message']),
      topic: asNullableString(json['topic']),
      source: asNullableString(json['source']),
      imageUrl: asNullableString(json['image_url']),
      createdAt: asString(json['created_at']),
      createdAgo: asString(json['created_ago']),
    );
  }

  /// The welcome bubble shown before the user asks anything.
  static AiMessage welcome(String greeting) => AiMessage(
    sender: 'ai',
    message: greeting,
    topic: 'Greeting',
    source: 'smalltalk',
  );

  /// Placeholder bubble rendered as animated typing dots.
  static const AiMessage thinking = AiMessage(
    sender: 'ai',
    message: '',
    isPending: true,
  );
}

// ---------------------------------------------------------------------------
// AiSuggestion - a tappable starter chip
// ---------------------------------------------------------------------------
class AiSuggestion {
  final String question;
  final String? topic;

  const AiSuggestion({required this.question, this.topic});

  factory AiSuggestion.fromJson(Map<String, dynamic> json) {
    return AiSuggestion(
      question: asString(json['question']),
      topic: asNullableString(json['topic']),
    );
  }
}

// ---------------------------------------------------------------------------
// AiTopicCount - knowledge base summary
// ---------------------------------------------------------------------------
class AiTopicCount {
  final String topic;
  final int count;

  const AiTopicCount({required this.topic, this.count = 0});

  factory AiTopicCount.fromJson(Map<String, dynamic> json) {
    return AiTopicCount(
      topic: asString(json['topic'], fallback: 'General'),
      count: asInt(json['count']),
    );
  }
}

// ---------------------------------------------------------------------------
// AiReply - the /api/ai/chat response
// ---------------------------------------------------------------------------
class AiReply {
  final String reply;
  final String? topic;
  final String source;
  final String? imageUrl;
  final List<String> followUps;
  final bool historySaved;

  const AiReply({
    required this.reply,
    this.topic,
    this.source = 'faq',
    this.imageUrl,
    this.followUps = const [],
    this.historySaved = false,
  });

  factory AiReply.fromJson(Map<String, dynamic> json) {
    return AiReply(
      reply: asString(json['reply']),
      topic: asNullableString(json['topic']),
      source: asString(json['source'], fallback: 'faq'),
      imageUrl: asNullableString(json['image_url']),
      followUps: (json['follow_ups'] is List)
          ? (json['follow_ups'] as List).map((item) => item.toString()).toList()
          : const [],
      historySaved: asBool(json['history_saved']),
    );
  }
}
