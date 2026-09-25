import 'package:flutter/material.dart';

/// MEMBER 2 - Fandom Content theme.
///
/// Emerald / cyan palette (the green band of the FANDOM VERSE mock-up), which
/// keeps it visually separate from Member 3 (purple) and Member 4 (orange).
class ContentTheme {
  static const Color primary = Color(0xFF10B981); // Emerald
  static const Color primaryDark = Color(0xFF047857);
  static const Color secondary = Color(0xFF06B6D4); // Cyan
  static const Color tertiary = Color(0xFF34D399);
  static const Color amber = Color(0xFFF59E0B);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color rose = Color(0xFFF43F5E);

  static const Color background = Color(0xFF0B0F19);
  static const Color card = Color(0xFF151C2C);
  static const Color cardAlt = Color(0xFF1B2436);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
  );

  static const LinearGradient featuredGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF059669), Color(0xFF0891B2)],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0D111D), Color(0xFF0B0F19), Color(0xFF08201B)],
  );

  static const LinearGradient podcastGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
  );

  /// Brand colour of a fandom (matches the bundled fandom banner artwork).
  static Color fandomColor(String fandom) {
    switch (fandom) {
      case 'Anime':
        return const Color(0xFFEC4899);
      case 'Gaming':
        return const Color(0xFF3B82F6);
      case 'Movies & TV':
        return const Color(0xFFF59E0B);
      case 'Comics':
        return const Color(0xFFF97316);
      case 'Music':
        return const Color(0xFF10B981);
      case 'Sports':
        return const Color(0xFFEF4444);
      case 'Sci-Fi':
        return const Color(0xFF8B5CF6);
      default:
        return primary;
    }
  }

  static IconData fandomIcon(String fandom) {
    switch (fandom) {
      case 'Anime':
        return Icons.auto_awesome_rounded;
      case 'Gaming':
        return Icons.sports_esports_rounded;
      case 'Movies & TV':
        return Icons.movie_creation_rounded;
      case 'Comics':
        return Icons.menu_book_rounded;
      case 'Music':
        return Icons.music_note_rounded;
      case 'Sports':
        return Icons.emoji_events_rounded;
      case 'Sci-Fi':
        return Icons.rocket_launch_rounded;
      default:
        return Icons.explore_rounded;
    }
  }

  /// Bundled artwork cover for a fandom.
  static String fandomArtwork(String fandom) {
    switch (fandom) {
      case 'Anime':
        return 'assets/images/fandoms/anime.jpg';
      case 'Gaming':
        return 'assets/images/fandoms/gaming.jpg';
      case 'Movies & TV':
        return 'assets/images/fandoms/movies_tv.jpg';
      case 'Comics':
        return 'assets/images/fandoms/comics.jpg';
      case 'Music':
        return 'assets/images/fandoms/music.jpg';
      case 'Sports':
        return 'assets/images/fandoms/sports.jpg';
      case 'Sci-Fi':
        return 'assets/images/fandoms/scifi.jpg';
      default:
        return 'assets/images/fandoms/default.jpg';
    }
  }

  static IconData contentTypeIcon(String type) {
    switch (type) {
      case 'news':
        return Icons.newspaper_rounded;
      case 'article':
        return Icons.article_rounded;
      case 'gallery':
        return Icons.photo_library_rounded;
      case 'video':
        return Icons.play_circle_rounded;
      case 'podcast':
        return Icons.podcasts_rounded;
      case 'deep_dive':
        return Icons.psychology_alt_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  static String contentTypeLabel(String type) {
    switch (type) {
      case 'news':
        return 'NEWS';
      case 'article':
        return 'ARTICLE';
      case 'gallery':
        return 'GALLERY';
      case 'video':
        return 'VIDEO';
      case 'podcast':
        return 'PODCAST';
      case 'deep_dive':
        return 'DEEP DIVE';
      default:
        return 'CONTENT';
    }
  }

  static Color contentTypeColor(String type) {
    switch (type) {
      case 'news':
        return amber;
      case 'article':
        return secondary;
      case 'gallery':
        return rose;
      case 'video':
        return violet;
      case 'podcast':
        return primary;
      case 'deep_dive':
        return const Color(0xFF22D3EE);
      default:
        return primary;
    }
  }

  /// 168 -> "2:48", 2280 -> "38:00", 5400 -> "1:30:00"
  static String prettyDuration(int seconds) {
    if (seconds <= 0) return '';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final rest = seconds % 60;
    final padded = rest.toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:$padded';
    }
    return '$minutes:$padded';
  }

  /// 18420 -> "18.4K"
  static String compactCount(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return '$value';
  }

  static String prettyDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
    if (parsed == null) return raw;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
  }
}
