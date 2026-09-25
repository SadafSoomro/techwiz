import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/community_models.dart';
import 'auth_storage.dart';

/// MEMBER 3 - Search & Community
/// Thin HTTP layer over the /api/search, /api/posts and /api/community routes.
/// The JWT saved by the login flow is attached automatically.
class CommunityResult<T> {
  final bool success;
  final String message;
  final T? data;

  CommunityResult({required this.success, required this.message, this.data});

  factory CommunityResult.failure(String message) =>
      CommunityResult(success: false, message: message);
}

class CommunityService {
  // ------------------------------------------------------------------
  // low level helpers
  // ------------------------------------------------------------------
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
    Map<String, dynamic>? query,
  }) async {
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
      case 'DELETE':
        response = await http.delete(uri, headers: headers, body: encoded);
        break;
      default:
        response = await http.get(uri, headers: headers);
    }

    if (response.body.isEmpty) {
      return {'success': false, 'message': 'Empty response from server'};
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static List<T> _parseList<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) parser,
  ) {
    if (raw is! List) return <T>[];
    return raw
        .whereType<Map>()
        .map((e) => parser(Map<String, dynamic>.from(e)))
        .toList();
  }

  // ==================================================================
  // SEARCH
  // ==================================================================

  /// Keyword search across users / posts / fandoms.
  static Future<CommunityResult<SearchBundle>> search({
    String query = '',
    String type = 'all',
    String fandom = '',
    String sort = 'popular',
    int limit = 20,
  }) async {
    try {
      final json = await _send('GET', ApiConfig.searchUrl, query: {
        'q': query,
        'type': type,
        'fandom': fandom,
        'sort': sort,
        'limit': limit,
      });

      if (json?['success'] == true) {
        return CommunityResult(
          success: true,
          message: 'OK',
          data: SearchBundle.fromJson(json!),
        );
      }
      return CommunityResult.failure(json?['message'] ?? 'Search failed');
    } catch (e) {
      return CommunityResult.failure('Unable to reach the server. ($e)');
    }
  }

  /// Live autocomplete suggestions + recent searches.
  static Future<CommunityResult<Map<String, dynamic>>> suggestions(
    String query,
  ) async {
    try {
      final json = await _send('GET', ApiConfig.searchSuggestionsUrl,
          query: {'q': query});
      if (json?['success'] == true) {
        return CommunityResult(success: true, message: 'OK', data: json);
      }
      return CommunityResult.failure('No suggestions');
    } catch (e) {
      return CommunityResult.failure('Network error ($e)');
    }
  }

  /// Filter chips + sort options (Popular / Newest / Top / Trending).
  static Future<CommunityResult<Map<String, dynamic>>> filters() async {
    try {
      final json = await _send('GET', ApiConfig.searchFiltersUrl);
      if (json?['success'] == true) {
        return CommunityResult(success: true, message: 'OK', data: json);
      }
      return CommunityResult.failure('Could not load filters');
    } catch (e) {
      return CommunityResult.failure('Network error ($e)');
    }
  }

  static Future<CommunityResult<TrendingBundle>> trending() async {
    try {
      final json = await _send('GET', ApiConfig.searchTrendingUrl);
      if (json?['success'] == true) {
        return CommunityResult(
          success: true,
          message: 'OK',
          data: TrendingBundle.fromJson(json!),
        );
      }
      return CommunityResult.failure(json?['message'] ?? 'Could not load trending');
    } catch (e) {
      return CommunityResult.failure('Network error ($e)');
    }
  }

  static Future<CommunityResult<int>> searchHistory() async {
    try {
      final json = await _send('GET', ApiConfig.searchHistoryUrl);
      if (json?['success'] == true) {
        final history = json!['history'];
        final count = history is List ? history.length : 0;
        return CommunityResult(success: true, message: 'OK', data: count);
      }
      return CommunityResult.failure('Could not load history');
    } catch (e) {
      return CommunityResult.failure('Network error ($e)');
    }
  }

  // ==================================================================
  // POSTS / DISCUSSIONS
  // ==================================================================

  /// Feed. Pass [type] as 'post' or 'deep_dive'.
  static Future<CommunityResult<List<CommunityPost>>> posts({
    String type = '',
    String fandom = '',
    String sort = 'newest',
    String query = '',
    int? userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final json = await _send('GET', ApiConfig.postsUrl, query: {
        'type': type,
        'fandom': fandom,
        'sort': sort,
        'q': query,
        'limit': limit,
        'offset': offset,
        'user_id': ?userId,
      });

      if (json?['success'] == true) {
        return CommunityResult(
          success: true,
          message: 'OK',
          data: _parseList(json!['posts'], CommunityPost.fromJson),
        );
      }
      return CommunityResult.failure(json?['message'] ?? 'Could not load posts');
    } catch (e) {
      return CommunityResult.failure('Network error ($e)');
    }
  }

  /// Deep Dive discussions with sorting (Popular / Newest / Top / Trending).
  static Future<CommunityResult<List<CommunityPost>>> discussions({
    String sort = 'popular',
    String fandom = '',
    String query = '',
    int limit = 20,
  }) async {
    try {
      final json = await _send('GET', ApiConfig.discussionsUrl, query: {
        'sort': sort,
        'fandom': fandom,
        'q': query,
        'limit': limit,
      });

      if (json?['success'] == true) {
        return CommunityResult(
          success: true,
          message: 'OK',
          data: _parseList(json!['posts'], CommunityPost.fromJson),
        );
      }
      return CommunityResult.failure(json?['message'] ?? 'Could not load discussions');
    } catch (e) {
      return CommunityResult.failure('Network error ($e)');
    }
  }

  /// Single post + its comments.
  static Future<CommunityResult<Map<String, dynamic>>> postDetails(int id) async {
    try {
      final json = await _send('GET', ApiConfig.postDetailsUrl(id));
      if (json?['success'] == true) {
        return CommunityResult(success: true, message: 'OK', data: json);
      }
      return CommunityResult.failure(json?['message'] ?? 'Post not found');
    } catch (e) {
      return CommunityResult.failure('Network error ($e)');
    }
  }

  /// Creates a community post or a Deep Dive discussion.
  static Future<CommunityResult<CommunityPost>> createPost({
    required String title,
    required String content,
    String fandom = 'Anime',
    List<String> hashtags = const [],
    String? imageUrl,
    bool deepDive = false,
    int rating = 0,
  }) async {
    try {
      final json = await _send('POST', ApiConfig.postsUrl, body: {
        'title': title,
        'content': content,
        'fandom_category': fandom,
        'hashtags': hashtags.join(','),
        'image_url': imageUrl,
        'post_type': deepDive ? 'deep_dive' : 'post',
        'rating': rating,
      });

      if (json?['success'] == true) {
        return CommunityResult(
          success: true,
          message: json!['message'] ?? 'Post created',
          data: CommunityPost.fromJson(Map<String, dynamic>.from(json['post'])),
        );
      }
      return CommunityResult.failure(json?['message'] ?? 'Could not create post');
    } catch (e) {
      return CommunityResult.failure('Network error ($e)');
    }
  }

  static Future<CommunityResult<bool>> deletePost(int id) async {
    try {
      final json = await _send('DELETE', ApiConfig.postDetailsUrl(id));
      if (json?['success'] == true) {
        return CommunityResult(success: true, message: json!['message'] ?? 'Deleted', data: true);
      }
      return CommunityResult.failure(json?['message'] ?? 'Could not delete post');
    } catch (e) {
      return CommunityResult.failure('Network error ($e)');
    }
  }

  /// Toggle like -> returns [liked, likesCount].
  static Future<CommunityResult<List<int>>> toggleLike(int postId) async {
    try {
      final json = await _send('POST', ApiConfig.postLikeUrl(postId));
      if (json?['success'] == true) {
        return CommunityResult(
          success: true,
          message: json!['message'] ?? '',
          data: [
            json['liked'] == true ? 1 : 0,
            (json['likes_count'] as num?)?.toInt() ?? 0,
          ],
        );
      }
      return CommunityResult.failure(json?['message'] ?? 'Could not update like');
    } catch (e) {
      return CommunityResult.failure('Network error ($e)');
    }
  }

  // ==================================================================
  // COMMENTS
  // ==================================================================

  static Future<CommunityResult<List<PostComment>>> comments(int postId) async {
    try {
      final json = await _send('GET', ApiConfig.postCommentsUrl(postId));
      if (json?['success'] == true) {
        return CommunityResult(
          success: true,
          message: 'OK',
          data: _parseList(json!['comments'], PostComment.fromJson),
        );
      }
      return CommunityResult.failure(json?['message'] ?? 'Could not load comments');
    } catch (e) {
      return CommunityResult.failure('Network error ($e)');
    }
  }

  static Future<CommunityResult<PostComment>> addComment(
    int postId,
    String body,
  ) async {
    try {
      final json = await _send('POST', ApiConfig.postCommentsUrl(postId),
          body: {'body': body});
      if (json?['success'] == true) {
        return CommunityResult(
          success: true,
          message: json!['message'] ?? 'Comment added',
          data: PostComment.fromJson(Map<String, dynamic>.from(json['comment'])),
        );
      }
      return CommunityResult.failure(json?['message'] ?? 'Could not add comment');
    } catch (e) {
      return CommunityResult.failure('Network error ($e)');
    }
  }

  // ==================================================================
  // BOOKMARKS (Saved Posts)
  // ==================================================================

  static Future<CommunityResult<List<CommunityPost>>> bookmarks() async {
    try {
      final json = await _send('GET', ApiConfig.bookmarksUrl);
      if (json?['success'] == true) {
        return CommunityResult(
          success: true,
          message: 'OK',
          data: _parseList(json!['bookmarks'], CommunityPost.fromJson),
        );
      }
      return CommunityResult.failure(json?['message'] ?? 'Could not load bookmarks');
    } catch (e) {
      return CommunityResult.failure('Network error ($e)');
    }
  }

  /// Toggle save -> returns [bookmarked, totalBookmarks].
  static Future<CommunityResult<List<int>>> toggleBookmark(int postId) async {
    try {
      final json = await _send('POST', ApiConfig.toggleBookmarkUrl(postId));
      if (json?['success'] == true) {
        return CommunityResult(
          success: true,
          message: json!['message'] ?? '',
          data: [
            json['bookmarked'] == true ? 1 : 0,
            (json['total_bookmarks'] as num?)?.toInt() ?? 0,
          ],
        );
      }
      return CommunityResult.failure(json?['message'] ?? 'Could not update bookmark');
    } catch (e) {
      return CommunityResult.failure('Network error ($e)');
    }
  }

  static Future<CommunityResult<bool>> clearBookmarks() async {
    try {
      final json = await _send('DELETE', ApiConfig.bookmarksUrl);
      if (json?['success'] == true) {
        return CommunityResult(success: true, message: json!['message'] ?? 'Cleared', data: true);
      }
      return CommunityResult.failure(json?['message'] ?? 'Could not clear bookmarks');
    } catch (e) {
      return CommunityResult.failure('Network error ($e)');
    }
  }

  // ==================================================================
  // FOLLOW / USER PROFILE
  // ==================================================================

  static Future<CommunityResult<Map<String, dynamic>>> userProfile(int userId) async {
    try {
      final json = await _send('GET', ApiConfig.userProfileUrl(userId));
      if (json?['success'] == true) {
        return CommunityResult(success: true, message: 'OK', data: json);
      }
      return CommunityResult.failure(json?['message'] ?? 'User not found');
    } catch (e) {
      return CommunityResult.failure('Network error ($e)');
    }
  }

  /// Toggle follow -> returns [following, followersCount].
  static Future<CommunityResult<List<int>>> toggleFollow(int userId) async {
    try {
      final json = await _send('POST', ApiConfig.toggleFollowUrl(userId));
      if (json?['success'] == true) {
        return CommunityResult(
          success: true,
          message: json!['message'] ?? '',
          data: [
            json['following'] == true ? 1 : 0,
            (json['followers_count'] as num?)?.toInt() ?? 0,
          ],
        );
      }
      return CommunityResult.failure(json?['message'] ?? 'Could not update follow');
    } catch (e) {
      return CommunityResult.failure('Network error ($e)');
    }
  }

  static Future<CommunityResult<List<CommunityUser>>> followers(int userId) async {
    return _peopleList(ApiConfig.followersUrl(userId), 'followers');
  }

  static Future<CommunityResult<List<CommunityUser>>> following(int userId) async {
    return _peopleList(ApiConfig.followingUrl(userId), 'following');
  }

  static Future<CommunityResult<List<CommunityUser>>> _peopleList(
    String url,
    String key,
  ) async {
    try {
      final json = await _send('GET', url);
      if (json?['success'] == true) {
        return CommunityResult(
          success: true,
          message: 'OK',
          data: _parseList(json![key], CommunityUser.fromJson),
        );
      }
      return CommunityResult.failure(json?['message'] ?? 'Could not load list');
    } catch (e) {
      return CommunityResult.failure('Network error ($e)');
    }
  }

  // ==================================================================
  // NOTIFICATIONS
  // ==================================================================

  static Future<CommunityResult<Map<String, dynamic>>> notifications({
    String filter = 'all',
  }) async {
    try {
      final json = await _send('GET', ApiConfig.notificationsUrl,
          query: {'filter': filter});
      if (json?['success'] == true) {
        return CommunityResult(success: true, message: 'OK', data: json);
      }
      return CommunityResult.failure(json?['message'] ?? 'Could not load notifications');
    } catch (e) {
      return CommunityResult.failure('Network error ($e)');
    }
  }

  static Future<CommunityResult<bool>> markAllNotificationsRead() async {
    try {
      final json = await _send('POST', ApiConfig.markAllNotificationsReadUrl);
      if (json?['success'] == true) {
        return CommunityResult(success: true, message: json!['message'] ?? 'Updated', data: true);
      }
      return CommunityResult.failure(json?['message'] ?? 'Could not update');
    } catch (e) {
      return CommunityResult.failure('Network error ($e)');
    }
  }

  static Future<CommunityResult<bool>> markNotificationRead(int id) async {
    try {
      final json = await _send('POST', ApiConfig.markNotificationReadUrl(id));
      if (json?['success'] == true) {
        return CommunityResult(success: true, message: 'Read', data: true);
      }
      return CommunityResult.failure(json?['message'] ?? 'Could not update');
    } catch (e) {
      return CommunityResult.failure('Network error ($e)');
    }
  }

  static Future<CommunityResult<bool>> deleteNotification(int id) async {
    try {
      final json = await _send('DELETE', ApiConfig.deleteNotificationUrl(id));
      if (json?['success'] == true) {
        return CommunityResult(success: true, message: 'Deleted', data: true);
      }
      return CommunityResult.failure(json?['message'] ?? 'Could not delete');
    } catch (e) {
      return CommunityResult.failure('Network error ($e)');
    }
  }

  // ==================================================================
  // OVERVIEW (community dashboard card)
  // ==================================================================

  static Future<CommunityResult<Map<String, dynamic>>> overview() async {
    try {
      final json = await _send('GET', ApiConfig.communityOverviewUrl);
      if (json?['success'] == true) {
        return CommunityResult(success: true, message: 'OK', data: json);
      }
      return CommunityResult.failure(json?['message'] ?? 'Could not load overview');
    } catch (e) {
      return CommunityResult.failure('Network error ($e)');
    }
  }
}
