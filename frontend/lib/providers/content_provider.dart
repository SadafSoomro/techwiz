import 'package:flutter/material.dart';

import '../models/content_models.dart';
import '../services/content_service.dart';

/// MEMBER 2 - Fandom Content
/// Holds the state used by the Fandom Hub, News, Gallery, Video Player,
/// Podcasts, Discover, Glossary and the recent / offline screens.
class ContentProvider extends ChangeNotifier {
  // ----------------------------- state -----------------------------
  bool _loadingHubs = false;
  bool _loadingHub = false;
  bool _loadingList = false;
  bool _loadingDiscover = false;
  bool _loadingRecent = false;
  String? _errorMessage;

  HubsBundle _hubs = const HubsBundle();
  HubBundle? _hubBundle;
  List<ContentItem> _items = [];
  DiscoverBundle _discover = const DiscoverBundle();
  RecentBundle _recent = const RecentBundle();
  OfflineBundle _offline = const OfflineBundle();
  List<GlossaryTerm> _glossary = [];

  // filters
  String _type = 'all';
  String _fandom = 'all';
  String _sort = 'latest';
  String _query = '';
  String _currentHubSlug = '';

  // ---------------------------- getters ----------------------------
  bool get loadingHubs => _loadingHubs;
  bool get loadingHub => _loadingHub;
  bool get loadingList => _loadingList;
  bool get loadingDiscover => _loadingDiscover;
  bool get loadingRecent => _loadingRecent;
  bool get loading => _loadingHubs || _loadingHub || _loadingList || _loadingDiscover;
  String? get errorMessage => _errorMessage;

  HubsBundle get hubs => _hubs;
  HubBundle? get hubBundle => _hubBundle;
  List<ContentItem> get items => _items;
  DiscoverBundle get discover => _discover;
  RecentBundle get recent => _recent;
  OfflineBundle get offline => _offline;
  List<GlossaryTerm> get glossary => _glossary;

  String get type => _type;
  String get fandom => _fandom;
  String get sort => _sort;
  String get query => _query;
  String get currentHubSlug => _currentHubSlug;

  // ---------------------------- helpers ----------------------------
  void _error(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Replaces an item everywhere it is currently held, so likes / offline
  /// flags stay in sync across every screen without a refetch.
  void _replace(ContentItem updated) {
    ContentItem apply(ContentItem item) => item.id == updated.id ? updated : item;

    _items = _items.map(apply).toList();
    _recent = RecentBundle(
      recent: _recent.recent.map(apply).toList(),
      offlineCount: _recent.offlineCount,
    );
    _offline = OfflineBundle(
      offline: _offline.offline.map((item) {
        final next = apply(item);
        return next;
      }).toList(),
      items: _offline.items,
      sizeMb: _offline.sizeMb,
    );
    _discover = DiscoverBundle(
      spotlight: _discover.spotlight?.id == updated.id
          ? updated
          : _discover.spotlight,
      trending: _discover.trending.map(apply).toList(),
      latest: _discover.latest.map(apply).toList(),
      collections: _discover.collections.map(apply).toList(),
    );
    if (_hubBundle != null) {
      final bundle = _hubBundle!;
      _hubBundle = HubBundle(
        hub: bundle.hub,
        news: bundle.news.map(apply).toList(),
        galleries: bundle.galleries.map(apply).toList(),
        videos: bundle.videos.map(apply).toList(),
        podcasts: bundle.podcasts.map(apply).toList(),
        deepDives: bundle.deepDives.map(apply).toList(),
        glossary: bundle.glossary,
      );
    }
    notifyListeners();
  }

  // ==================================================================
  // LOADERS
  // ==================================================================

  /// Explore Fandoms - hub cards + trending carousel.
  Future<void> loadHubs() async {
    _loadingHubs = true;
    notifyListeners();

    final result = await ContentService.hubs();
    if (result.success && result.data != null) {
      _hubs = result.data!;
      _errorMessage = null;
    } else {
      _errorMessage = result.message;
    }

    _loadingHubs = false;
    notifyListeners();
  }

  /// One Fandom Hub with all of its sections.
  Future<void> loadHub(String slug, {bool force = false}) async {
    if (!force && _currentHubSlug == slug && _hubBundle != null) return;

    _currentHubSlug = slug;
    _loadingHub = true;
    _hubBundle = null;
    notifyListeners();

    final result = await ContentService.hub(slug);
    if (result.success && result.data != null) {
      _hubBundle = result.data!;
      _errorMessage = null;
    } else {
      _errorMessage = result.message;
    }

    _loadingHub = false;
    notifyListeners();
  }

  /// Filtered list (News List, Gallery, Video list, Podcasts).
  Future<void> loadList({
    String? type,
    String? fandom,
    String? sort,
    String? query,
    bool reset = false,
  }) async {
    if (reset) {
      _items = [];
      _errorMessage = null;
    }
    if (type != null) _type = type;
    if (fandom != null) _fandom = fandom;
    if (sort != null) _sort = sort;
    if (query != null) _query = query;

    _loadingList = true;
    notifyListeners();

    final result = await ContentService.list(
      type: _type,
      fandom: _fandom,
      query: _query,
      sort: _sort,
      limit: 30,
    );

    if (result.success && result.data != null) {
      _items = result.data!;
      _errorMessage = null;
    } else {
      _errorMessage = result.message;
    }

    _loadingList = false;
    notifyListeners();
  }

  Future<void> setFilters({
    String? type,
    String? fandom,
    String? sort,
  }) async {
    _type = type ?? _type;
    _fandom = fandom ?? _fandom;
    _sort = sort ?? _sort;
    await loadList();
  }

  Future<void> search(String query) async {
    _query = query;
    await loadList(query: query);
  }

  /// Discover feed.
  Future<void> loadDiscover() async {
    _loadingDiscover = true;
    notifyListeners();

    final result = await ContentService.discover();
    if (result.success && result.data != null) {
      _discover = result.data!;
      _errorMessage = null;
    } else {
      _errorMessage = result.message;
    }

    _loadingDiscover = false;
    notifyListeners();
  }

  /// Recently viewed content (SQLite recent history).
  Future<void> loadRecent() async {
    _loadingRecent = true;
    notifyListeners();

    final result = await ContentService.recent();
    if (result.success && result.data != null) {
      _recent = result.data!;
      _errorMessage = null;
    } else {
      _errorMessage = result.message;
    }

    _loadingRecent = false;
    notifyListeners();
  }

  /// Content saved for offline access.
  Future<void> loadOffline() async {
    _loadingRecent = true;
    notifyListeners();

    final result = await ContentService.offline();
    if (result.success && result.data != null) {
      _offline = result.data!;
      _errorMessage = null;
    } else {
      _errorMessage = result.message;
    }

    _loadingRecent = false;
    notifyListeners();
  }

  /// Beginner fan hub glossary.
  Future<void> loadGlossary({String fandom = ''}) async {
    final result = await ContentService.glossary(fandom: fandom);
    if (result.success && result.data != null) {
      _glossary = result.data!;
      notifyListeners();
    }
  }

  /// Warm every section the Home / Discover screens need.
  Future<void> loadOverview() async {
    await Future.wait([
      loadHubs(),
      loadDiscover(),
    ]);
  }

  // ==================================================================
  // INTERACTIONS
  // ==================================================================

  /// Records a view so the item appears in "Recently viewed".
  Future<void> recordView(int id, {double progress = 0, bool? offline}) async {
    final result = await ContentService.recordView(id, progress: progress, offline: offline);
    if (result.success) {
      await loadRecent();
    }
  }

  /// Toggles "save for offline" and returns the new state.
  Future<bool> toggleOffline(ContentItem item) async {
    final result = await ContentService.toggleOffline(item.id);
    if (!result.success) {
      _error(result.message);
      return item.isOffline;
    }

    final next = result.data?['isOffline'] == true;
    _replace(item.copyWith(isOffline: next));
    await loadOffline();
    return next;
  }

  /// Toggles a like and returns the new state.
  Future<bool> toggleLike(ContentItem item) async {
    final result = await ContentService.toggleLike(item.id);
    if (!result.success) {
      _error(result.message);
      return item.isLiked;
    }

    final next = result.data?['isLiked'] == true;
    final count = result.data?['likesCount'] is num
        ? (result.data!['likesCount'] as num).toInt()
        : item.likesCount;

    _replace(item.copyWith(isLiked: next, likesCount: count));
    return next;
  }
}
