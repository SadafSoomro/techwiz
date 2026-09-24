import 'package:flutter/material.dart';
import '../models/community_models.dart';
import '../services/community_service.dart';

/// MEMBER 3 - Search & Community
/// Holds all state used by the Search, Trending, Discussions,
/// Bookmarks and Notifications screens.
class CommunityProvider extends ChangeNotifier {
  // ----------------------------- state -----------------------------
  bool _loading = false;
  String? _errorMessage;

  SearchBundle? _searchResults;
  String _searchQuery = '';
  String _searchType = 'all';
  String _searchFandom = '';
  String _searchSort = 'popular';

  List<String> _recentSearches = [];

  TrendingBundle? _trending;

  List<CommunityPost> _discussions = [];
  String _discussionSort = 'popular';
  String _discussionFandom = '';

  List<CommunityPost> _feed = [];

  List<CommunityPost> _bookmarks = [];

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;

  List<FandomCategory> _fandoms = const [];
  List<Map<String, String>> _sortOptions = const [];
  List<Map<String, String>> _contentTypes = const [];

  Map<String, dynamic> _overview = const {};

  // ---------------------------- getters ----------------------------
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  SearchBundle? get searchResults => _searchResults;
  String get searchQuery => _searchQuery;
  String get searchType => _searchType;
  String get searchFandom => _searchFandom;
  String get searchSort => _searchSort;
  List<String> get recentSearches => _recentSearches;

  TrendingBundle? get trending => _trending;

  List<CommunityPost> get discussions => _discussions;
  String get discussionSort => _discussionSort;
  String get discussionFandom => _discussionFandom;

  List<CommunityPost> get feed => _feed;

  List<CommunityPost> get bookmarks => _bookmarks;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  List<FandomCategory> get fandoms => _fandoms;
  List<Map<String, String>> get sortOptions => _sortOptions;
  List<Map<String, String>> get contentTypes => _contentTypes;

  Map<String, dynamic> get overview => _overview;

  // ---------------------------- helpers ----------------------------
  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Keeps every list in sync after a like / bookmark change.
  void _replacePost(CommunityPost updated) {
    List<CommunityPost> mapList(List<CommunityPost> list) => list
        .map((p) => p.id == updated.id ? p.copyWith(
              likesCount: updated.likesCount,
              commentsCount: updated.commentsCount,
              isLiked: updated.isLiked,
              isBookmarked: updated.isBookmarked,
            ) : p)
        .toList();

    _feed = mapList(_feed);
    _discussions = mapList(_discussions);
    _bookmarks = mapList(_bookmarks);

    final results = _searchResults;
    if (results != null) {
      _searchResults = SearchBundle(
        query: results.query,
        users: results.users,
        fandoms: results.fandoms,
        posts: mapList(results.posts),
      );
    }

    final trendingBundle = _trending;
    if (trendingBundle != null) {
      _trending = TrendingBundle(
        hashtags: trendingBundle.hashtags,
        users: trendingBundle.users,
        fandoms: trendingBundle.fandoms,
        posts: mapList(trendingBundle.posts),
        deepDives: mapList(trendingBundle.deepDives),
      );
    }
  }

  // ==================================================================
  // FILTERS
  // ==================================================================
  Future<void> loadFilters() async {
    final result = await CommunityService.filters();
    final data = result.data;
    if (result.success && data != null) {
      _fandoms = (data['fandoms'] as List? ?? [])
          .whereType<Map>()
          .map((e) => FandomCategory.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      _sortOptions = (data['sortOptions'] as List? ?? [])
          .whereType<Map>()
          .map((e) => {
                'key': e['key'].toString(),
                'label': e['label'].toString(),
              })
          .toList();

      _contentTypes = (data['contentTypes'] as List? ?? [])
          .whereType<Map>()
          .map((e) => {
                'key': e['key'].toString(),
                'label': e['label'].toString(),
              })
          .toList();

      notifyListeners();
    }
  }

  // ==================================================================
  // SEARCH
  // ==================================================================
  Future<void> runSearch({
    String? query,
    String? type,
    String? fandom,
    String? sort,
  }) async {
    _searchQuery = query ?? _searchQuery;
    _searchType = type ?? _searchType;
    _searchFandom = fandom ?? _searchFandom;
    _searchSort = sort ?? _searchSort;

    _setLoading(true);
    _errorMessage = null;

    final result = await CommunityService.search(
      query: _searchQuery,
      type: _searchType,
      fandom: _searchFandom == 'All' ? '' : _searchFandom,
      sort: _searchSort,
    );

    if (result.success && result.data != null) {
      _searchResults = result.data;
      if (_searchQuery.trim().isNotEmpty &&
          !_recentSearches.contains(_searchQuery.trim())) {
        _recentSearches = [_searchQuery.trim(), ..._recentSearches].take(6).toList();
      }
    } else {
      _errorMessage = result.message;
    }

    _setLoading(false);
  }

  void clearSearchResults() {
    _searchResults = null;
    _searchQuery = '';
    notifyListeners();
  }

  Future<List<String>> suggestions(String query) async {
    if (query.trim().isEmpty) return [];
    final result = await CommunityService.suggestions(query.trim());
    final data = result.data;
    if (!result.success || data == null) return [];

    final suggestions = (data['suggestions'] as List? ?? [])
        .whereType<Map>()
        .map((e) => e['name'].toString())
        .toList();

    _recentSearches = (data['recent'] as List? ?? [])
        .map((e) => e.toString())
        .take(6)
        .toList();

    return suggestions;
  }

  // ==================================================================
  // TRENDING
  // ==================================================================
  Future<void> loadTrending() async {
    _setLoading(true);
    final result = await CommunityService.trending();
    if (result.success && result.data != null) {
      _trending = result.data;
    } else {
      _errorMessage = result.message;
    }
    _setLoading(false);
  }

  // ==================================================================
  // FEED + DISCUSSIONS
  // ==================================================================
  Future<void> loadFeed({String type = '', String fandom = '', String sort = 'newest'}) async {
    _setLoading(true);
    final result = await CommunityService.posts(type: type, fandom: fandom, sort: sort);
    if (result.success && result.data != null) {
      _feed = result.data!;
    } else {
      _errorMessage = result.message;
    }
    _setLoading(false);
  }

  Future<void> loadDiscussions({String? sort, String? fandom, String query = ''}) async {
    _discussionSort = sort ?? _discussionSort;
    _discussionFandom = fandom ?? _discussionFandom;

    _setLoading(true);
    final result = await CommunityService.discussions(
      sort: _discussionSort,
      fandom: _discussionFandom == 'All' ? '' : _discussionFandom,
      query: query,
    );
    if (result.success && result.data != null) {
      _discussions = result.data!;
    } else {
      _errorMessage = result.message;
    }
    _setLoading(false);
  }

  Future<CommunityResult<CommunityPost>> createPost({
    required String title,
    required String content,
    required String fandom,
    required List<String> hashtags,
    required bool deepDive,
    int rating = 0,
  }) async {
    _setLoading(true);
    final result = await CommunityService.createPost(
      title: title,
      content: content,
      fandom: fandom,
      hashtags: hashtags,
      deepDive: deepDive,
      rating: rating,
    );

    if (result.success && result.data != null) {
      final post = result.data!;
      if (post.isDeepDive) {
        _discussions = [post, ..._discussions];
      } else {
        _feed = [post, ..._feed];
      }
    } else {
      _errorMessage = result.message;
    }

    _setLoading(false);
    return result;
  }

  Future<CommunityResult<bool>> deletePost(int id) async {
    final result = await CommunityService.deletePost(id);
    if (result.success) {
      _discussions = _discussions.where((p) => p.id != id).toList();
      _feed = _feed.where((p) => p.id != id).toList();
      _bookmarks = _bookmarks.where((p) => p.id != id).toList();
      notifyListeners();
    }
    return result;
  }

  // ==================================================================
  // LIKE / BOOKMARK
  // ==================================================================
  Future<CommunityResult<List<int>>> toggleLike(CommunityPost post) async {
    final result = await CommunityService.toggleLike(post.id);
    if (result.success && result.data != null) {
      _replacePost(post.copyWith(
        isLiked: result.data![0] == 1,
        likesCount: result.data![1],
      ));
      notifyListeners();
    }
    return result;
  }

  Future<CommunityResult<List<int>>> toggleBookmark(CommunityPost post) async {
    final result = await CommunityService.toggleBookmark(post.id);
    if (result.success && result.data != null) {
      _replacePost(post.copyWith(isBookmarked: result.data![0] == 1));
      await loadBookmarks(silent: true);
      notifyListeners();
    }
    return result;
  }

  // ==================================================================
  // BOOKMARKS (Saved Posts)
  // ==================================================================
  Future<void> loadBookmarks({bool silent = false}) async {
    if (!silent) _setLoading(true);
    final result = await CommunityService.bookmarks();
    if (result.success && result.data != null) {
      _bookmarks = result.data!;
    } else if (!silent) {
      _errorMessage = result.message;
    }
    if (!silent) _setLoading(false);
    notifyListeners();
  }

  Future<CommunityResult<bool>> clearBookmarks() async {
    final result = await CommunityService.clearBookmarks();
    if (result.success) {
      _bookmarks = [];
      notifyListeners();
    }
    return result;
  }

  // ==================================================================
  // NOTIFICATIONS
  // ==================================================================
  Future<void> loadNotifications({String filter = 'all'}) async {
    _setLoading(true);
    final result = await CommunityService.notifications(filter: filter);
    final data = result.data;
    if (result.success && data != null) {
      _notifications = (data['notifications'] as List? ?? [])
          .whereType<Map>()
          .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _unreadCount = (data['unread_count'] as num?)?.toInt() ?? 0;
    } else {
      _errorMessage = result.message;
    }
    _setLoading(false);
  }

  Future<void> markAllRead() async {
    final result = await CommunityService.markAllNotificationsRead();
    if (result.success) {
      _notifications =
          _notifications.map((n) => _copyNotification(n, isRead: true)).toList();
      _unreadCount = 0;
      notifyListeners();
    }
  }

  Future<void> markRead(AppNotification notification) async {
    if (notification.isRead) return;
    final result = await CommunityService.markNotificationRead(notification.id);
    if (result.success) {
      _notifications = _notifications
          .map((n) => n.id == notification.id ? _copyNotification(n, isRead: true) : n)
          .toList();
      _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
      notifyListeners();
    }
  }

  Future<void> removeNotification(AppNotification notification) async {
    final result = await CommunityService.deleteNotification(notification.id);
    if (result.success) {
      _notifications = _notifications.where((n) => n.id != notification.id).toList();
      if (!notification.isRead && _unreadCount > 0) _unreadCount--;
      notifyListeners();
    }
  }

  AppNotification _copyNotification(AppNotification n, {required bool isRead}) {
    return AppNotification(
      id: n.id,
      type: n.type,
      message: n.message,
      referenceId: n.referenceId,
      isRead: isRead,
      createdAgo: n.createdAgo,
      actorName: n.actorName,
      actorAvatar: n.actorAvatar,
    );
  }

  /// Refreshes the unread badge shown on the Home screen bell icon.
  Future<void> refreshUnreadCount() async {
    final result = await CommunityService.notifications();
    final data = result.data;
    if (result.success && data != null) {
      _unreadCount = (data['unread_count'] as num?)?.toInt() ?? 0;
      notifyListeners();
    }
  }

  // ==================================================================
  // FOLLOW
  // ==================================================================
  Future<CommunityResult<List<int>>> toggleFollow(CommunityUser user) async {
    final result = await CommunityService.toggleFollow(user.id);
    if (result.success && result.data != null) {
      _trending = _trending == null
          ? null
          : TrendingBundle(
              hashtags: _trending!.hashtags,
              fandoms: _trending!.fandoms,
              posts: _trending!.posts,
              deepDives: _trending!.deepDives,
              users: _trending!.users
                  .map((u) => u.id == user.id
                      ? u.copyWith(
                          isFollowing: result.data![0] == 1,
                          followersCount: result.data![1],
                        )
                      : u)
                  .toList(),
            );

      final results = _searchResults;
      if (results != null) {
        _searchResults = SearchBundle(
          query: results.query,
          posts: results.posts,
          fandoms: results.fandoms,
          users: results.users
              .map((u) => u.id == user.id
                  ? u.copyWith(
                      isFollowing: result.data![0] == 1,
                      followersCount: result.data![1],
                    )
                  : u)
              .toList(),
        );
      }
      notifyListeners();
    }
    return result;
  }

  // ==================================================================
  // OVERVIEW
  // ==================================================================
  Future<void> loadOverview() async {
    final result = await CommunityService.overview();
    if (result.success && result.data != null) {
      _overview = result.data!;
      notifyListeners();
    }
  }
}
