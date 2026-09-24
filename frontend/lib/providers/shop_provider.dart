import 'package:flutter/material.dart';

import '../models/shop_models.dart';
import '../services/auth_storage.dart';
import '../services/shop_service.dart';

/// MEMBER 5 - Merchandise Store
/// Holds all state used by the Shop Home, Product Details, Wishlist, Cart,
/// Checkout, Order Success and Orders screens.
class ShopProvider extends ChangeNotifier {
  // ----------------------------- state -----------------------------
  bool _loading = false;
  bool _loadingProducts = false;
  bool _loadingPersonal = false;
  String? _errorMessage;

  ShopOverview _overview = const ShopOverview();
  List<ProductCategory> _categories = [];
  List<ProductFandom> _fandoms = [];
  List<Product> _products = [];

  List<WishlistItem> _wishlist = [];
  double _wishlistValue = 0;
  double _wishlistSavings = 0;
  int _wishlistDrops = 0;
  List<PriceAlert> _priceAlerts = [];

  CartSummary _cart = const CartSummary();
  List<Order> _orders = [];
  double _totalSpent = 0;

  // filters
  String _category = 'All';
  String _fandom = 'All';
  String _query = '';
  String _sort = 'featured';
  bool _inStockOnly = false;
  bool _discountedOnly = false;

  // checkout
  String _promoInput = '';
  String? _promoMessage;
  bool _promoIsError = false;

  // ---------------------------- getters ----------------------------
  bool get loading => _loading;
  bool get loadingProducts => _loadingProducts;
  bool get loadingPersonal => _loadingPersonal;
  String? get errorMessage => _errorMessage;

  ShopOverview get overview => _overview;
  ShopStats get stats => _overview.stats;
  List<ProductCategory> get categories => _categories;
  List<ProductFandom> get fandoms => _fandoms;
  List<Product> get products => _products;

  List<Product> get featured => _overview.featured;
  List<Product> get deals => _overview.deals;
  List<Product> get newArrivals => _overview.newArrivals;
  List<Product> get bestSellers => _overview.bestSellers;
  List<PromoCode> get promoCodes => _overview.promoCodes;
  ShopShippingRules get shipping => _overview.shipping;

  List<WishlistItem> get wishlist => _wishlist;
  double get wishlistValue => _wishlistValue;
  double get wishlistSavings => _wishlistSavings;
  int get wishlistDrops => _wishlistDrops;
  List<PriceAlert> get priceAlerts => _priceAlerts;

  CartSummary get cart => _cart;
  List<Order> get orders => _orders;
  double get totalSpent => _totalSpent;

  String get category => _category;
  String get fandom => _fandom;
  String get query => _query;
  String get sort => _sort;
  bool get inStockOnly => _inStockOnly;
  bool get discountedOnly => _discountedOnly;

  String get promoInput => _promoInput;
  String? get promoMessage => _promoMessage;
  bool get promoIsError => _promoIsError;

  /// Badge counters used by the dashboard + bottom navigation.
  int get wishlistCount => _wishlist.length;
  int get cartQuantity => _cart.itemCount;
  int get cartLineCount => _cart.items.length;
  int get ordersCount => _orders.length;

  bool get hasActiveFilters =>
      _category != 'All' ||
      _fandom != 'All' ||
      _query.isNotEmpty ||
      _inStockOnly ||
      _discountedOnly ||
      _sort != 'featured';

  /// Products on the current filtered result set.
  int get resultCount => _products.length;

  // ---------------------------- helpers ----------------------------
  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ==================================================================
  // SHOP HOME / CATALOGUE
  // ==================================================================

  /// Loads the Shop Home payload (stats, categories, merchandising rows).
  Future<void> loadOverview({bool silent = false}) async {
    if (!silent) _setLoading(true);

    final result = await ShopService.overview();

    if (result.success && result.data != null) {
      _overview = result.data!;
      _categories = result.data!.categories;
      _errorMessage = null;
    } else {
      _errorMessage = result.message;
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> loadFilters() async {
    final categoryResult = await ShopService.categories();
    final fandomResult = await ShopService.fandoms();

    if (categoryResult.success && categoryResult.data != null) {
      _categories = categoryResult.data!;
    }
    if (fandomResult.success && fandomResult.data != null) {
      _fandoms = fandomResult.data!;
    }
    notifyListeners();
  }

  /// Catalogue with filters + price sorting (SRS requirement).
  Future<void> loadProducts({bool silent = false}) async {
    if (!silent) {
      _loadingProducts = true;
      notifyListeners();
    }

    final result = await ShopService.products(
      category: _category,
      fandom: _fandom,
      query: _query,
      sort: _sort,
      inStockOnly: _inStockOnly,
      discountedOnly: _discountedOnly,
      limit: 60,
    );

    if (result.success && result.data != null) {
      _products = result.data!;
      _errorMessage = null;
    } else {
      _errorMessage = result.message;
    }

    _loadingProducts = false;
    notifyListeners();
  }

  /// Used by the Shop Home category chips: tapping a category both filters the
  /// catalogue and switches to the product list.
  Future<void> selectCategory(String value) async {
    _category = value;
    _loadingProducts = true;
    notifyListeners();
    await loadProducts(silent: true);
  }

  Future<void> selectFandom(String value) async {
    _fandom = value;
    _loadingProducts = true;
    notifyListeners();
    await loadProducts(silent: true);
  }

  Future<void> selectSort(String value) async {
    _sort = value;
    _loadingProducts = true;
    notifyListeners();
    await loadProducts(silent: true);
  }

  Future<void> search(String value) async {
    _query = value;
    _loadingProducts = true;
    notifyListeners();
    await loadProducts(silent: true);
  }

  Future<void> toggleInStockOnly() async {
    _inStockOnly = !_inStockOnly;
    _loadingProducts = true;
    notifyListeners();
    await loadProducts(silent: true);
  }

  Future<void> toggleDiscountedOnly() async {
    _discountedOnly = !_discountedOnly;
    _loadingProducts = true;
    notifyListeners();
    await loadProducts(silent: true);
  }

  Future<void> resetFilters() async {
    _category = 'All';
    _fandom = 'All';
    _query = '';
    _sort = 'featured';
    _inStockOnly = false;
    _discountedOnly = false;
    _loadingProducts = true;
    notifyListeners();
    await loadProducts(silent: true);
  }

  /// Product details + related products. Returns the raw map so the details
  /// screen can read `related` and `category_average_rating` as well.
  Future<ShopResult<Map<String, dynamic>>> loadProductDetails(int productId) {
    return ShopService.productDetails(productId);
  }

  // ==================================================================
  // PERSONAL DATA (needs a token)
  // ==================================================================

  /// Loads wishlist + cart + orders together. Safe to call when signed out -
  /// it simply clears the personal state instead of showing an error.
  Future<void> loadPersonal({bool silent = false}) async {
    if (!await AuthStorage.isLoggedIn()) {
      _wishlist = [];
      _cart = const CartSummary();
      _orders = [];
      _wishlistValue = 0;
      _wishlistSavings = 0;
      _wishlistDrops = 0;
      notifyListeners();
      return;
    }

    if (!silent) _setLoadingPersonal(true);

    await Future.wait([
      loadCart(silent: true),
      loadWishlist(silent: true),
      loadOrders(silent: true),
    ]);

    _loadingPersonal = false;
    notifyListeners();
  }

  void _setLoadingPersonal(bool value) {
    _loadingPersonal = value;
    notifyListeners();
  }

  // ------------------------------ wishlist ------------------------------

  Future<void> loadWishlist({bool silent = false}) async {
    if (!await AuthStorage.isLoggedIn()) return;

    final result = await ShopService.wishlist();

    if (result.success && result.data != null) {
      final json = result.data!;
      _wishlist = (json['items'] as List? ?? [])
          .whereType<Map>()
          .map((item) => WishlistItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      _wishlistValue = (json['total_value'] as num?)?.toDouble() ?? 0;
      _wishlistSavings = (json['total_savings'] as num?)?.toDouble() ?? 0;
      _wishlistDrops = (json['price_drops'] as num?)?.toInt() ?? 0;
    }

    if (!silent) notifyListeners();
  }

  /// Heart button handler. Returns the resulting state so the UI can show the
  /// right snack bar ("added" / "removed").
  Future<bool?> toggleWishlist(Product product) async {
    if (!await AuthStorage.isLoggedIn()) {
      _errorMessage = 'Please log in to save items to your wishlist';
      notifyListeners();
      return null;
    }

    final result = await ShopService.toggleWishlist(product.id);

    if (!result.success || result.data == null) {
      _errorMessage = result.message;
      notifyListeners();
      return null;
    }

    final wishlisted = result.data!;

    // Update every list that shows this product so all screens stay in sync.
    _products = _products
        .map(
          (item) => item.id == product.id
              ? item.copyWith(isWishlisted: wishlisted)
              : item,
        )
        .toList();

    // Keep the merchandising rows in sync too.
    Product toggle(Product item) =>
        item.id == product.id ? item.copyWith(isWishlisted: wishlisted) : item;

    _overview = ShopOverview(
      stats: _overview.stats,
      categories: _overview.categories,
      featured: _overview.featured.map(toggle).toList(),
      deals: _overview.deals.map(toggle).toList(),
      newArrivals: _overview.newArrivals.map(toggle).toList(),
      bestSellers: _overview.bestSellers.map(toggle).toList(),
      promoCodes: _overview.promoCodes,
      shipping: _overview.shipping,
    );

    await loadWishlist(silent: true);

    _errorMessage = null;
    notifyListeners();
    return wishlisted;
  }

  Future<String?> removeFromWishlist(int productId) async {
    final result = await ShopService.removeFromWishlist(productId);

    if (!result.success) {
      _errorMessage = result.message;
      notifyListeners();
      return null;
    }

    _wishlist = _wishlist
        .where((item) => item.product.id != productId)
        .toList();
    _products = _products
        .map(
          (item) =>
              item.id == productId ? item.copyWith(isWishlisted: false) : item,
        )
        .toList();

    notifyListeners();
    return result.data;
  }

  Future<String?> clearWishlist() async {
    final result = await ShopService.clearWishlist();

    if (!result.success) {
      _errorMessage = result.message;
      notifyListeners();
      return null;
    }

    _wishlist = [];
    _wishlistValue = 0;
    _wishlistSavings = 0;
    _wishlistDrops = 0;
    _products = _products
        .map((item) => item.copyWith(isWishlisted: false))
        .toList();

    notifyListeners();
    return result.data;
  }

  /// Runs the price-drop detection. Returns the number of drops found and the
  /// human message so the screen can show a snack bar.
  Future<({int count, String message})> checkPriceAlerts() async {
    if (!await AuthStorage.isLoggedIn()) {
      return (count: 0, message: 'Log in to track prices');
    }

    final result = await ShopService.checkPriceAlerts();

    if (!result.success || result.data == null) {
      return (count: 0, message: result.message);
    }

    final count = (result.data!['price_drops'] as num?)?.toInt() ?? 0;
    final message = result.data!['message']?.toString() ?? '';

    // Always refresh: the strips come from the current drop list, not from the
    // number of alerts that were written on this pass.
    await loadWishlist(silent: true);

    notifyListeners();
    return (count: count, message: message);
  }

  Future<void> loadPriceAlerts() async {
    final result = await ShopService.priceAlerts();
    if (result.success && result.data != null) {
      _priceAlerts = result.data!;
      notifyListeners();
    }
  }

  // -------------------------------- cart --------------------------------

  Future<void> loadCart({bool silent = false}) async {
    if (!await AuthStorage.isLoggedIn()) return;

    final result = await ShopService.cart(promo: _cart.promoCode ?? '');

    if (result.success && result.data != null) {
      _cart = result.data!;
    }
    if (!silent) notifyListeners();
  }

  Future<String?> addToCart(Product product, {int quantity = 1}) async {
    if (!await AuthStorage.isLoggedIn()) {
      _errorMessage = 'Please log in to add items to your cart';
      notifyListeners();
      return null;
    }

    final result = await ShopService.addToCart(
      product.id,
      quantity: quantity,
      promo: _cart.promoCode ?? '',
    );

    if (!result.success || result.data == null) {
      _errorMessage = result.message;
      notifyListeners();
      return null;
    }

    _cart = result.data!;
    _applyProductFlags();

    notifyListeners();
    return result.message;
  }

  Future<String?> updateCartQuantity(int productId, int quantity) async {
    final result = await ShopService.updateCartItem(
      productId,
      quantity: quantity,
      promo: _cart.promoCode ?? '',
    );

    if (!result.success || result.data == null) {
      _errorMessage = result.message;
      notifyListeners();
      return null;
    }

    _cart = result.data!;
    _applyProductFlags();

    notifyListeners();
    return result.message;
  }

  Future<String?> removeFromCart(int productId) async {
    final result = await ShopService.removeCartItem(
      productId,
      promo: _cart.promoCode ?? '',
    );

    if (!result.success || result.data == null) {
      _errorMessage = result.message;
      notifyListeners();
      return null;
    }

    _cart = result.data!;
    _applyProductFlags();

    notifyListeners();
    return result.message;
  }

  Future<String?> clearCart() async {
    final result = await ShopService.clearCart();

    if (!result.success || result.data == null) {
      _errorMessage = result.message;
      notifyListeners();
      return null;
    }

    _cart = result.data!;
    _applyProductFlags();

    notifyListeners();
    return result.data!.isEmpty ? 'Cart cleared' : null;
  }

  /// Mirrors the cart quantities onto the loaded product lists so the cards
  /// show their "in cart" badge without another request.
  void _applyProductFlags() {
    final quantityByProduct = {
      for (final line in _cart.items) line.productId: line.quantity,
    };

    Product flag(Product item) => quantityByProduct.containsKey(item.id)
        ? item.copyWith(quantityInCart: quantityByProduct[item.id])
        : item.copyWith(quantityInCart: 0);

    _products = _products.map(flag).toList();

    _overview = ShopOverview(
      stats: _overview.stats,
      categories: _overview.categories,
      featured: _overview.featured.map(flag).toList(),
      deals: _overview.deals.map(flag).toList(),
      newArrivals: _overview.newArrivals.map(flag).toList(),
      bestSellers: _overview.bestSellers.map(flag).toList(),
      promoCodes: _overview.promoCodes,
      shipping: _overview.shipping,
    );
  }

  void setPromoInput(String value) {
    _promoInput = value;
    notifyListeners();
  }

  /// Validates a promo code through the server so the checkout preview always
  /// matches what the order will actually charge.
  Future<({bool ok, String message})> applyPromo() async {
    final code = _promoInput.trim().toUpperCase();

    if (code.isEmpty) {
      _promoMessage = 'Enter a promo code first';
      _promoIsError = true;
      notifyListeners();
      return (ok: false, message: _promoMessage!);
    }

    final result = await ShopService.previewBill(code);

    if (!result.success || result.data == null) {
      _promoMessage = result.message;
      _promoIsError = true;
      notifyListeners();
      return (ok: false, message: result.message);
    }

    final json = result.data!;

    if (json['promo_valid'] == false) {
      _promoMessage = json['promo_error']?.toString() ?? 'Invalid promo code';
      _promoIsError = true;
      notifyListeners();
      return (ok: false, message: _promoMessage!);
    }

    _cart = CartSummary.fromJson(json);
    _promoMessage = json['promo_label']?.toString() ?? 'Promo applied';
    _promoIsError = false;

    notifyListeners();
    return (ok: true, message: _promoMessage!);
  }

  Future<void> removePromo() async {
    _promoInput = '';
    _promoMessage = null;
    _promoIsError = false;
    await loadCart(silent: true);
    notifyListeners();
  }

  // ---------------------------- checkout ----------------------------

  /// Places the simulated order and returns it so the success screen can show
  /// the order code and the bill.
  Future<({Order? order, String message})> checkout({
    String? shippingName,
    String? shippingPhone,
    String? shippingCity,
    String? shippingAddress,
    String? note,
    String? paymentMethod,
  }) async {
    final payload = <String, dynamic>{
      if (shippingName != null) 'shipping_name': shippingName,
      if (shippingPhone != null) 'shipping_phone': shippingPhone,
      if (shippingCity != null) 'shipping_city': shippingCity,
      if (shippingAddress != null) 'shipping_address': shippingAddress,
      if (note != null && note.isNotEmpty) 'note': note,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (_cart.promoCode != null) 'promo': _cart.promoCode,
    };

    final result = await ShopService.checkout(payload);

    if (!result.success || result.data == null) {
      return (order: null, message: result.message);
    }

    final order = result.data!;

    // The cart is empty server side now - reset the local copy and refresh the
    // catalogue so stock levels reflect the order.
    _cart = const CartSummary();
    _promoInput = '';
    _promoMessage = null;
    _applyProductFlags();

    await loadOrders(silent: true);
    await loadOverview(silent: true);
    await loadProducts(silent: true);

    notifyListeners();
    return (order: order, message: 'Order placed successfully');
  }

  // ----------------------------- orders -----------------------------

  Future<void> loadOrders({bool silent = false}) async {
    if (!await AuthStorage.isLoggedIn()) return;

    final result = await ShopService.myOrders();

    if (result.success && result.data != null) {
      _orders = result.data!;
      _totalSpent = _orders.fold(0.0, (sum, order) => sum + order.total);
    }
    if (!silent) notifyListeners();
  }

  Future<Order?> orderDetails(int orderId) async {
    final result = await ShopService.orderDetails(orderId);
    return result.success ? result.data : null;
  }

  Future<String?> deleteOrder(int orderId) async {
    final result = await ShopService.deleteOrder(orderId);

    if (!result.success) {
      _errorMessage = result.message;
      notifyListeners();
      return null;
    }

    _orders = _orders.where((order) => order.id != orderId).toList();
    _totalSpent = _orders.fold(0.0, (sum, order) => sum + order.total);

    notifyListeners();
    return result.data;
  }

  /// "Buy again" from the Order Success screen.
  Future<String?> buyAgain(int productId) async {
    final product = _products.firstWhere(
      (item) => item.id == productId,
      orElse: () => Product(id: productId, name: 'Item'),
    );
    return addToCart(product);
  }
}
