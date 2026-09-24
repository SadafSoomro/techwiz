import 'package:flutter/material.dart';

/// MEMBER 4 - Events & Maps
/// Member 4 uses a warm orange / red palette (see the design board) so it
/// stays visually distinct from Member 3's purple / pink community theme.
class EventTheme {
  // ------------------------------- colours -------------------------------
  static const Color primary = Color(0xFFF97316); // Orange
  static const Color primaryDark = Color(0xFFEA580C);
  static const Color secondary = Color(0xFFEF4444); // Red
  static const Color amber = Color(0xFFF59E0B);
  static const Color teal = Color(0xFF14B8A6);
  static const Color green = Color(0xFF22C55E);

  static const Color surface = Color(0xFF171B26);
  static const Color surfaceLight = Color(0xFF1F2534);
  static const Color border = Color(0x14FFFFFF);

  // --------------------------- stylised map ---------------------------
  static const Color mapBackground = Color(0xFF0E1622);
  static const Color mapBlock = Color(0xFF172232);
  static const Color mapRoad = Color(0xFF26364D);
  static const Color mapRoadMajor = Color(0xFF33475F);
  static const Color mapWater = Color(0xFF102C40);
  static const Color mapPark = Color(0xFF15302A);

  // ------------------------------ gradients ------------------------------
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF97316), Color(0xFFEF4444)],
  );

  static const LinearGradient featuredGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFB923C), Color(0xFFEF4444), Color(0xFFB91C1C)],
  );

  static const LinearGradient ticketGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF97316), Color(0xFFEA580C)],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFF97316), Color(0xFFEF4444)],
  );

  // ------------------------------- helpers -------------------------------
  /// "#F97316" -> Color
  static Color fromHex(String? hex, {Color fallback = primary}) {
    if (hex == null || hex.isEmpty) return fallback;
    final value = int.tryParse('FF${hex.replaceFirst('#', '')}', radix: 16);
    return value == null ? fallback : Color(value);
  }

  /// IconData from the icon names stored in the database.
  static IconData iconFor(String? name) {
    switch (name) {
      case 'groups_rounded':
        return Icons.groups_rounded;
      case 'auto_awesome_rounded':
        return Icons.auto_awesome_rounded;
      case 'movie_creation_rounded':
        return Icons.movie_creation_rounded;
      case 'sports_esports_rounded':
        return Icons.sports_esports_rounded;
      case 'menu_book_rounded':
        return Icons.menu_book_rounded;
      case 'music_note_rounded':
        return Icons.music_note_rounded;
      case 'diversity_3_rounded':
        return Icons.diversity_3_rounded;
      case 'construction_rounded':
        return Icons.construction_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  /// Colour used for each event category (matches event_categories.color).
  static Color categoryColor(String? category) {
    switch (category) {
      case 'Fan Convention':
        return const Color(0xFFF97316);
      case 'Cosplay Meetup':
        return const Color(0xFFEC4899);
      case 'Screening':
        return const Color(0xFFF59E0B);
      case 'Gaming Tournament':
        return const Color(0xFF3B82F6);
      case 'Comic Con':
        return const Color(0xFFF43F5E);
      case 'Concert':
        return const Color(0xFF10B981);
      case 'Fan Meetup':
        return const Color(0xFF8B5CF6);
      case 'Workshop':
        return const Color(0xFF06B6D4);
      default:
        return primary;
    }
  }

  /// Material icon for each event category.
  static IconData categoryIcon(String? category) {
    switch (category) {
      case 'Fan Convention':
        return Icons.groups_rounded;
      case 'Cosplay Meetup':
        return Icons.auto_awesome_rounded;
      case 'Screening':
        return Icons.movie_creation_rounded;
      case 'Gaming Tournament':
        return Icons.sports_esports_rounded;
      case 'Comic Con':
        return Icons.menu_book_rounded;
      case 'Concert':
        return Icons.music_note_rounded;
      case 'Fan Meetup':
        return Icons.diversity_3_rounded;
      case 'Workshop':
        return Icons.construction_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  /// File-name slug for the generated banner artwork of a category.
  /// Must stay in sync with frontend/tool/generate_event_banners.py
  static String bannerSlug(String? category) {
    switch (category) {
      case 'Fan Convention':
        return 'fan_convention';
      case 'Cosplay Meetup':
        return 'cosplay_meetup';
      case 'Screening':
        return 'screening';
      case 'Gaming Tournament':
        return 'gaming_tournament';
      case 'Comic Con':
        return 'comic_con';
      case 'Concert':
        return 'concert';
      case 'Fan Meetup':
        return 'fan_meetup';
      case 'Workshop':
        return 'workshop';
      default:
        return 'default';
    }
  }

  /// Bundled banner artwork for a category.
  static String bannerFor(String? category) =>
      'assets/images/events/${bannerSlug(category)}.jpg';

  /// Shared card decoration for the Events module.
  static BoxDecoration card({Color? borderColor, double radius = 18}) {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? border),
    );
  }

  /// "2026-09-27" -> "27 Sep 2026"
  static String prettyDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final date = DateTime.tryParse(iso.length > 10 ? iso.substring(0, 10) : iso);
    if (date == null) return iso;

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// "18:00" -> "6:00 PM"
  static String prettyTime(String? time) {
    if (time == null || time.isEmpty) return '';
    final parts = time.split(':');
    if (parts.length < 2) return time;

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1];
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final display = hour % 12 == 0 ? 12 : hour % 12;

    return '$display:$minute $suffix';
  }

  /// 1500.0 -> "1,500"
  static String prettyPrice(double? price, {String currency = 'PKR'}) {
    final value = price ?? 0;
    if (value <= 0) return 'Free';

    final text = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0 && text[i - 1] != '.') {
        buffer.write(',');
      }
      buffer.write(text[i]);
    }
    return '$currency ${buffer.toString()}';
  }

  /// 3 -> "in 3 days", -2 -> "2 days ago"
  static String countdown(int days) {
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    if (days > 1) return 'In $days days';
    return '${days.abs()} days ago';
  }

  static const List<String> monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const List<String> weekdayShort = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];
}
