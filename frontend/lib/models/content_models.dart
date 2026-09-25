/// MEMBER 2 - Fandom Content
/// Data models mapped from the Node/Express + SQLite responses.
library;

import '../theme/content_theme.dart';
import 'json_utils.dart';

// ---------------------------------------------------------------------------
// ContentItem  (news / article / gallery / video / podcast / deep dive)
// ---------------------------------------------------------------------------
class ContentItem {
  final int id;
  final String fandom;
  final String hubSlug;
  final String contentType;
  final String title;
  final String subtitle;
  final String summary;
  final String body;
  final String imageUrl;
  final String mediaUrl;
  final int durationSeconds;
  final String author;
  final String source;
  final String tags;
  final int? episodeNumber;
  final int? season;
  final int viewsCount;
  final int likesCount;
  final int commentsCount;
  final bool isFeatured;
  final bool isLiked;
  final bool isOffline;
  final double progress;
  final String publishedAt;
  final String publishedAgo;
  final String fandomColor;
  final String fandomIcon;

  const ContentItem({
    required this.id,
    this.fandom = '',
    this.hubSlug = '',
    this.contentType = 'news',
    required this.title,
    this.subtitle = '',
    this.summary = '',
    this.body = '',
    this.imageUrl = '',
    this.mediaUrl = '',
    this.durationSeconds = 0,
    this.author = '',
    this.source = '',
    this.tags = '',
    this.episodeNumber,
    this.season,
    this.viewsCount = 0,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isFeatured = false,
    this.isLiked = false,
    this.isOffline = false,
    this.progress = 0,
    this.publishedAt = '',
    this.publishedAgo = '',
    this.fandomColor = '',
    this.fandomIcon = '',
  });

  List<String> get tagsList => tags
      .split(',')
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toList();

  String get durationLabel => ContentTheme.prettyDuration(durationSeconds);

  int get progressPercent => (progress * 100).round().clamp(0, 100);

  String get episodeLabel =>
      (season != null && episodeNumber != null) ? 'S$season · E$episodeNumber' : '';

  /// Artwork, falling back to the bundled cover of its fandom.
  String get artwork =>
      imageUrl.trim().isNotEmpty ? imageUrl : ContentTheme.fandomArtwork(fandom);

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    return ContentItem(
      id: asInt(json['id']),
      fandom: asString(json['fandom']),
      hubSlug: asString(json['hub_slug']),
      contentType: asString(json['content_type'], fallback: 'news'),
      title: asString(json['title'], fallback: 'Untitled'),
      subtitle: asString(json['subtitle']),
      summary: asString(json['summary']),
      body: asString(json['body']),
      imageUrl: asString(json['image_url']),
      mediaUrl: asString(json['media_url']),
      durationSeconds: asInt(json['duration_seconds']),
      author: asString(json['author']),
      source: asString(json['source']),
      tags: asString(json['tags']),
      episodeNumber: asNullableInt(json['episode_number']),
      season: asNullableInt(json['season']),
      viewsCount: asInt(json['views_count']),
      likesCount: asInt(json['likes_count']),
      commentsCount: asInt(json['comments_count']),
      isFeatured: asBool(json['is_featured']),
      isLiked: asBool(json['is_liked']),
      isOffline: asBool(json['is_offline']),
      progress: asDouble(json['progress']),
      publishedAt: asString(json['published_at']),
      publishedAgo: asString(json['published_ago']),
      fandomColor: asString(json['fandom_color']),
      fandomIcon: asString(json['fandom_icon']),
    );
  }

  static List<ContentItem> listFrom(dynamic raw) =>
      parseList<ContentItem>(raw, ContentItem.fromJson);

  ContentItem copyWith({bool? isLiked, int? likesCount, bool? isOffline}) {
    return ContentItem(
      id: id,
      fandom: fandom,
      hubSlug: hubSlug,
      contentType: contentType,
      title: title,
      subtitle: subtitle,
      summary: summary,
      body: body,
      imageUrl: imageUrl,
      mediaUrl: mediaUrl,
      durationSeconds: durationSeconds,
      author: author,
      source: source,
      tags: tags,
      episodeNumber: episodeNumber,
      season: season,
      viewsCount: viewsCount,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount,
      isFeatured: isFeatured,
      isLiked: isLiked ?? this.isLiked,
      isOffline: isOffline ?? this.isOffline,
      progress: progress,
      publishedAt: publishedAt,
      publishedAgo: publishedAgo,
      fandomColor: fandomColor,
      fandomIcon: fandomIcon,
    );
  }
}

// ---------------------------------------------------------------------------
// FandomHub  (Explore Fandoms / Fandom Hub)
// ---------------------------------------------------------------------------
class FandomHub {
  final int id;
  final String slug;
  final String name;
  final String tagline;
  final String description;
  final String imageUrl;
  final String icon;
  final String color;
  final int followersCount;
  final int postsCount;
  final int itemsCount;
  final int totalViews;
  final bool isTrending;

  const FandomHub({
    required this.id,
    required this.slug,
    required this.name,
    this.tagline = '',
    this.description = '',
    this.imageUrl = '',
    this.icon = '',
    this.color = '',
    this.followersCount = 0,
    this.postsCount = 0,
    this.itemsCount = 0,
    this.totalViews = 0,
    this.isTrending = false,
  });

  factory FandomHub.fromJson(Map<String, dynamic> json) {
    return FandomHub(
      id: asInt(json['id']),
      slug: asString(json['slug']),
      name: asString(json['name'], fallback: 'Fandom'),
      tagline: asString(json['tagline']),
      description: asString(json['description']),
      imageUrl: asString(json['image_url']),
      icon: asString(json['icon'], fallback: 'explore_rounded'),
      color: asString(json['color']),
      followersCount: asInt(json['followers_count']),
      postsCount: asInt(json['posts_count']),
      itemsCount: asInt(json['items_count']),
      totalViews: asInt(json['total_views']),
      isTrending: asBool(json['is_trending']),
    );
  }

  static List<FandomHub> listFrom(dynamic raw) =>
      parseList<FandomHub>(raw, FandomHub.fromJson);
}

// ---------------------------------------------------------------------------
// Detail payloads
// ---------------------------------------------------------------------------
class ContentMedia {
  final int id;
  final String mediaType;
  final String url;
  final String caption;

  const ContentMedia({
    required this.id,
    this.mediaType = 'image',
    required this.url,
    this.caption = '',
  });

  factory ContentMedia.fromJson(Map<String, dynamic> json) => ContentMedia(
        id: asInt(json['id']),
        mediaType: asString(json['media_type'], fallback: 'image'),
        url: asString(json['url']),
        caption: asString(json['caption']),
      );

  static List<ContentMedia> listFrom(dynamic raw) =>
      parseList<ContentMedia>(raw, ContentMedia.fromJson);
}

class ContentDetails {
  final ContentItem item;
  final List<String> paragraphs;
  final List<ContentMedia> media;
  final List<ContentItem> related;

  const ContentDetails({
    required this.item,
    this.paragraphs = const [],
    this.media = const [],
    this.related = const [],
  });

  factory ContentDetails.fromJson(Map<String, dynamic> json) {
    final item = ContentItem.fromJson(
      Map<String, dynamic>.from(json['item'] as Map? ?? {}),
    );
    return ContentDetails(
      item: item,
      paragraphs: (json['paragraphs'] as List?)
              ?.map((p) => p.toString())
              .where((p) => p.trim().isNotEmpty)
              .toList() ??
          const [],
      media: ContentMedia.listFrom(json['media']),
      related: ContentItem.listFrom(json['related']),
    );
  }
}

/// One Fandom Hub screen payload (hub + its sections).
class HubBundle {
  final FandomHub hub;
  final List<ContentItem> news;
  final List<ContentItem> galleries;
  final List<ContentItem> videos;
  final List<ContentItem> podcasts;
  final List<ContentItem> deepDives;
  final List<GlossaryTerm> glossary;

  const HubBundle({
    required this.hub,
    this.news = const [],
    this.galleries = const [],
    this.videos = const [],
    this.podcasts = const [],
    this.deepDives = const [],
    this.glossary = const [],
  });

  List<ContentItem> get all => [...news, ...galleries, ...videos, ...podcasts, ...deepDives];

  factory HubBundle.fromJson(Map<String, dynamic> json) {
    return HubBundle(
      hub: FandomHub.fromJson(
        Map<String, dynamic>.from(json['hub'] as Map? ?? {}),
      ),
      news: ContentItem.listFrom(json['news']),
      galleries: ContentItem.listFrom(json['galleries']),
      videos: ContentItem.listFrom(json['videos']),
      podcasts: ContentItem.listFrom(json['podcasts']),
      deepDives: ContentItem.listFrom(json['deepDives']),
      glossary: GlossaryTerm.listFrom(json['glossary']),
    );
  }
}

class GlossaryTerm {
  final String term;
  final String definition;
  final String fandom;
  final String category;

  const GlossaryTerm({
    required this.term,
    required this.definition,
    this.fandom = 'General',
    this.category = 'General',
  });

  factory GlossaryTerm.fromJson(Map<String, dynamic> json) => GlossaryTerm(
        term: asString(json['term']),
        definition: asString(json['definition']),
        fandom: asString(json['fandom'], fallback: 'General'),
        category: asString(json['category'], fallback: 'General'),
      );

  static List<GlossaryTerm> listFrom(dynamic raw) =>
      parseList<GlossaryTerm>(raw, GlossaryTerm.fromJson);
}

/// Discover screen payload.
class DiscoverBundle {
  final ContentItem? spotlight;
  final List<ContentItem> trending;
  final List<ContentItem> latest;
  final List<ContentItem> collections;

  const DiscoverBundle({
    this.spotlight,
    this.trending = const [],
    this.latest = const [],
    this.collections = const [],
  });

  factory DiscoverBundle.fromJson(Map<String, dynamic> json) {
    final raw = json['spotlight'];
    return DiscoverBundle(
      spotlight: raw is Map
          ? ContentItem.fromJson(Map<String, dynamic>.from(raw))
          : null,
      trending: ContentItem.listFrom(json['trending']),
      latest: ContentItem.listFrom(json['latest']),
      collections: ContentItem.listFrom(json['collections']),
    );
  }
}

/// Recent + offline payloads.
class RecentBundle {
  final List<ContentItem> recent;
  final int offlineCount;

  const RecentBundle({this.recent = const [], this.offlineCount = 0});

  factory RecentBundle.fromJson(Map<String, dynamic> json) => RecentBundle(
        recent: ContentItem.listFrom(json['recent']),
        offlineCount: asInt(json['offlineCount']),
      );
}

class OfflineBundle {
  final List<ContentItem> offline;
  final int items;
  final double sizeMb;

  const OfflineBundle({this.offline = const [], this.items = 0, this.sizeMb = 0});

  factory OfflineBundle.fromJson(Map<String, dynamic> json) {
    final totals = parseMap(json['totals']) ?? const {};
    return OfflineBundle(
      offline: ContentItem.listFrom(json['offline']),
      items: asInt(totals['items']),
      sizeMb: asDouble(totals['sizeMb']),
    );
  }
}

/// Fandom Hub list payload (Explore Fandoms).
class HubsBundle {
  final List<FandomHub> hubs;
  final List<FandomHub> trending;
  final int totalItems;
  final int totalViews;

  const HubsBundle({
    this.hubs = const [],
    this.trending = const [],
    this.totalItems = 0,
    this.totalViews = 0,
  });

  factory HubsBundle.fromJson(Map<String, dynamic> json) {
    final totals = parseMap(json['totals']) ?? const {};
    return HubsBundle(
      hubs: FandomHub.listFrom(json['hubs']),
      trending: FandomHub.listFrom(json['trending']),
      totalItems: asInt(totals['items']),
      totalViews: asInt(totals['views']),
    );
  }
}
