import 'package:flutter/material.dart';

import '../models/content_models.dart';
import '../models/profile_models.dart';
import '../services/auth_storage.dart';
import '../services/profile_service.dart';

/// MEMBER 1 - Profile, Fandom Selection & Home
/// Holds the profile, fandom selection, badges, tasks, invite and settings
/// state, plus the aggregated Home Dashboard.
class ProfileProvider extends ChangeNotifier {
  // ----------------------------- state -----------------------------
  bool _loading = false;
  bool _saving = false;
  String? _errorMessage;

  HomeDashboard? _dashboard;
  ProfileBundle? _bundle;

  List<FandomOption> _fandoms = [];
  Set<String> _selected = {};
  bool _fandomSelectionLoaded = false;

  BadgeBundle? _badges;
  TasksBundle? _tasks;
  InviteInfo? _invite;
  UserSettings _settings = const UserSettings();
  List<String> _avatars = [];

  List<String> _recentBadges = [];

  // ---------------------------- getters ----------------------------
  bool get loading => _loading;
  bool get saving => _saving;
  String? get errorMessage => _errorMessage;

  HomeDashboard? get dashboard => _dashboard;
  ProfileBundle? get bundle => _bundle;
  ProfileUser? get user => _dashboard?.user ?? _bundle?.user;

  List<FandomOption> get fandoms => _fandoms;
  Set<String> get selected => _selected;
  bool get hasSelectedFandoms => _selected.isNotEmpty;
  bool get fandomSelectionLoaded => _fandomSelectionLoaded;

  BadgeBundle? get badges => _badges;
  TasksBundle? get tasks => _tasks;
  InviteInfo? get invite => _invite;
  UserSettings get settings => _settings;
  List<String> get avatars => _avatars;
  List<String> get recentBadges => _recentBadges;

  List<ProfileBadge> get earnedBadges =>
      (_dashboard?.badges ?? _bundle?.badges ?? const <ProfileBadge>[])
          .where((b) => b.isEarned || b.awardedAt.isNotEmpty)
          .toList();

  ProfileStats get stats =>
      _dashboard?.stats ?? _bundle?.stats ?? const ProfileStats();

  int get completion => _dashboard?.completion ?? _bundle?.completion ?? 0;

  // ---------------------------- helpers ----------------------------
  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void _setSaving(bool value) {
    _saving = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearRecentBadges() {
    _recentBadges = [];
  }

  // ==================================================================
  // LOADERS
  // ==================================================================

  /// Home Dashboard aggregate (the cached /profile/home payload).
  Future<void> loadDashboard({bool refresh = false}) async {
    if (_dashboard != null && !refresh) return;

    _setLoading(true);
    final result = await ProfileService.dashboard();

    if (result.success && result.data != null) {
      _dashboard = result.data;
      _errorMessage = null;
      // Keep the fandom selection in sync with the dashboard payload.
      if (_selected.isEmpty) {
        _selected = _dashboard!.fandoms.map((f) => f.name).toSet();
      }
    } else {
      _errorMessage = result.message;
    }

    _setLoading(false);
  }

  /// Profile + stats + badges + tasks.
  Future<void> loadProfile() async {
    _setLoading(true);
    final result = await ProfileService.me();

    if (result.success && result.data != null) {
      _bundle = result.data;
      _errorMessage = null;
      _selected = result.data!.fandoms.map((f) => f.name).toSet();
      if (result.data!.newBadges.isNotEmpty) {
        _recentBadges = result.data!.newBadges;
      }
    } else {
      _errorMessage = result.message;
    }

    _setLoading(false);
  }

  /// Fandom catalogue + the user's current selection.
  Future<void> loadFandoms() async {
    _fandomSelectionLoaded = false;
    notifyListeners();

    final result = await ProfileService.fandoms();

    if (result.success && result.data != null) {
      _fandoms = result.data!.fandoms;
      _selected = result.data!.selected.toSet();
      _errorMessage = null;
    } else {
      _errorMessage = result.message;
    }

    _fandomSelectionLoaded = true;
    notifyListeners();
  }

  /// Avatar presets for Edit Profile.
  Future<void> loadAvatars() async {
    final result = await ProfileService.avatars();
    if (result.success && result.data != null) {
      _avatars = result.data!;
      notifyListeners();
    }
  }

  Future<void> loadBadges() async {
    _setLoading(true);
    final result = await ProfileService.badges();

    if (result.success && result.data != null) {
      _badges = result.data;
      _errorMessage = null;
    } else {
      _errorMessage = result.message;
    }

    _setLoading(false);
  }

  Future<void> loadTasks() async {
    _setLoading(true);
    final result = await ProfileService.tasks();

    if (result.success && result.data != null) {
      _tasks = result.data;
      _errorMessage = null;
    } else {
      _errorMessage = result.message;
    }

    _setLoading(false);
  }

  Future<void> loadInvite() async {
    _setLoading(true);
    final result = await ProfileService.invite();

    if (result.success && result.data != null) {
      _invite = result.data;
      _errorMessage = null;
    } else {
      _errorMessage = result.message;
    }

    _setLoading(false);
  }

  Future<void> loadSettings() async {
    _setLoading(true);
    final result = await ProfileService.settings();

    if (result.success && result.data != null) {
      final raw = result.data!['settings'];
      if (raw is Map) {
        _settings = UserSettings.fromJson(Map<String, dynamic>.from(raw));
      }
      _errorMessage = null;
    } else {
      _errorMessage = result.message;
    }

    _setLoading(false);
  }

  // ==================================================================
  // FANDOM SELECTION
  // ==================================================================

  void toggleFandom(String name) {
    if (_selected.contains(name)) {
      _selected.remove(name);
    } else {
      _selected.add(name);
    }
    notifyListeners();
  }

  void selectAllFandoms() {
    _selected = _fandoms.map((f) => f.name).toSet();
    notifyListeners();
  }

  void clearFandomSelection() {
    _selected = {};
    notifyListeners();
  }

  /// Saves the Fandom Selection screen. Returns the API message.
  Future<String?> saveFandoms({bool skipped = false}) async {
    _setSaving(true);
    final result = await ProfileService.saveFandoms(_selected.toList(), skipped: skipped);

    if (result.success) {
      final newBadges = result.data?['newBadges'];
      if (newBadges is List && newBadges.isNotEmpty) {
        _recentBadges = newBadges.map((b) => b.toString()).toList();
      }
      _errorMessage = null;
    } else {
      _errorMessage = result.message;
    }

    _setSaving(false);
    if (result.success) await loadDashboard(refresh: true);
    return result.success ? result.message : null;
  }

  // ==================================================================
  // PROFILE EDIT
  // ==================================================================

  /// Edit Profile - name / bio / avatar (and public visibility).
  Future<String?> updateProfile({
    String? name,
    String? bio,
    String? avatar,
    bool? isPublic,
  }) async {
    _setSaving(true);
    final result = await ProfileService.updateProfile(
      name: name,
      bio: bio,
      avatar: avatar,
      isPublic: isPublic,
    );

    if (result.success && result.data != null) {
      _bundle = result.data;
      if (result.data!.newBadges.isNotEmpty) {
        _recentBadges = result.data!.newBadges;
      }
      _errorMessage = null;

      // Keep the persisted session (used by the app header) up to date.
      final token = await AuthStorage.getToken();
      if (token != null) {
        await AuthStorage.saveSession(token, {
          'id': result.data!.user.id,
          'name': result.data!.user.name,
          'email': result.data!.user.email,
        });
      }
      await loadDashboard(refresh: true);
    } else {
      _errorMessage = result.message;
    }

    _setSaving(false);
    return result.success ? result.message : null;
  }

  // ==================================================================
  // BADGES / TASKS / INVITE / SETTINGS
  // ==================================================================

  /// Completes a social task once. Returns the API message.
  Future<String?> completeTask(String code) async {
    final result = await ProfileService.completeTask(code);

    if (result.success) {
      final newBadges = result.data?['newBadges'];
      if (newBadges is List && newBadges.isNotEmpty) {
        _recentBadges = newBadges.map((b) => b.toString()).toList();
      }
      await loadTasks();
      await loadDashboard(refresh: true);
      return result.message;
    }

    _errorMessage = result.message;
    notifyListeners();
    return null;
  }

  Future<String?> claimInvite(String code) async {
    final result = await ProfileService.claimInvite(code);
    if (result.success) {
      await loadInvite();
      return result.message;
    }
    _errorMessage = result.message;
    notifyListeners();
    return null;
  }

  /// Applies a settings change instantly in the UI, then persists it.
  Future<void> updateSettings(UserSettings next) async {
    final previous = _settings;
    _settings = next;
    notifyListeners();

    final result = await ProfileService.updateSettings(next);
    if (!result.success) {
      _settings = previous;
      _errorMessage = result.message;
      notifyListeners();
    }
  }

  /// Track a content item as viewed (keeps "Continue watching" fresh).
  void noteContentViewed(ContentItem item) {
    if (_dashboard == null) return;
    final list = [..._dashboard!.continueWatching];
    list.removeWhere((element) => element.id == item.id);
    list.insert(
      0,
      ContinueWatching(
        id: item.id,
        title: item.title,
        imageUrl: item.imageUrl,
        contentType: item.contentType,
        fandom: item.fandom,
        durationSeconds: item.durationSeconds,
        percentage: (item.progress * 100).round(),
        isOffline: item.isOffline,
      ),
    );
    _dashboard = HomeDashboard(
      greeting: _dashboard!.greeting,
      user: _dashboard!.user,
      fandoms: _dashboard!.fandoms,
      badges: _dashboard!.badges,
      tasks: _dashboard!.tasks,
      stats: _dashboard!.stats,
      completion: _dashboard!.completion,
      trending: _dashboard!.trending,
      hubs: _dashboard!.hubs,
      latestNews: _dashboard!.latestNews,
      forYou: _dashboard!.forYou,
      continueWatching: list.take(6).toList(),
      nextEvent: _dashboard!.nextEvent,
      unreadNotifications: _dashboard!.unreadNotifications,
    );
    notifyListeners();
  }
}
