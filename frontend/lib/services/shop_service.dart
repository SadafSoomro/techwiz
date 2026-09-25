import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/json_utils.dart';
import '../models/shop_models.dart';
import 'auth_storage.dart';

/// MEMBER 5 - Merchandise Store
/// Thin HTTP layer over the /api/shop routes.
/// The JWT saved by the login flow is attached automatically, so the same
/// service powers public catalogue browsing and the personal
/// wishlist / cart / orders screens.
class ShopResult<T> {
  final bool success;
  final String message;
  final T? data;

  ShopResult({required this.success, required this.message, this.data});

  factory ShopResult.failure(String message) =>
      ShopResult(success: false, message: message);
}

class ShopService {
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

  /// Wraps a decode + parse step so every method has the same error handling.
  static Future<ShopResult<T>> _guard<T>(
    Future<Map<String, dynamic>?> Function() request,
    T Function(Map<String, dynamic> json) parse,
    String fallbackMessage,
  ) async {
    try {
      final json = await request();

      if (json != null && json['success'] == true) {
        return ShopResult(success: true, message: 'OK', data: parse(json));
      }
      return ShopResult.failure(json?['message'] ?? fallbackMessage);
    } catch (e) {
      return ShopResult.failure('Network error ($e)');
    }
  }

  // ==================================================================
  // SHOP HOME / CATALOGUE
  // ==================================================================

  static Future<ShopResult<ShopOverview>> overview() {
    return _guard(
      () => _send('GET', ApiConfig.shopOverviewUrl),
      ShopOverview.fromJson,
      'Could not load the shop',
    );
  }

  static Future<ShopResult<List<ProductCategory>>> categories() {
    return _guard(
      () => _send('GET', ApiConfig.shopCategoriesUrl),
      (json) => parseList(json['categories'], ProductCategory.fromJson),
      'Could not load product categories',
    );
  }

  static Future<ShopResult<List<ProductFandom>>> fandoms() {
    return _guard(
      () => _send('GET', ApiConfig.shopFandomsUrl),
      (json) => parseList(json['fandoms'], ProductFandom.fromJson),
      'Could not load fandoms',
    );
  }

  /// Product catalogue with category / fandom filtering and price sorting.
  /// [sort] = featured | popular | rating | newest | price_low | price_high | discount | name
  static Future<ShopResult<List<Product>>> products({
    String category = '',
    String fandom = '',
    String query = '',
    String sort = 'featured',
    double? minPrice,
    double? maxPrice,
    bool inStockOnly = false,
    bool discountedOnly = false,
    bool featuredOnly = false,
    int limit = 40,
    int offset = 0,
  }) {
    return _guard(
      () => _send(
        'GET',
        ApiConfig.shopProductsUrl,
        query: {
          'category': category,
          'fandom': fandom,
          'q': query,
          'sort': sort,
          'min_price': ?minPrice,
          'max_price': ?maxPrice,
          if (inStockOnly) 'in_stock': 1,
          if (discountedOnly) 'discounted': 1,
          if (featuredOnly) 'featured': 1,
          'limit': limit,
          'offset': offset,
        },
      ),
      (json) => parseList(json['products'], Product.fromJson),
      'Could not load products',
    );
  }

  static Future<ShopResult<Map<String, dynamic>>> productDetails(
    int productId,
  ) {
    return _guard(
      () => _send('GET', ApiConfig.shopProductUrl(productId)),
      (json) => json,
      'Product not found',
    );
  }

  // ==================================================================
  // WISHLIST + PRICE DROP ALERTS
  // ==================================================================

  static Future<ShopResult<Map<String, dynamic>>> wishlist() {
    return _guard(
      () => _send('GET', ApiConfig.wishlistUrl),
      (json) => json,
      'Could not load your wishlist',
    );
  }

  /// Adds or removes the product depending on its current state.
  static Future<ShopResult<bool>> toggleWishlist(int productId) {
    return _guard(
      () => _send('POST', ApiConfig.wishlistToggleUrl(productId)),
      (json) => json['wishlisted'] == true,
      'Could not update your wishlist',
    );
  }

  static Future<ShopResult<String>> removeFromWishlist(int productId) {
    return _guard(
      () => _send('DELETE', ApiConfig.wishlistToggleUrl(productId)),
      (json) => json['message']?.toString() ?? 'Removed',
      'Could not remove the item',
    );
  }

  static Future<ShopResult<String>> clearWishlist() {
    return _guard(
      () => _send('DELETE', ApiConfig.wishlistUrl),
      (json) => json['message']?.toString() ?? 'Wishlist cleared',
      'Could not clear your wishlist',
    );
  }

  /// Runs the price-drop detection and creates the notifications.
  static Future<ShopResult<Map<String, dynamic>>> checkPriceAlerts() {
    return _guard(
      () => _send('POST', ApiConfig.priceAlertsCheckUrl),
      (json) => json,
      'Could not check for price drops',
    );
  }

  static Future<ShopResult<List<PriceAlert>>> priceAlerts() {
    return _guard(
      () => _send('GET', ApiConfig.priceAlertsUrl),
      (json) => parseList(json['alerts'], PriceAlert.fromJson),
      'Could not load price alerts',
    );
  }

  // ==================================================================
  // CART
  // ==================================================================

  static Future<ShopResult<CartSummary>> cart({String promo = ''}) {
    return _guard(
      () => _send('GET', ApiConfig.cartUrl, query: {'promo': promo}),
      CartSummary.fromJson,
      'Could not load your cart',
    );
  }

  static Future<ShopResult<CartSummary>> addToCart(
    int productId, {
    int quantity = 1,
    String promo = '',
  }) {
    return _guard(
      () => _send(
        'POST',
        ApiConfig.cartUrl,
        body: {'product_id': productId, 'quantity': quantity, 'promo': promo},
      ),
      CartSummary.fromJson,
      'Could not add the item to your cart',
    );
  }

  static Future<ShopResult<CartSummary>> updateCartItem(
    int productId, {
    required int quantity,
    String promo = '',
  }) {
    return _guard(
      () => _send(
        'PUT',
        ApiConfig.cartItemUrl(productId),
        body: {'quantity': quantity, 'promo': promo},
      ),
      CartSummary.fromJson,
      'Could not update the quantity',
    );
  }

  static Future<ShopResult<CartSummary>> removeCartItem(
    int productId, {
    String promo = '',
  }) {
    return _guard(
      () => _send(
        'DELETE',
        ApiConfig.cartItemUrl(productId),
        query: {'promo': promo},
      ),
      CartSummary.fromJson,
      'Could not remove the item',
    );
  }

  static Future<ShopResult<CartSummary>> clearCart() {
    return _guard(
      () => _send('DELETE', ApiConfig.cartUrl),
      CartSummary.fromJson,
      'Could not clear your cart',
    );
  }

  /// Recalculates the bill for a promo code without changing the cart.
  static Future<ShopResult<Map<String, dynamic>>> previewBill(String promo) {
    return _guard(
      () => _send('POST', ApiConfig.cartSummaryUrl, body: {'promo': promo}),
      (json) => json,
      'Could not calculate your bill',
    );
  }

  // ==================================================================
  // CHECKOUT + ORDERS
  // ==================================================================

  /// Places the simulated order. No payment is taken - the SRS keeps real
  /// payment and delivery out of scope, so this only saves the bill.
  static Future<ShopResult<Order>> checkout(Map<String, dynamic> payload) {
    return _guard(
      () => _send('POST', ApiConfig.checkoutUrl, body: payload),
      (json) => Order.fromJson(parseMap(json['order']) ?? const {}),
      'Could not place your order',
    );
  }

  static Future<ShopResult<List<Order>>> myOrders() {
    return _guard(
      () => _send('GET', ApiConfig.myOrdersUrl),
      (json) => parseList(json['orders'], Order.fromJson),
      'Could not load your orders',
    );
  }

  static Future<ShopResult<Order>> orderDetails(int orderId) {
    return _guard(
      () => _send('GET', ApiConfig.orderUrl(orderId)),
      (json) => Order.fromJson(parseMap(json['order']) ?? const {}),
      'Order not found',
    );
  }

  static Future<ShopResult<String>> deleteOrder(int orderId) {
    return _guard(
      () => _send('DELETE', ApiConfig.orderUrl(orderId)),
      (json) => json['message']?.toString() ?? 'Order removed',
      'Could not remove the order',
    );
  }
}
