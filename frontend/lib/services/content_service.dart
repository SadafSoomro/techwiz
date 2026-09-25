import '../config/api_config.dart';
import '../models/content_models.dart';
import 'api_client.dart';

/// MEMBER 2 - Fandom Content
/// HTTP layer over the /api/content routes (Fandom Hub, News, Gallery,
/// Video, Podcasts, Discover, glossary and the recent / offline cache).
class ContentService {
  /// GET /api/content/hub - Explore Fandoms + trending carousel.
  static Future<ApiResult<HubsBundle>> hubs() => ApiClient.request(
        'GET',
        ApiConfig.contentHubsUrl,
        parser: HubsBundle.fromJson,
      );

  /// GET /api/content/hub/:slug - one Fandom Hub with all of its sections.
  static Future<ApiResult<HubBundle>> hub(String slug) => ApiClient.request(
        'GET',
        ApiConfig.contentHubUrl(slug),
        parser: HubBundle.fromJson,
      );

  /// GET /api/content - filtered list (news / video / podcast / gallery).
  static Future<ApiResult<List<ContentItem>>> list({
    String type = '',
    String fandom = '',
    String hub = '',
    String query = '',
    String sort = 'latest',
    int limit = 20,
    int offset = 0,
  }) async {
    final result = await ApiClient.request<Map<String, dynamic>>(
      'GET',
      ApiConfig.contentUrl,
      parser: (json) => json,
      query: {
        'type': type,
        'fandom': fandom,
        'hub': hub,
        'q': query,
        'sort': sort,
        'limit': limit,
        'offset': offset,
      },
    );

    if (!result.success) return ApiResult.failure(result.message);
    return ApiResult(success: true, message: 'OK', data: ContentItem.listFrom(result.data?['items']));
  }

  /// GET /api/content/discover - mixed media feed.
  static Future<ApiResult<DiscoverBundle>> discover() => ApiClient.request(
        'GET',
        ApiConfig.contentDiscoverUrl,
        parser: DiscoverBundle.fromJson,
      );

  /// GET /api/content/:id - details + gallery media + related content.
  static Future<ApiResult<ContentDetails>> details(int id) => ApiClient.request(
        'GET',
        ApiConfig.contentDetailsUrl(id),
        parser: ContentDetails.fromJson,
      );

  /// GET /api/content/glossary - beginner fan hub glossary.
  static Future<ApiResult<List<GlossaryTerm>>> glossary({String fandom = ''}) async {
    final result = await ApiClient.request<Map<String, dynamic>>(
      'GET',
      ApiConfig.contentGlossaryUrl,
      parser: (json) => json,
      query: {'fandom': fandom},
    );
    if (!result.success) return ApiResult.failure(result.message);
    return ApiResult(
      success: true,
      message: 'OK',
      data: GlossaryTerm.listFrom(result.data?['terms']),
    );
  }

  /// GET /api/content/recent - SQLite recent content history.
  static Future<ApiResult<RecentBundle>> recent() => ApiClient.request(
        'GET',
        ApiConfig.contentRecentUrl,
        parser: RecentBundle.fromJson,
      );

  /// GET /api/content/offline - content saved for offline access.
  static Future<ApiResult<OfflineBundle>> offline() => ApiClient.request(
        'GET',
        ApiConfig.contentOfflineUrl,
        parser: OfflineBundle.fromJson,
      );

  /// POST /api/content/:id/view - record a view (recent + progress).
  static Future<ApiResult<Map<String, dynamic>>> recordView(
    int id, {
    double progress = 0,
    bool? offline,
  }) =>
      ApiClient.request(
        'POST',
        ApiConfig.contentViewUrl(id),
        body: {'progress': progress, 'offline': ?offline},
        parser: (json) => json,
      );

  /// POST /api/content/:id/offline - toggle offline save.
  static Future<ApiResult<Map<String, dynamic>>> toggleOffline(int id) =>
      ApiClient.request(
        'POST',
        ApiConfig.contentOfflineToggleUrl(id),
        parser: (json) => json,
      );

  /// POST /api/content/:id/like - toggle like.
  static Future<ApiResult<Map<String, dynamic>>> toggleLike(int id) =>
      ApiClient.request(
        'POST',
        ApiConfig.contentLikeUrl(id),
        parser: (json) => json,
      );
}
