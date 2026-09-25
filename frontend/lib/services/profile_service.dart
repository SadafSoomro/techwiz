import '../config/api_config.dart';
import '../models/profile_models.dart';
import 'api_client.dart';

/// MEMBER 1 - Profile, Fandom Selection & Home
/// HTTP layer over the /api/profile routes.
class ProfileService {
  /// GET /api/profile/home - Home Dashboard aggregate (profile + trending +
  /// latest content + next event), served from the SQLite user cache.
  static Future<ApiResult<HomeDashboard>> dashboard() => ApiClient.request(
        'GET',
        ApiConfig.profileHomeUrl,
        parser: HomeDashboard.fromJson,
      );

  /// GET /api/profile/me - profile + stats + badges + tasks.
  static Future<ApiResult<ProfileBundle>> me() => ApiClient.request(
        'GET',
        ApiConfig.profileMeUrl,
        parser: ProfileBundle.fromJson,
      );

  /// PUT /api/profile/me - Edit Profile (name / bio / avatar).
  static Future<ApiResult<ProfileBundle>> updateProfile({
    String? name,
    String? bio,
    String? avatar,
    bool? isPublic,
  }) =>
      ApiClient.request(
        'PUT',
        ApiConfig.profileMeUrl,
        body: {
          'name': ?name,
          'bio': ?bio,
          'avatar': ?avatar,
          'is_public': ?isPublic,
        },
        parser: ProfileBundle.fromJson,
      );

  /// GET /api/profile/avatars - bundled avatar presets.
  static Future<ApiResult<List<String>>> avatars() async {
    final result = await ApiClient.request<Map<String, dynamic>>(
      'GET',
      ApiConfig.profileAvatarsUrl,
      parser: (json) => json,
    );
    if (!result.success) return ApiResult.failure(result.message);
    final raw = result.data?['avatars'];
    return ApiResult(
      success: true,
      message: 'OK',
      data: raw is List ? raw.map((a) => a.toString()).toList() : <String>[],
    );
  }

  /// GET /api/profile/fandoms - fandom catalogue + current selection.
  static Future<ApiResult<FandomBundle>> fandoms() => ApiClient.request(
        'GET',
        ApiConfig.profileFandomsUrl,
        parser: FandomBundle.fromJson,
      );

  /// PUT /api/profile/fandoms - save the Fandom Selection screen.
  static Future<ApiResult<Map<String, dynamic>>> saveFandoms(
    List<String> fandoms, {
    bool skipped = false,
  }) =>
      ApiClient.request(
        'PUT',
        ApiConfig.profileFandomsUrl,
        body: {'fandoms': fandoms, 'skipped': skipped},
      );

  /// GET /api/profile/badges - Public Badges screen.
  static Future<ApiResult<BadgeBundle>> badges() => ApiClient.request(
        'GET',
        ApiConfig.profileBadgesUrl,
        parser: BadgeBundle.fromJson,
      );

  /// GET /api/profile/invite - Invite Friends screen.
  static Future<ApiResult<InviteInfo>> invite() => ApiClient.request(
        'GET',
        ApiConfig.profileInviteUrl,
        parser: InviteInfo.fromJson,
      );

  /// POST /api/profile/invite/claim - apply a friend's invite code.
  static Future<ApiResult<Map<String, dynamic>>> claimInvite(String code) =>
      ApiClient.request(
        'POST',
        ApiConfig.profileInviteClaimUrl,
        body: {'code': code},
        parser: (json) => json,
      );

  /// GET /api/profile/tasks - Social & Tasks screen.
  static Future<ApiResult<TasksBundle>> tasks() => ApiClient.request(
        'GET',
        ApiConfig.profileTasksUrl,
        parser: TasksBundle.fromJson,
      );

  /// POST /api/profile/tasks/:code/complete
  static Future<ApiResult<Map<String, dynamic>>> completeTask(String code) =>
      ApiClient.request(
        'POST',
        ApiConfig.profileTaskCompleteUrl(code),
        parser: (json) => json,
      );

  /// GET /api/profile/settings
  static Future<ApiResult<Map<String, dynamic>>> settings() =>
      ApiClient.request('GET', ApiConfig.profileSettingsUrl);

  /// PUT /api/profile/settings
  static Future<ApiResult<Map<String, dynamic>>> updateSettings(
    UserSettings settings,
  ) =>
      ApiClient.request(
        'PUT',
        ApiConfig.profileSettingsUrl,
        body: settings.toJson(),
      );
}
