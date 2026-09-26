import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // Base URL auto-detection based on device/platform
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5000/api';
      }
    } catch (_) {}
    return 'http://localhost:5000/api';
  }

  // Google Client ID
  static const String googleClientId =
      '346283855204-tmhtfilf469h44b4jc8mri4oqokfk7jf.apps.googleusercontent.com';

  // Endpoints
  static String get registerUrl => '$baseUrl/auth/register';
  static String get verifyEmailUrl => '$baseUrl/auth/verify-email';
  static String get loginUrl => '$baseUrl/auth/login';
  static String get forgotPasswordUrl => '$baseUrl/auth/forgot-password';
  static String get resetPasswordUrl => '$baseUrl/auth/reset-password';
  static String get googleLoginUrl => '$baseUrl/auth/google';
  static String get getUsersUrl => '$baseUrl/users/getall';

  // General - Contact Us (enquiry form + office location)
  static String get contactUrl => '$baseUrl/contact';

  // =====================================================================
  // MEMBER 3 - Search & Community endpoints
  // =====================================================================

  // Search module
  static String get searchUrl => '$baseUrl/search';
  static String get searchFiltersUrl => '$baseUrl/search/filters';
  static String get searchTrendingUrl => '$baseUrl/search/trending';
  static String get searchSuggestionsUrl => '$baseUrl/search/suggestions';
  static String get searchHistoryUrl => '$baseUrl/search/history';

  // Posts / Discussions module
  static String get postsUrl => '$baseUrl/posts';
  static String get discussionsUrl => '$baseUrl/posts/discussions';
  static String postDetailsUrl(int id) => '$baseUrl/posts/$id';
  static String postLikeUrl(int id) => '$baseUrl/posts/$id/like';
  static String postCommentsUrl(int id) => '$baseUrl/posts/$id/comments';

  // Community module
  static String get communityOverviewUrl => '$baseUrl/community/overview';
  static String get communityProfileUrl => '$baseUrl/community/profile';
  static String get bookmarksUrl => '$baseUrl/community/bookmarks';
  static String toggleBookmarkUrl(int postId) =>
      '$baseUrl/community/bookmarks/$postId';
  static String get notificationsUrl => '$baseUrl/community/notifications';
  static String get markAllNotificationsReadUrl =>
      '$baseUrl/community/notifications/read-all';
  static String markNotificationReadUrl(int id) =>
      '$baseUrl/community/notifications/$id/read';
  static String deleteNotificationUrl(int id) =>
      '$baseUrl/community/notifications/$id';
  static String userProfileUrl(int userId) =>
      '$baseUrl/community/users/$userId/profile';
  static String toggleFollowUrl(int userId) =>
      '$baseUrl/community/users/$userId/follow';
  static String followersUrl(int userId) =>
      '$baseUrl/community/users/$userId/followers';
  static String followingUrl(int userId) =>
      '$baseUrl/community/users/$userId/following';

  // =====================================================================
  // MEMBER 4 - Events & Maps endpoints
  // =====================================================================

  static String get eventsUrl => '$baseUrl/events';
  static String get eventsNearbyUrl => '$baseUrl/events/nearby';
  static String get eventsMapUrl => '$baseUrl/events/map';
  static String get eventsOverviewUrl => '$baseUrl/events/overview';
  static String get eventsCategoriesUrl => '$baseUrl/events/categories';
  static String get eventsCitiesUrl => '$baseUrl/events/cities';
  static String get eventsCalendarUrl => '$baseUrl/events/calendar';
  static String get eventsSavedUrl => '$baseUrl/events/saved/mine';
  static String get eventsTicketsUrl => '$baseUrl/events/tickets/mine';
  static String eventTicketUrl(int ticketId) => '$baseUrl/events/tickets/$ticketId';
  static String eventDetailsUrl(int eventId) => '$baseUrl/events/$eventId';
  static String eventSaveUrl(int eventId) => '$baseUrl/events/$eventId/save';
  static String eventBookTicketUrl(int eventId) =>
      '$baseUrl/events/$eventId/tickets';

  // =====================================================================
  // MEMBER 1 - Profile, Fandom Selection & Home endpoints
  // =====================================================================

  static String get profileHomeUrl => '$baseUrl/profile/home';
  static String get profileMeUrl => '$baseUrl/profile/me';
  static String get profileAvatarsUrl => '$baseUrl/profile/avatars';
  static String get profileFandomsUrl => '$baseUrl/profile/fandoms';
  static String get profileBadgesUrl => '$baseUrl/profile/badges';
  static String get profileInviteUrl => '$baseUrl/profile/invite';
  static String get profileInviteClaimUrl => '$baseUrl/profile/invite/claim';
  static String get profileTasksUrl => '$baseUrl/profile/tasks';
  static String profileTaskCompleteUrl(String code) =>
      '$baseUrl/profile/tasks/$code/complete';
  static String get profileSettingsUrl => '$baseUrl/profile/settings';

  // =====================================================================
  // MEMBER 2 - Fandom Content endpoints
  // =====================================================================

  static String get contentUrl => '$baseUrl/content';
  static String get contentHubsUrl => '$baseUrl/content/hub';
  static String contentHubUrl(String slug) => '$baseUrl/content/hub/$slug';
  static String get contentGlossaryUrl => '$baseUrl/content/glossary';
  static String get contentDiscoverUrl => '$baseUrl/content/discover';
  static String get contentRecentUrl => '$baseUrl/content/recent';
  static String get contentOfflineUrl => '$baseUrl/content/offline';
  static String contentDetailsUrl(int id) => '$baseUrl/content/$id';
  static String contentViewUrl(int id) => '$baseUrl/content/$id/view';
  static String contentOfflineToggleUrl(int id) => '$baseUrl/content/$id/offline';
  static String contentLikeUrl(int id) => '$baseUrl/content/$id/like';

  // =====================================================================
  // MEMBER 5 - Merchandise Store + AI Fan Helper endpoints
  // =====================================================================

  // Shop home / catalogue
  static String get shopOverviewUrl => '$baseUrl/shop/overview';
  static String get shopCategoriesUrl => '$baseUrl/shop/categories';
  static String get shopFandomsUrl => '$baseUrl/shop/fandoms';
  static String get shopProductsUrl => '$baseUrl/shop/products';
  static String shopProductUrl(int productId) =>
      '$baseUrl/shop/products/$productId';

  // Wishlist + price drop alerts
  static String get wishlistUrl => '$baseUrl/shop/wishlist';
  static String wishlistToggleUrl(int productId) =>
      '$baseUrl/shop/wishlist/$productId';
  static String get priceAlertsUrl => '$baseUrl/shop/wishlist/alerts';
  static String get priceAlertsCheckUrl =>
      '$baseUrl/shop/wishlist/alerts/check';

  // Cart
  static String get cartUrl => '$baseUrl/shop/cart';
  static String get cartSummaryUrl => '$baseUrl/shop/cart/summary';
  static String cartItemUrl(int productId) => '$baseUrl/shop/cart/$productId';

  // Checkout + orders
  static String get checkoutUrl => '$baseUrl/shop/checkout';
  static String get myOrdersUrl => '$baseUrl/shop/orders/mine';
  static String orderUrl(int orderId) => '$baseUrl/shop/orders/$orderId';

  // AI Fan Helper
  static String get aiChatUrl => '$baseUrl/ai/chat';
  static String get aiSuggestionsUrl => '$baseUrl/ai/suggestions';
  static String get aiTopicsUrl => '$baseUrl/ai/topics';
  static String get aiHistoryUrl => '$baseUrl/ai/history';
}
