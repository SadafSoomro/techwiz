/// MEMBER 3 - Search & Community
/// Data models mapped from the Node/Express + SQLite responses.
library;

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

bool _toBool(dynamic value) => _toInt(value) == 1;

String _toStr(dynamic value) => value?.toString() ?? '';

// ---------------------------------------------------------------------------
// CommunityUser
// ---------------------------------------------------------------------------
class CommunityUser {
  final int id;
  final String name;
  final String? avatar;
  final String bio;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final int totalLikes;
  final bool isFollowing;
  final String joinedAgo;

  const CommunityUser({
    required this.id,
    required this.name,
    this.avatar,
    this.bio = '',
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.totalLikes = 0,
    this.isFollowing = false,
    this.joinedAgo = '',
  });

  String get initial => name.trim().isEmpty ? 'U' : name.trim()[0].toUpperCase();

  factory CommunityUser.fromJson(Map<String, dynamic> json) {
    return CommunityUser(
      id: _toInt(json['id']),
      name: _toStr(json['name']).isEmpty ? 'Unknown Fan' : _toStr(json['name']),
      avatar: json['avatar']?.toString(),
      bio: _toStr(json['bio']),
      followersCount: _toInt(json['followers_count']),
      followingCount: _toInt(json['following_count']),
      postsCount: _toInt(json['posts_count']),
      totalLikes: _toInt(json['total_likes']),
      isFollowing: _toBool(json['is_following']),
      joinedAgo: _toStr(json['joined_ago']),
    );
  }

  CommunityUser copyWith({bool? isFollowing, int? followersCount}) {
    return CommunityUser(
      id: id,
      name: name,
      avatar: avatar,
      bio: bio,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount,
      postsCount: postsCount,
      totalLikes: totalLikes,
      isFollowing: isFollowing ?? this.isFollowing,
      joinedAgo: joinedAgo,
    );
  }
}

// ---------------------------------------------------------------------------
// CommunityPost  (community post OR deep-dive discussion)
// ---------------------------------------------------------------------------
class CommunityPost {
  final int id;
  final int userId;
  final String fandom;
  final String title;
  final String content;
  final String? imageUrl;
  final String hashtags;
  final String postType;
  final int rating;
  final int likesCount;
  final int commentsCount;
  final int viewsCount;
  final String createdAt;
  final String createdAgo;
  final String authorName;
  final String? authorAvatar;
  final bool isLiked;
  final bool isBookmarked;

  const CommunityPost({
    required this.id,
    required this.userId,
    required this.fandom,
    required this.title,
    required this.content,
    this.imageUrl,
    this.hashtags = '',
    this.postType = 'post',
    this.rating = 0,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.viewsCount = 0,
    this.createdAt = '',
    this.createdAgo = '',
    this.authorName = 'Unknown Fan',
    this.authorAvatar,
    this.isLiked = false,
    this.isBookmarked = false,
  });

  bool get isDeepDive => postType == 'deep_dive';
  String get authorInitial =>
      authorName.trim().isEmpty ? 'U' : authorName.trim()[0].toUpperCase();

  List<String> get hashtagList => hashtags
      .split(',')
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .map((t) => t.startsWith('#') ? t : '#$t')
      .toList();

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: _toInt(json['id']),
      userId: _toInt(json['user_id']),
      fandom: _toStr(json['fandom']).isEmpty ? 'General' : _toStr(json['fandom']),
      title: _toStr(json['title']),
      content: _toStr(json['content']),
      imageUrl: json['image_url']?.toString(),
      hashtags: _toStr(json['hashtags']),
      postType: _toStr(json['post_type']).isEmpty ? 'post' : _toStr(json['post_type']),
      rating: _toInt(json['rating']),
      likesCount: _toInt(json['likes_count']),
      commentsCount: _toInt(json['comments_count']),
      viewsCount: _toInt(json['views_count']),
      createdAt: _toStr(json['created_at']),
      createdAgo: _toStr(json['created_ago']),
      authorName:
          _toStr(json['author_name']).isEmpty ? 'Unknown Fan' : _toStr(json['author_name']),
      authorAvatar: json['author_avatar']?.toString(),
      isLiked: _toBool(json['is_liked']),
      isBookmarked: _toBool(json['is_bookmarked']),
    );
  }

  CommunityPost copyWith({
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
    bool? isBookmarked,
  }) {
    return CommunityPost(
      id: id,
      userId: userId,
      fandom: fandom,
      title: title,
      content: content,
      imageUrl: imageUrl,
      hashtags: hashtags,
      postType: postType,
      rating: rating,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      viewsCount: viewsCount,
      createdAt: createdAt,
      createdAgo: createdAgo,
      authorName: authorName,
      authorAvatar: authorAvatar,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}

// ---------------------------------------------------------------------------
// PostComment
// ---------------------------------------------------------------------------
class PostComment {
  final int id;
  final int postId;
  final int userId;
  final String body;
  final String createdAt;
  final String createdAgo;
  final String authorName;
  final String? authorAvatar;

  const PostComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.body,
    this.createdAt = '',
    this.createdAgo = '',
    this.authorName = 'Unknown Fan',
    this.authorAvatar,
  });

  String get authorInitial =>
      authorName.trim().isEmpty ? 'U' : authorName.trim()[0].toUpperCase();

  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      id: _toInt(json['id']),
      postId: _toInt(json['post_id']),
      userId: _toInt(json['user_id']),
      body: _toStr(json['body']),
      createdAt: _toStr(json['created_at']),
      createdAgo: _toStr(json['created_ago']),
      authorName:
          _toStr(json['author_name']).isEmpty ? 'Unknown Fan' : _toStr(json['author_name']),
      authorAvatar: json['author_avatar']?.toString(),
    );
  }
}

// ---------------------------------------------------------------------------
// FandomCategory
// ---------------------------------------------------------------------------
class FandomCategory {
  final int id;
  final String name;
  final String hashtag;
  final String icon;
  final String color;
  final String description;
  final int postsCount;

  const FandomCategory({
    this.id = 0,
    required this.name,
    this.hashtag = '',
    this.icon = '',
    this.color = '',
    this.description = '',
    this.postsCount = 0,
  });

  factory FandomCategory.fromJson(Map<String, dynamic> json) {
    return FandomCategory(
      id: _toInt(json['id']),
      name: _toStr(json['name']),
      hashtag: _toStr(json['hashtag']),
      icon: _toStr(json['icon']),
      color: _toStr(json['color']),
      description: _toStr(json['description']),
      postsCount: _toInt(json['posts_count']),
    );
  }
}

// ---------------------------------------------------------------------------
// TrendingHashtag
// ---------------------------------------------------------------------------
class TrendingHashtag {
  final String tag;
  final int postsCount;
  final int likesCount;

  const TrendingHashtag({
    required this.tag,
    this.postsCount = 0,
    this.likesCount = 0,
  });

  factory TrendingHashtag.fromJson(Map<String, dynamic> json) {
    return TrendingHashtag(
      tag: _toStr(json['tag']),
      postsCount: _toInt(json['posts_count']),
      likesCount: _toInt(json['likes_count']),
    );
  }
}

// ---------------------------------------------------------------------------
// AppNotification
// ---------------------------------------------------------------------------
class AppNotification {
  final int id;
  final String type;
  final String message;
  final int? referenceId;
  final bool isRead;
  final String createdAgo;
  final String actorName;
  final String? actorAvatar;

  const AppNotification({
    required this.id,
    required this.type,
    required this.message,
    this.referenceId,
    this.isRead = false,
    this.createdAgo = '',
    this.actorName = '',
    this.actorAvatar,
  });

  String get actorInitial =>
      actorName.trim().isEmpty ? 'F' : actorName.trim()[0].toUpperCase();

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: _toInt(json['id']),
      type: _toStr(json['type']).isEmpty ? 'system' : _toStr(json['type']),
      message: _toStr(json['message']),
      referenceId: json['reference_id'] == null ? null : _toInt(json['reference_id']),
      isRead: _toBool(json['is_read']),
      createdAgo: _toStr(json['created_ago']),
      actorName: _toStr(json['actor_name']),
      actorAvatar: json['actor_avatar']?.toString(),
    );
  }
}

// ---------------------------------------------------------------------------
// TrendingBundle -> one payload for the whole Trending screen
// ---------------------------------------------------------------------------
class TrendingBundle {
  final List<TrendingHashtag> hashtags;
  final List<CommunityUser> users;
  final List<CommunityPost> posts;
  final List<FandomCategory> fandoms;
  final List<CommunityPost> deepDives;

  const TrendingBundle({
    this.hashtags = const [],
    this.users = const [],
    this.posts = const [],
    this.fandoms = const [],
    this.deepDives = const [],
  });

  static List<T> _list<T>(dynamic raw, T Function(Map<String, dynamic>) parse) {
    if (raw is! List) return <T>[];
    return raw
        .whereType<Map>()
        .map((item) => parse(Map<String, dynamic>.from(item)))
        .toList();
  }

  factory TrendingBundle.fromJson(Map<String, dynamic> json) {
    return TrendingBundle(
      hashtags: _list(json['hashtags'], TrendingHashtag.fromJson),
      users: _list(json['users'], CommunityUser.fromJson),
      posts: _list(json['posts'], CommunityPost.fromJson),
      fandoms: _list(json['fandoms'], FandomCategory.fromJson),
      deepDives: _list(json['deepDives'], CommunityPost.fromJson),
    );
  }
}

// ---------------------------------------------------------------------------
// SearchBundle -> results of one search request
// ---------------------------------------------------------------------------
class SearchBundle {
  final String query;
  final List<CommunityUser> users;
  final List<CommunityPost> posts;
  final List<FandomCategory> fandoms;

  const SearchBundle({
    this.query = '',
    this.users = const [],
    this.posts = const [],
    this.fandoms = const [],
  });

  int get total => users.length + posts.length + fandoms.length;
  bool get isEmpty => total == 0;

  factory SearchBundle.fromJson(Map<String, dynamic> json) {
    return SearchBundle(
      query: _toStr(json['query']),
      users: TrendingBundle._list(json['users'], CommunityUser.fromJson),
      posts: TrendingBundle._list(json['posts'], CommunityPost.fromJson),
      fandoms: TrendingBundle._list(json['fandoms'], FandomCategory.fromJson),
    );
  }
}
