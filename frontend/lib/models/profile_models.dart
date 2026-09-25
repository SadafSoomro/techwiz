/// MEMBER 1 - Profile, Fandom Selection & Home
/// Data models mapped from the Node/Express + SQLite responses.
library;

import 'package:flutter/material.dart';

import '../theme/profile_theme.dart';
import 'content_models.dart';
import 'json_utils.dart';

// ---------------------------------------------------------------------------
// ProfileUser
// ---------------------------------------------------------------------------
class ProfileUser {
  final int id;
  final String name;
  final String email;
  final String bio;
  final String avatar;
  final String inviteCode;
  final int inviteCount;
  final int points;
  final int streakCount;
  final bool isPublic;
  final String memberSince;
  final String joinedAgo;
  final int level;
  final int nextLevelPoints;
  final List<String> selectedFandoms;

  const ProfileUser({
    required this.id,
    required this.name,
    this.email = '',
    this.bio = '',
    this.avatar = '',
    this.inviteCode = '',
    this.inviteCount = 0,
    this.points = 0,
    this.streakCount = 0,
    this.isPublic = true,
    this.memberSince = '',
    this.joinedAgo = '',
    this.level = 1,
    this.nextLevelPoints = 100,
    this.selectedFandoms = const [],
  });

  String get initial => name.trim().isEmpty ? 'U' : name.trim()[0].toUpperCase();

  /// 0..1 progress towards the next level.
  double get levelProgress {
    final span = 100;
    final within = points % span;
    return (within / span).clamp(0.0, 1.0);
  }

  factory ProfileUser.fromJson(Map<String, dynamic> json) {
    final fandoms = json['selected_fandoms'];
    return ProfileUser(
      id: asInt(json['id']),
      name: asString(json['name'], fallback: 'Fan'),
      email: asString(json['email']),
      bio: asString(json['bio']),
      avatar: asString(json['avatar']),
      inviteCode: asString(json['invite_code']),
      inviteCount: asInt(json['invite_count']),
      points: asInt(json['points']),
      streakCount: asInt(json['streak_count']),
      isPublic: json['is_public'] == null ? true : asBool(json['is_public']),
      memberSince: asString(json['member_since']),
      joinedAgo: asString(json['joined_ago']),
      level: asInt(json['level']) == 0 ? 1 : asInt(json['level']),
      nextLevelPoints: asInt(json['next_level_points']),
      selectedFandoms: fandoms is List
          ? fandoms.map((f) => f.toString()).toList()
          : const [],
    );
  }
}

// ---------------------------------------------------------------------------
// FandomOption  (Fandom Selection screen)
// ---------------------------------------------------------------------------
class FandomOption {
  final int id;
  final String name;
  final String hashtag;
  final String icon;
  final String color;
  final String description;
  final int followersCount;
  final String imageUrl;
  final bool isSelected;

  const FandomOption({
    required this.id,
    required this.name,
    this.hashtag = '',
    this.icon = '',
    this.color = '',
    this.description = '',
    this.followersCount = 0,
    this.imageUrl = '',
    this.isSelected = false,
  });

  factory FandomOption.fromJson(Map<String, dynamic> json) => FandomOption(
        id: asInt(json['id']),
        name: asString(json['name']),
        hashtag: asString(json['hashtag']),
        icon: asString(json['icon']),
        color: asString(json['color']),
        description: asString(json['description']),
        followersCount: asInt(json['followers_count']),
        imageUrl: asString(json['image_url']),
        isSelected: asBool(json['is_selected']),
      );

  static List<FandomOption> listFrom(dynamic raw) =>
      parseList<FandomOption>(raw, FandomOption.fromJson);
}

// ---------------------------------------------------------------------------
// ProfileBadge  (Public Badges screen)
// ---------------------------------------------------------------------------
class ProfileBadge {
  final int id;
  final String code;
  final String name;
  final String description;
  final String icon;
  final String color;
  final String category;
  final int threshold;
  final bool isEarned;
  final String awardedAt;
  final String earnedAgo;

  const ProfileBadge({
    required this.id,
    required this.code,
    required this.name,
    this.description = '',
    this.icon = '',
    this.color = '',
    this.category = 'Milestone',
    this.threshold = 0,
    this.isEarned = false,
    this.awardedAt = '',
    this.earnedAgo = '',
  });

  factory ProfileBadge.fromJson(Map<String, dynamic> json) => ProfileBadge(
        id: asInt(json['id']),
        code: asString(json['code']),
        name: asString(json['name']),
        description: asString(json['description']),
        icon: asString(json['icon']),
        color: asString(json['color']),
        category: asString(json['category'], fallback: 'Milestone'),
        threshold: asInt(json['threshold']),
        isEarned: asBool(json['is_earned']),
        awardedAt: asString(json['awarded_at']),
        earnedAgo: asString(json['earned_ago']),
      );

  static List<ProfileBadge> listFrom(dynamic raw) =>
      parseList<ProfileBadge>(raw, ProfileBadge.fromJson);
}

// ---------------------------------------------------------------------------
// SocialTask  (Social & Tasks screen)
// ---------------------------------------------------------------------------
class SocialTask {
  final String code;
  final String title;
  final String description;
  final String icon;
  final String color;
  final int rewardPoints;
  final int targetCount;
  final String action;
  final int progress;
  final bool isCompleted;
  final String progressLabel;
  final int percentage;

  const SocialTask({
    required this.code,
    required this.title,
    this.description = '',
    this.icon = '',
    this.color = '',
    this.rewardPoints = 0,
    this.targetCount = 1,
    this.action = 'in_app',
    this.progress = 0,
    this.isCompleted = false,
    this.progressLabel = '',
    this.percentage = 0,
  });

  factory SocialTask.fromJson(Map<String, dynamic> json) => SocialTask(
        code: asString(json['code']),
        title: asString(json['title']),
        description: asString(json['description']),
        icon: asString(json['icon']),
        color: asString(json['color']),
        rewardPoints: asInt(json['reward_points']),
        targetCount: asInt(json['target_count']) == 0 ? 1 : asInt(json['target_count']),
        action: asString(json['action'], fallback: 'in_app'),
        progress: asInt(json['progress']),
        isCompleted: asBool(json['is_completed']),
        progressLabel: asString(json['progress_label']),
        percentage: asInt(json['percentage']),
      );

  static List<SocialTask> listFrom(dynamic raw) =>
      parseList<SocialTask>(raw, SocialTask.fromJson);
}

// ---------------------------------------------------------------------------
// ProfileStats
// ---------------------------------------------------------------------------
class ProfileStats {
  final int fandomCount;
  final int postsCount;
  final int bookmarksCount;
  final int viewedCount;
  final int offlineCount;
  final int savedEventsCount;
  final int ticketsCount;
  final int badgeCount;
  final int followingCount;
  final int followersCount;
  final int completedTasks;
  final int totalTasks;

  const ProfileStats({
    this.fandomCount = 0,
    this.postsCount = 0,
    this.bookmarksCount = 0,
    this.viewedCount = 0,
    this.offlineCount = 0,
    this.savedEventsCount = 0,
    this.ticketsCount = 0,
    this.badgeCount = 0,
    this.followingCount = 0,
    this.followersCount = 0,
    this.completedTasks = 0,
    this.totalTasks = 0,
  });

  factory ProfileStats.fromJson(Map<String, dynamic> json) => ProfileStats(
        fandomCount: asInt(json['fandom_count']),
        postsCount: asInt(json['posts_count']),
        bookmarksCount: asInt(json['bookmarks_count']),
        viewedCount: asInt(json['viewed_count']),
        offlineCount: asInt(json['offline_count']),
        savedEventsCount: asInt(json['saved_events_count']),
        ticketsCount: asInt(json['tickets_count']),
        badgeCount: asInt(json['badge_count']),
        followingCount: asInt(json['following_count']),
        followersCount: asInt(json['followers_count']),
        completedTasks: asInt(json['completed_tasks']),
        totalTasks: asInt(json['total_tasks']),
      );
}

// ---------------------------------------------------------------------------
// ProfileBundle  (GET /profile/me)
// ---------------------------------------------------------------------------
class ProfileBundle {
  final ProfileUser user;
  final List<FandomOption> fandoms;
  final List<ProfileBadge> badges;
  final List<SocialTask> tasks;
  final ProfileStats stats;
  final int completion;
  final List<String> newBadges;

  const ProfileBundle({
    required this.user,
    this.fandoms = const [],
    this.badges = const [],
    this.tasks = const [],
    this.stats = const ProfileStats(),
    this.completion = 0,
    this.newBadges = const [],
  });

  factory ProfileBundle.fromJson(Map<String, dynamic> json) => ProfileBundle(
        user: ProfileUser.fromJson(
          Map<String, dynamic>.from(json['user'] as Map? ?? {}),
        ),
        fandoms: FandomOption.listFrom(json['fandoms']),
        badges: ProfileBadge.listFrom(json['badges']),
        tasks: SocialTask.listFrom(json['tasks']),
        stats: ProfileStats.fromJson(
          Map<String, dynamic>.from(json['stats'] as Map? ?? {}),
        ),
        completion: asInt(json['completion']),
        newBadges: (json['newBadges'] as List?)
                ?.map((b) => b.toString())
                .toList() ??
            const [],
      );
}

// ---------------------------------------------------------------------------
// BadgeBundle / TasksBundle / FandomBundle
// ---------------------------------------------------------------------------
class BadgeBundle {
  final List<ProfileBadge> badges;
  final int earnedCount;
  final int totalCount;
  final int progress;

  const BadgeBundle({
    this.badges = const [],
    this.earnedCount = 0,
    this.totalCount = 0,
    this.progress = 0,
  });

  factory BadgeBundle.fromJson(Map<String, dynamic> json) => BadgeBundle(
        badges: ProfileBadge.listFrom(json['badges']),
        earnedCount: asInt(json['earnedCount']),
        totalCount: asInt(json['totalCount']),
        progress: asInt(json['progress']),
      );
}

class TasksBundle {
  final List<SocialTask> tasks;
  final int points;
  final int completedCount;
  final int totalCount;
  final int earnedPoints;

  const TasksBundle({
    this.tasks = const [],
    this.points = 0,
    this.completedCount = 0,
    this.totalCount = 0,
    this.earnedPoints = 0,
  });

  factory TasksBundle.fromJson(Map<String, dynamic> json) => TasksBundle(
        tasks: SocialTask.listFrom(json['tasks']),
        points: asInt(json['points']),
        completedCount: asInt(json['completedCount']),
        totalCount: asInt(json['totalCount']),
        earnedPoints: asInt(json['earnedPoints']),
      );
}

class FandomBundle {
  final List<FandomOption> fandoms;
  final List<String> selected;

  const FandomBundle({this.fandoms = const [], this.selected = const []});

  factory FandomBundle.fromJson(Map<String, dynamic> json) => FandomBundle(
        fandoms: FandomOption.listFrom(json['fandoms']),
        selected: (json['selected'] as List?)
                ?.map((s) => s.toString())
                .toList() ??
            const [],
      );
}

// ---------------------------------------------------------------------------
// Invite
// ---------------------------------------------------------------------------
class InvitedFriend {
  final int id;
  final String name;
  final String joinedAgo;

  const InvitedFriend({required this.id, required this.name, this.joinedAgo = ''});

  factory InvitedFriend.fromJson(Map<String, dynamic> json) => InvitedFriend(
        id: asInt(json['id']),
        name: asString(json['name'], fallback: 'Fan'),
        joinedAgo: asString(json['joined_ago']),
      );
}

class InviteInfo {
  final String inviteCode;
  final int inviteCount;
  final int pointsEarned;
  final int rewardPerInvite;
  final List<InvitedFriend> invited;
  final String shareMessage;

  const InviteInfo({
    this.inviteCode = '',
    this.inviteCount = 0,
    this.pointsEarned = 0,
    this.rewardPerInvite = 0,
    this.invited = const [],
    this.shareMessage = '',
  });

  factory InviteInfo.fromJson(Map<String, dynamic> json) => InviteInfo(
        inviteCode: asString(json['inviteCode']),
        inviteCount: asInt(json['inviteCount']),
        pointsEarned: asInt(json['pointsEarned']),
        rewardPerInvite: asInt(json['rewardPerInvite']),
        invited: parseList<InvitedFriend>(json['invited'], InvitedFriend.fromJson),
        shareMessage: asString(json['shareMessage']),
      );
}

// ---------------------------------------------------------------------------
// Settings
// ---------------------------------------------------------------------------
class UserSettings {
  final String language;
  final bool darkMode;
  final bool pushEnabled;
  final bool pushEvents;
  final bool pushContent;
  final bool pushCommunity;
  final bool emailUpdates;
  final bool autoplayVideo;
  final bool offlineSync;
  final bool isPublic;

  const UserSettings({
    this.language = 'English',
    this.darkMode = true,
    this.pushEnabled = true,
    this.pushEvents = true,
    this.pushContent = true,
    this.pushCommunity = true,
    this.emailUpdates = false,
    this.autoplayVideo = true,
    this.offlineSync = true,
    this.isPublic = true,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) => UserSettings(
        language: asString(json['language'], fallback: 'English'),
        darkMode: asBool(json['dark_mode']),
        pushEnabled: asBool(json['push_enabled']),
        pushEvents: asBool(json['push_events']),
        pushContent: asBool(json['push_content']),
        pushCommunity: asBool(json['push_community']),
        emailUpdates: asBool(json['email_updates']),
        autoplayVideo: asBool(json['autoplay_video']),
        offlineSync: asBool(json['offline_sync']),
        isPublic: json['is_public'] == null ? true : asBool(json['is_public']),
      );

  UserSettings copyWith({
    String? language,
    bool? darkMode,
    bool? pushEnabled,
    bool? pushEvents,
    bool? pushContent,
    bool? pushCommunity,
    bool? emailUpdates,
    bool? autoplayVideo,
    bool? offlineSync,
    bool? isPublic,
  }) {
    return UserSettings(
      language: language ?? this.language,
      darkMode: darkMode ?? this.darkMode,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      pushEvents: pushEvents ?? this.pushEvents,
      pushContent: pushContent ?? this.pushContent,
      pushCommunity: pushCommunity ?? this.pushCommunity,
      emailUpdates: emailUpdates ?? this.emailUpdates,
      autoplayVideo: autoplayVideo ?? this.autoplayVideo,
      offlineSync: offlineSync ?? this.offlineSync,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  Map<String, dynamic> toJson() => {
        'language': language,
        'dark_mode': darkMode,
        'push_enabled': pushEnabled,
        'push_events': pushEvents,
        'push_content': pushContent,
        'push_community': pushCommunity,
        'email_updates': emailUpdates,
        'autoplay_video': autoplayVideo,
        'offline_sync': offlineSync,
        'is_public': isPublic,
      };
}

// ---------------------------------------------------------------------------
// Home dashboard pieces
// ---------------------------------------------------------------------------
class TrendingFandom {
  final String name;
  final String hashtag;
  final String icon;
  final String color;
  final String description;
  final int followersCount;
  final bool isSelected;

  const TrendingFandom({
    required this.name,
    this.hashtag = '',
    this.icon = '',
    this.color = '',
    this.description = '',
    this.followersCount = 0,
    this.isSelected = false,
  });

  factory TrendingFandom.fromJson(Map<String, dynamic> json) => TrendingFandom(
        name: asString(json['name']),
        hashtag: asString(json['hashtag']),
        icon: asString(json['icon']),
        color: asString(json['color']),
        description: asString(json['description']),
        followersCount: asInt(json['followers_count']),
        isSelected: asBool(json['is_selected']),
      );

  static List<TrendingFandom> listFrom(dynamic raw) =>
      parseList<TrendingFandom>(raw, TrendingFandom.fromJson);
}

class ContinueWatching {
  final int id;
  final String title;
  final String imageUrl;
  final String contentType;
  final String fandom;
  final int durationSeconds;
  final int percentage;
  final bool isOffline;

  const ContinueWatching({
    required this.id,
    required this.title,
    this.imageUrl = '',
    this.contentType = 'news',
    this.fandom = '',
    this.durationSeconds = 0,
    this.percentage = 0,
    this.isOffline = false,
  });

  factory ContinueWatching.fromJson(Map<String, dynamic> json) => ContinueWatching(
        id: asInt(json['id']),
        title: asString(json['title']),
        imageUrl: asString(json['image_url']),
        contentType: asString(json['content_type'], fallback: 'news'),
        fandom: asString(json['fandom']),
        durationSeconds: asInt(json['duration_seconds']),
        percentage: asInt(json['percentage']),
        isOffline: asBool(json['is_offline']),
      );

  static List<ContinueWatching> listFrom(dynamic raw) =>
      parseList<ContinueWatching>(raw, ContinueWatching.fromJson);
}

class NextEventPreview {
  final int id;
  final String title;
  final String city;
  final String eventDate;
  final String imageUrl;
  final String category;
  final String venue;

  const NextEventPreview({
    required this.id,
    required this.title,
    this.city = '',
    this.eventDate = '',
    this.imageUrl = '',
    this.category = '',
    this.venue = '',
  });

  factory NextEventPreview.fromJson(Map<String, dynamic> json) => NextEventPreview(
        id: asInt(json['id']),
        title: asString(json['title']),
        city: asString(json['city_name']),
        eventDate: asString(json['event_date']),
        imageUrl: asString(json['image_url']),
        category: asString(json['category']),
        venue: asString(json['venue_name']),
      );
}

/// GET /api/profile/home - everything the Home Dashboard renders.
class HomeDashboard {
  final String greeting;
  final ProfileUser user;
  final List<FandomOption> fandoms;
  final List<ProfileBadge> badges;
  final List<SocialTask> tasks;
  final ProfileStats stats;
  final int completion;
  final List<TrendingFandom> trending;
  final List<FandomHub> hubs;
  final List<ContentItem> latestNews;
  final List<ContentItem> forYou;
  final List<ContinueWatching> continueWatching;
  final NextEventPreview? nextEvent;
  final int unreadNotifications;

  const HomeDashboard({
    this.greeting = 'Welcome back',
    required this.user,
    this.fandoms = const [],
    this.badges = const [],
    this.tasks = const [],
    this.stats = const ProfileStats(),
    this.completion = 0,
    this.trending = const [],
    this.hubs = const [],
    this.latestNews = const [],
    this.forYou = const [],
    this.continueWatching = const [],
    this.nextEvent,
    this.unreadNotifications = 0,
  });

  ProfileBundle get asBundle => ProfileBundle(
        user: user,
        fandoms: fandoms,
        badges: badges,
        tasks: tasks,
        stats: stats,
        completion: completion,
      );

  factory HomeDashboard.fromJson(Map<String, dynamic> json) {
    final event = json['nextEvent'];
    return HomeDashboard(
      greeting: asString(json['greeting'], fallback: 'Welcome back'),
      user: ProfileUser.fromJson(
        Map<String, dynamic>.from(json['user'] as Map? ?? {}),
      ),
      fandoms: FandomOption.listFrom(json['fandoms']),
      badges: ProfileBadge.listFrom(json['badges']),
      tasks: SocialTask.listFrom(json['tasks']),
      stats: ProfileStats.fromJson(
        Map<String, dynamic>.from(json['stats'] as Map? ?? {}),
      ),
      completion: asInt(json['completion']),
      trending: TrendingFandom.listFrom(json['trending']),
      hubs: FandomHub.listFrom(json['hubs']),
      latestNews: ContentItem.listFrom(json['latestNews']),
      forYou: ContentItem.listFrom(json['forYou']),
      continueWatching: ContinueWatching.listFrom(json['continueWatching']),
      nextEvent: event is Map
          ? NextEventPreview.fromJson(Map<String, dynamic>.from(event))
          : null,
      unreadNotifications: asInt(json['unreadNotifications']),
    );
  }
}

/// Fallback colours used when a badge colour is missing.
extension ProfileBadgeColors on ProfileBadge {
  Color get displayColor => ProfileTheme.parseColor(color);
}

extension FandomOptionColors on FandomOption {
  Color get displayColor => ProfileTheme.parseColor(color);
}

extension SocialTaskColors on SocialTask {
  Color get displayColor => ProfileTheme.parseColor(color);
}
