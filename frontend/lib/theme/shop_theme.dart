import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// MEMBER 5 - Merchandise Store + AI Fan Helper
///
/// The Shop keeps the shared FANDOM VERSE purple/pink brand (that is what the
/// design board shows for the storefront) and adds two functional accents:
///   * gold  -> prices
///   * green -> stock / success
///   * cyan  -> the AI Fan Helper
class ShopTheme {
  // ------------------------------- brand -------------------------------
  static const Color primary = Color(0xFF7C3AED); // electric purple
  static const Color primaryDark = Color(0xFF5B21B6);
  static const Color secondary = Color(0xFFEC4899); // neon pink
  static const Color accent = Color(0xFF06B6D4); // cyan (AI)

  // ---------------------------- functional ----------------------------
  static const Color gold = Color(0xFFFBBF24); // prices
  static const Color green = Color(0xFF10B981); // in stock / success
  static const Color red = Color(0xFFEF4444); // out of stock / errors
  static const Color orange = Color(0xFFF97316); // deal badges

  // ------------------------------ surfaces ------------------------------
  static const Color surface = Color(0xFF151C2C);
  static const Color surfaceLight = Color(0xFF1E293B);
  static const Color surfaceUltra = Color(0xFF232C42);
  static const Color border = Color(0x14FFFFFF);

  // ------------------------------ gradients ------------------------------
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF7C3AED), Color(0xFF9333EA), Color(0xFFA855F7)],
  );

  /// The "Add to Cart" / "Confirm Order" button gradient.
  static const LinearGradient buyGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
  );

  static const LinearGradient dealGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFF97316), Color(0xFFEC4899)],
  );

  static const LinearGradient aiGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF06B6D4), Color(0xFF7C3AED)],
  );

  static const LinearGradient priceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
  );

  // ------------------------------- helpers -------------------------------
  /// "#F59E0B" -> Color
  static Color fromHex(String? hex, {Color fallback = primary}) {
    if (hex == null || hex.isEmpty) return fallback;
    final value = int.tryParse('FF${hex.replaceFirst('#', '')}', radix: 16);
    return value == null ? fallback : Color(value);
  }

  /// Colour per product category - matches `product_categories.color`.
  static Color categoryColor(String? category) {
    switch (category) {
      case 'Figures':
        return const Color(0xFFF59E0B);
      case 'Shirts':
        return const Color(0xFF8B5CF6);
      case 'Collections':
        return const Color(0xFF06B6D4);
      case 'Accessories':
        return const Color(0xFF10B981);
      case 'Digital Assets':
        return const Color(0xFFEC4899);
      default:
        return primary;
    }
  }

  /// Material icon per product category.
  static IconData categoryIcon(String? category) {
    switch (category) {
      case 'Figures':
        return Icons.toys_rounded;
      case 'Shirts':
        return Icons.checkroom_rounded;
      case 'Collections':
        return Icons.inventory_2_rounded;
      case 'Accessories':
        return Icons.watch_rounded;
      case 'Digital Assets':
        return Icons.cloud_download_rounded;
      default:
        return Icons.shopping_bag_rounded;
    }
  }

  /// Material icon from the icon name stored in `product_categories.icon`.
  static IconData iconFor(String? name) {
    switch (name) {
      case 'toys_rounded':
        return Icons.toys_rounded;
      case 'checkroom_rounded':
        return Icons.checkroom_rounded;
      case 'inventory_2_rounded':
        return Icons.inventory_2_rounded;
      case 'watch_rounded':
        return Icons.watch_rounded;
      case 'cloud_download_rounded':
        return Icons.cloud_download_rounded;
      default:
        return Icons.shopping_bag_rounded;
    }
  }

  /// Bundled artwork for the Shop Home hero/banner rows.
  static const String heroBanner = 'assets/images/shop/shop_hero.jpg';
  static const String dealsBanner = 'assets/images/shop/shop_deals.jpg';
  static const String newArrivalsBanner = 'assets/images/shop/shop_new.jpg';
  static const String digitalBanner = 'assets/images/shop/shop_digital.jpg';

  /// Fallback artwork when a product has no usable image_url.
  static const String fallbackProductImage =
      'assets/images/products/luffy_gear5_figure.jpg';

  /// True when the value points at a bundled asset rather than a URL.
  static bool isAsset(String? path) =>
      path != null && path.isNotEmpty && path.startsWith('assets/');

  /// True when the value is a remote image.
  static bool isRemote(String? path) =>
      path != null &&
      (path.startsWith('http://') || path.startsWith('https://'));

  /// Shared card decoration for the Shop module.
  static BoxDecoration card({Color? borderColor, double radius = 18}) {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? border),
    );
  }

  /// 29.99 + "USD" -> "$29.99";  3999 + "PKR" -> "Rs 3,999"
  static String formatPrice(double? price, {String currency = 'USD'}) {
    final value = price ?? 0;
    final decimals = value == value.roundToDouble() ? 0 : 2;

    final number = value.toStringAsFixed(decimals);
    final parts = number.split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (match) => '${match[1]},',
    );
    final formatted = parts.length > 1 ? '$whole.${parts[1]}' : whole;

    switch (currency.toUpperCase()) {
      case 'USD':
      case 'DOLLAR':
        return '\$$formatted';
      case 'PKR':
        return 'Rs $formatted';
      case 'EUR':
        return '€$formatted';
      case 'GBP':
        return '£$formatted';
      default:
        return '$currency $formatted';
    }
  }

  /// Large whole-number part used for the split price display on cards.
  static String priceWhole(double? price) {
    final value = price ?? 0;
    return value.toStringAsFixed(2).split('.')[0];
  }

  /// Decimal part ("99").
  static String priceCents(double? price) {
    final value = price ?? 0;
    final parts = value.toStringAsFixed(2).split('.');
    return parts.length > 1 ? parts[1] : '00';
  }

  /// 4.8 -> one filled star count out of 5 for compact rating rows.
  static int fullStars(double rating) => rating.round().clamp(0, 5);

  /// "2026-09-24 19:38:56" -> "24 Sep 2026"
  static String prettyDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final normalised = iso.contains('T') ? iso : iso.replaceFirst(' ', 'T');
    final date = DateTime.tryParse(normalised);
    if (date == null) return iso;

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// "2026-09-24 19:38:56" -> "24 Sep, 7:38 PM"
  static String prettyDateTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final normalised = iso.contains('T') ? iso : iso.replaceFirst(' ', 'T');
    final date = DateTime.tryParse(normalised);
    if (date == null) return iso;

    final hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final suffix = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');

    return '${prettyDate(iso)}, $hour12:$minute $suffix';
  }

  /// Shared text styles so every Shop screen matches.
  static TextStyle title({double size = 20}) => GoogleFonts.outfit(
    color: Colors.white,
    fontSize: size,
    fontWeight: FontWeight.bold,
  );

  static TextStyle body({double size = 14, Color? color}) => GoogleFonts.inter(
    color: color ?? const Color(0xFF94A3B8),
    fontSize: size,
  );

  static TextStyle label({double size = 12.5}) => GoogleFonts.inter(
    color: const Color(0xFF94A3B8),
    fontSize: size,
    fontWeight: FontWeight.w500,
  );

  static TextStyle price({double size = 18, Color? color}) =>
      GoogleFonts.outfit(
        color: color ?? gold,
        fontSize: size,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.2,
      );
}
