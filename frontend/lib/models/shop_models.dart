/// MEMBER 5 - Merchandise Store
/// Data models mapped from the Node/Express + SQLite shop responses.
library;

import 'json_utils.dart';

// ---------------------------------------------------------------------------
// ProductCategory
// ---------------------------------------------------------------------------
class ProductCategory {
  final int id;
  final String name;
  final String slug;
  final String? icon;
  final String? color;
  final String description;
  final int productCount;
  final int dealCount;
  final double minPrice;

  const ProductCategory({
    required this.id,
    required this.name,
    this.slug = '',
    this.icon,
    this.color,
    this.description = '',
    this.productCount = 0,
    this.dealCount = 0,
    this.minPrice = 0,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: asInt(json['id']),
      name: asString(json['name'], fallback: 'General'),
      slug: asString(json['slug']),
      icon: asNullableString(json['icon']),
      color: asNullableString(json['color']),
      description: asString(json['description']),
      productCount: asInt(json['product_count']),
      dealCount: asInt(json['deal_count']),
      minPrice: asDouble(json['min_price']),
    );
  }
}

// ---------------------------------------------------------------------------
// ProductFandom
// ---------------------------------------------------------------------------
class ProductFandom {
  final String name;
  final int productCount;
  final double minPrice;

  const ProductFandom({
    required this.name,
    this.productCount = 0,
    this.minPrice = 0,
  });

  factory ProductFandom.fromJson(Map<String, dynamic> json) {
    return ProductFandom(
      name: asString(json['name'], fallback: 'Other'),
      productCount: asInt(json['product_count']),
      minPrice: asDouble(json['min_price']),
    );
  }
}

// ---------------------------------------------------------------------------
// Product  (SRS "Merchandise": Product_Id, Name, Price, Image_Url, Category)
// ---------------------------------------------------------------------------
class Product {
  final int id;
  final String name;
  final String sku;
  final String description;
  final String category;
  final String fandom;
  final String brand;

  final double price;
  final double? oldPrice;
  final int discountPercent;
  final String currency;

  final String? imageUrl;
  final int stock;
  final double rating;
  final int ratingCount;
  final int soldCount;

  final bool isFeatured;
  final bool isDigital;
  final bool inStock;
  final bool hasDiscount;
  final double savings;

  /// Per-user state, filled by the catalogue / details endpoints.
  final bool isWishlisted;
  final int quantityInCart;

  const Product({
    required this.id,
    required this.name,
    this.sku = '',
    this.description = '',
    this.category = 'General',
    this.fandom = '',
    this.brand = '',
    this.price = 0,
    this.oldPrice,
    this.discountPercent = 0,
    this.currency = 'USD',
    this.imageUrl,
    this.stock = 0,
    this.rating = 0,
    this.ratingCount = 0,
    this.soldCount = 0,
    this.isFeatured = false,
    this.isDigital = false,
    this.inStock = false,
    this.hasDiscount = false,
    this.savings = 0,
    this.isWishlisted = false,
    this.quantityInCart = 0,
  });

  String get initial =>
      name.trim().isEmpty ? 'P' : name.trim()[0].toUpperCase();

  /// Stock label shown on the product cards / details screen.
  String get stockLabel {
    if (isDigital) return 'Instant download';
    if (stock <= 0) return 'Out of stock';
    if (stock <= 10) return 'Only $stock left';
    return 'In Stock';
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: asInt(json['id']),
      name: asString(json['name'], fallback: 'Untitled product'),
      sku: asString(json['sku']),
      description: asString(json['description']),
      category: asString(json['category'], fallback: 'General'),
      fandom: asString(json['fandom']),
      brand: asString(json['brand']),
      price: asDouble(json['price']),
      oldPrice: asNullableDouble(json['old_price']),
      discountPercent: asInt(json['discount_percent']),
      currency: asString(json['currency'], fallback: 'USD'),
      imageUrl: asNullableString(json['image_url']),
      stock: asInt(json['stock']),
      rating: asDouble(json['rating']),
      ratingCount: asInt(json['rating_count']),
      soldCount: asInt(json['sold_count']),
      isFeatured: asBool(json['is_featured']),
      isDigital: asBool(json['is_digital']),
      inStock: json.containsKey('in_stock')
          ? asBool(json['in_stock'])
          : asInt(json['stock']) > 0,
      hasDiscount: json.containsKey('has_discount')
          ? asBool(json['has_discount'])
          : (asNullableDouble(json['old_price']) ?? 0) >
                asDouble(json['price']),
      savings: asDouble(json['savings']),
      isWishlisted: asBool(json['is_wishlisted']),
      quantityInCart: asInt(json['quantity_in_cart']),
    );
  }

  Product copyWith({
    bool? isWishlisted,
    int? quantityInCart,
    int? stock,
    double? price,
  }) {
    return Product(
      id: id,
      name: name,
      sku: sku,
      description: description,
      category: category,
      fandom: fandom,
      brand: brand,
      price: price ?? this.price,
      oldPrice: oldPrice,
      discountPercent: discountPercent,
      currency: currency,
      imageUrl: imageUrl,
      stock: stock ?? this.stock,
      rating: rating,
      ratingCount: ratingCount,
      soldCount: soldCount,
      isFeatured: isFeatured,
      isDigital: isDigital,
      inStock: (stock ?? this.stock) > 0,
      hasDiscount: hasDiscount,
      savings: savings,
      isWishlisted: isWishlisted ?? this.isWishlisted,
      quantityInCart: quantityInCart ?? this.quantityInCart,
    );
  }
}

// ---------------------------------------------------------------------------
// PriceDrop  (attached to a wishlist item when the price fell)
// ---------------------------------------------------------------------------
class PriceDrop {
  final int productId;
  final String name;
  final String? imageUrl;
  final String currency;
  final double oldPrice;
  final double newPrice;
  final double dropAmount;
  final int dropPercent;

  const PriceDrop({
    required this.productId,
    required this.name,
    this.imageUrl,
    this.currency = 'USD',
    this.oldPrice = 0,
    this.newPrice = 0,
    this.dropAmount = 0,
    this.dropPercent = 0,
  });

  factory PriceDrop.fromJson(Map<String, dynamic> json) {
    return PriceDrop(
      productId: asInt(json['product_id']),
      name: asString(json['name'], fallback: 'Product'),
      imageUrl: asNullableString(json['image_url']),
      currency: asString(json['currency'], fallback: 'USD'),
      oldPrice: asDouble(json['old_price']),
      newPrice: asDouble(json['new_price']),
      dropAmount: asDouble(json['drop_amount']),
      dropPercent: asInt(json['drop_percent']),
    );
  }
}

// ---------------------------------------------------------------------------
// WishlistItem  (SRS "Wishlists": Wish_Id, User_Id, Product_Id, Saved_At)
// ---------------------------------------------------------------------------
class WishlistItem {
  final Product product;
  final int wishId;
  final String savedAt;
  final String savedAgo;
  final double priceAtSave;

  /// current price - price when saved. Negative means it got cheaper.
  final double priceChange;
  final bool hasPriceDrop;
  final PriceDrop? priceDrop;

  const WishlistItem({
    required this.product,
    this.wishId = 0,
    this.savedAt = '',
    this.savedAgo = '',
    this.priceAtSave = 0,
    this.priceChange = 0,
    this.hasPriceDrop = false,
    this.priceDrop,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    final drop = parseMap(json['price_drop']);

    return WishlistItem(
      product: Product.fromJson({...json, 'is_wishlisted': 1}),
      wishId: asInt(json['wish_id']),
      savedAt: asString(json['saved_at']),
      savedAgo: asString(json['saved_ago']),
      priceAtSave: asDouble(json['price_at_save']),
      priceChange: asDouble(json['price_change']),
      hasPriceDrop: asBool(json['has_price_drop']),
      priceDrop: drop == null ? null : PriceDrop.fromJson(drop),
    );
  }

  WishlistItem copyWith({Product? product, bool? hasPriceDrop}) {
    return WishlistItem(
      product: product ?? this.product,
      wishId: wishId,
      savedAt: savedAt,
      savedAgo: savedAgo,
      priceAtSave: priceAtSave,
      priceChange: priceChange,
      hasPriceDrop: hasPriceDrop ?? this.hasPriceDrop,
      priceDrop: priceDrop,
    );
  }
}

// ---------------------------------------------------------------------------
// CartLine
// ---------------------------------------------------------------------------
class CartLine {
  final int cartItemId;
  final int productId;
  final String name;
  final double price;
  final double? oldPrice;
  final String currency;
  final String? imageUrl;
  final String category;
  final String fandom;
  final String brand;
  final int stock;
  final bool isDigital;
  final int discountPercent;
  final int quantity;
  final double lineTotal;

  const CartLine({
    required this.cartItemId,
    required this.productId,
    required this.name,
    this.price = 0,
    this.oldPrice,
    this.currency = 'USD',
    this.imageUrl,
    this.category = '',
    this.fandom = '',
    this.brand = '',
    this.stock = 0,
    this.isDigital = false,
    this.discountPercent = 0,
    this.quantity = 1,
    this.lineTotal = 0,
  });

  /// Largest quantity the user may select for this line.
  int get maxQuantity => isDigital ? 99 : (stock > 0 ? stock : 1);

  factory CartLine.fromJson(Map<String, dynamic> json) {
    return CartLine(
      cartItemId: asInt(json['cart_item_id']),
      productId: asInt(json['product_id']),
      name: asString(json['name'], fallback: 'Product'),
      price: asDouble(json['price']),
      oldPrice: asNullableDouble(json['old_price']),
      currency: asString(json['currency'], fallback: 'USD'),
      imageUrl: asNullableString(json['image_url']),
      category: asString(json['category']),
      fandom: asString(json['fandom']),
      brand: asString(json['brand']),
      stock: asInt(json['stock']),
      isDigital: asBool(json['is_digital']),
      discountPercent: asInt(json['discount_percent']),
      quantity: asInt(json['quantity']),
      lineTotal: asDouble(json['line_total']),
    );
  }
}

// ---------------------------------------------------------------------------
// CartSummary  (the simulated bill shown on Cart + Checkout)
// ---------------------------------------------------------------------------
class CartSummary {
  final List<CartLine> items;
  final int itemCount;
  final double subtotal;
  final double discount;
  final String? discountLabel;
  final double shippingFee;
  final bool freeShipping;
  final double freeShippingThreshold;
  final String shippingNote;
  final String? promoCode;
  final String? promoLabel;
  final String? promoError;
  final double total;
  final String currency;
  final bool hasDigital;
  final bool hasPhysical;

  const CartSummary({
    this.items = const [],
    this.itemCount = 0,
    this.subtotal = 0,
    this.discount = 0,
    this.discountLabel,
    this.shippingFee = 0,
    this.freeShipping = false,
    this.freeShippingThreshold = 75,
    this.shippingNote = '',
    this.promoCode,
    this.promoLabel,
    this.promoError,
    this.total = 0,
    this.currency = 'USD',
    this.hasDigital = false,
    this.hasPhysical = false,
  });

  bool get isEmpty => items.isEmpty;

  factory CartSummary.fromJson(Map<String, dynamic> json) {
    return CartSummary(
      items: parseList(json['items'], CartLine.fromJson),
      itemCount: asInt(json['item_count']),
      subtotal: asDouble(json['subtotal']),
      discount: asDouble(json['discount']),
      discountLabel: asNullableString(json['discount_label']),
      shippingFee: asDouble(json['shipping_fee']),
      freeShipping: asBool(json['free_shipping']),
      freeShippingThreshold: asDouble(json['free_shipping_threshold']),
      shippingNote: asString(json['shipping_note']),
      promoCode: asNullableString(json['promo_code']),
      promoLabel: asNullableString(json['promo_label']),
      promoError: asNullableString(json['promo_error']),
      total: asDouble(json['total']),
      currency: asString(json['currency'], fallback: 'USD'),
      hasDigital: asBool(json['has_digital']),
      hasPhysical: asBool(json['has_physical']),
    );
  }
}

// ---------------------------------------------------------------------------
// PromoCode / payment method metadata returned by the bill preview
// ---------------------------------------------------------------------------
class PromoCode {
  final String code;
  final String label;
  final double minSubtotal;

  const PromoCode({required this.code, this.label = '', this.minSubtotal = 0});

  factory PromoCode.fromJson(Map<String, dynamic> json) {
    return PromoCode(
      code: asString(json['code']),
      label: asString(json['label']),
      minSubtotal: asDouble(json['min_subtotal']),
    );
  }
}

// ---------------------------------------------------------------------------
// PriceAlert  (the notification history for price drops)
// ---------------------------------------------------------------------------
class PriceAlert {
  final int id;
  final int productId;
  final String name;
  final String? imageUrl;
  final String currency;
  final double oldPrice;
  final double newPrice;
  final double dropAmount;
  final int dropPercent;
  final double currentPrice;
  final bool isSeen;
  final String createdAt;
  final String createdAgo;

  const PriceAlert({
    required this.id,
    required this.productId,
    required this.name,
    this.imageUrl,
    this.currency = 'USD',
    this.oldPrice = 0,
    this.newPrice = 0,
    this.dropAmount = 0,
    this.dropPercent = 0,
    this.currentPrice = 0,
    this.isSeen = false,
    this.createdAt = '',
    this.createdAgo = '',
  });

  factory PriceAlert.fromJson(Map<String, dynamic> json) {
    return PriceAlert(
      id: asInt(json['id']),
      productId: asInt(json['product_id']),
      name: asString(json['name'], fallback: 'Product'),
      imageUrl: asNullableString(json['image_url']),
      currency: asString(json['currency'], fallback: 'USD'),
      oldPrice: asDouble(json['old_price']),
      newPrice: asDouble(json['new_price']),
      dropAmount: asDouble(json['drop_amount']),
      dropPercent: asInt(json['drop_percent']),
      currentPrice: asDouble(json['current_price']),
      isSeen: asBool(json['is_seen']),
      createdAt: asString(json['created_at']),
      createdAgo: asString(json['created_ago']),
    );
  }
}

// ---------------------------------------------------------------------------
// OrderLine
// ---------------------------------------------------------------------------
class OrderLine {
  final int productId;
  final String name;
  final String? imageUrl;
  final double unitPrice;
  final int quantity;
  final double lineTotal;

  const OrderLine({
    required this.productId,
    required this.name,
    this.imageUrl,
    this.unitPrice = 0,
    this.quantity = 1,
    this.lineTotal = 0,
  });

  factory OrderLine.fromJson(Map<String, dynamic> json) {
    return OrderLine(
      productId: asInt(json['product_id']),
      name: asString(json['name'], fallback: 'Product'),
      imageUrl: asNullableString(json['image_url']),
      unitPrice: asDouble(json['unit_price']),
      quantity: asInt(json['quantity']),
      lineTotal: asDouble(json['line_total']),
    );
  }
}

// ---------------------------------------------------------------------------
// Order  (simulated checkout result - the SRS "bill")
// ---------------------------------------------------------------------------
class Order {
  final int id;
  final String orderCode;
  final int itemCount;
  final double subtotal;
  final double discount;
  final double shippingFee;
  final double total;
  final String currency;
  final String status;
  final String paymentMethod;
  final String? shippingName;
  final String? shippingPhone;
  final String? shippingCity;
  final String? shippingAddress;
  final String? note;
  final String? promoCode;
  final String placedAt;
  final String placedAgo;

  /// Only present on the list endpoint (a compact preview).
  final String? previewName;
  final String? previewImage;
  final int lineCount;
  final int additionalItems;

  /// Only present on the details endpoint.
  final List<OrderLine> items;
  final int? buyAgainProductId;

  const Order({
    required this.id,
    required this.orderCode,
    this.itemCount = 0,
    this.subtotal = 0,
    this.discount = 0,
    this.shippingFee = 0,
    this.total = 0,
    this.currency = 'USD',
    this.status = 'placed',
    this.paymentMethod = 'Cash on Delivery (simulated)',
    this.shippingName,
    this.shippingPhone,
    this.shippingCity,
    this.shippingAddress,
    this.note,
    this.promoCode,
    this.placedAt = '',
    this.placedAgo = '',
    this.previewName,
    this.previewImage,
    this.lineCount = 0,
    this.additionalItems = 0,
    this.items = const [],
    this.buyAgainProductId,
  });

  /// "placed" -> "Placed", "delivered" -> "Delivered"
  String get statusLabel =>
      status.isEmpty ? 'Placed' : status[0].toUpperCase() + status.substring(1);

  String get shortCode => orderCode.isEmpty ? '#$id' : orderCode;

  factory Order.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];

    return Order(
      id: asInt(json['id']),
      orderCode: asString(json['order_code']),
      itemCount: asInt(json['item_count']),
      subtotal: asDouble(json['subtotal']),
      discount: asDouble(json['discount']),
      shippingFee: asDouble(json['shipping_fee']),
      total: asDouble(json['total']),
      currency: asString(json['currency'], fallback: 'USD'),
      status: asString(json['status'], fallback: 'placed'),
      paymentMethod: asString(
        json['payment_method'],
        fallback: 'Cash on Delivery (simulated)',
      ),
      shippingName: asNullableString(json['shipping_name']),
      shippingPhone: asNullableString(json['shipping_phone']),
      shippingCity: asNullableString(json['shipping_city']),
      shippingAddress: asNullableString(json['shipping_address']),
      note: asNullableString(json['note']),
      promoCode: asNullableString(json['promo_code']),
      placedAt: asString(json['placed_at']),
      placedAgo: asString(json['placed_ago']),
      previewName: asNullableString(json['preview_name']),
      previewImage: asNullableString(json['preview_image']),
      lineCount: asInt(json['line_count']),
      additionalItems: asInt(json['additional_items']),
      items: parseList(rawItems, OrderLine.fromJson),
      buyAgainProductId: asNullableInt(json['buy_again_product_id']),
    );
  }
}

// ---------------------------------------------------------------------------
// ShopStats / ShopOverview
// ---------------------------------------------------------------------------
class ShopStats {
  final int totalProducts;
  final int totalCategories;
  final int outOfStock;
  final int totalDeals;
  final int totalSold;
  final int wishlistCount;
  final int cartCount;
  final int cartQuantity;
  final int ordersCount;

  const ShopStats({
    this.totalProducts = 0,
    this.totalCategories = 0,
    this.outOfStock = 0,
    this.totalDeals = 0,
    this.totalSold = 0,
    this.wishlistCount = 0,
    this.cartCount = 0,
    this.cartQuantity = 0,
    this.ordersCount = 0,
  });

  factory ShopStats.fromJson(Map<String, dynamic> json) {
    return ShopStats(
      totalProducts: asInt(json['total_products']),
      totalCategories: asInt(json['total_categories']),
      outOfStock: asInt(json['out_of_stock']),
      totalDeals: asInt(json['total_deals']),
      totalSold: asInt(json['total_sold']),
      wishlistCount: asInt(json['wishlist_count']),
      cartCount: asInt(json['cart_count']),
      cartQuantity: asInt(json['cart_quantity']),
      ordersCount: asInt(json['orders_count']),
    );
  }
}

class ShopShippingRules {
  final double flatFee;
  final double freeThreshold;
  final String currency;

  const ShopShippingRules({
    this.flatFee = 6.99,
    this.freeThreshold = 75,
    this.currency = 'USD',
  });

  factory ShopShippingRules.fromJson(Map<String, dynamic> json) {
    return ShopShippingRules(
      flatFee: asDouble(json['flat_fee']),
      freeThreshold: asDouble(json['free_threshold']),
      currency: asString(json['currency'], fallback: 'USD'),
    );
  }
}

class ShopOverview {
  final ShopStats stats;
  final List<ProductCategory> categories;
  final List<Product> featured;
  final List<Product> deals;
  final List<Product> newArrivals;
  final List<Product> bestSellers;
  final List<PromoCode> promoCodes;
  final ShopShippingRules shipping;

  const ShopOverview({
    this.stats = const ShopStats(),
    this.categories = const [],
    this.featured = const [],
    this.deals = const [],
    this.newArrivals = const [],
    this.bestSellers = const [],
    this.promoCodes = const [],
    this.shipping = const ShopShippingRules(),
  });

  factory ShopOverview.fromJson(Map<String, dynamic> json) {
    return ShopOverview(
      stats: ShopStats.fromJson(parseMap(json['stats']) ?? const {}),
      categories: parseList(json['categories'], ProductCategory.fromJson),
      featured: parseList(json['featured'], Product.fromJson),
      deals: parseList(json['deals'], Product.fromJson),
      newArrivals: parseList(json['new_arrivals'], Product.fromJson),
      bestSellers: parseList(json['best_sellers'], Product.fromJson),
      promoCodes: parseList(json['promo_codes'], PromoCode.fromJson),
      shipping: ShopShippingRules.fromJson(
        parseMap(json['shipping']) ?? const {},
      ),
    );
  }
}
