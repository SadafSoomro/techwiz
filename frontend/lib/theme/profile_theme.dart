import 'package:flutter/material.dart';

/// MEMBER 1 - Profile, Fandom Selection & Home theme.
///
/// Electric blue + indigo palette (the blue band of the FANDOM VERSE mock-up),
/// which keeps Member 1 visually distinct from the other modules.
class ProfileTheme {
  static const Color primary = Color(0xFF3B82F6); // Electric blue
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color secondary = Color(0xFF6366F1); // Indigo
  static const Color tertiary = Color(0xFF8B5CF6); // Violet
  static const Color cyan = Color(0xFF22D3EE);
  static const Color amber = Color(0xFFF59E0B);
  static const Color green = Color(0xFF10B981);
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
    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF3B82F6), Color(0xFF6366F1), Color(0xFF8B5CF6)],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0D111D), Color(0xFF0B0F19), Color(0xFF0C1430)],
  );

  static const LinearGradient pointsGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFF43F5E)],
  );

  static const LinearGradient badgeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF22D3EE)],
  );

  /// Colour used for a fandom name (shared with the content module look).
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

  /// Bundled cover artwork for a fandom selection card.
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

  /// Material icon for the icon names stored in SQLite (e.g. "badge_rounded").
  static IconData icon(String? name) {
    switch (name) {
      case 'rocket_launch_rounded':
        return Icons.rocket_launch_rounded;
      case 'auto_awesome_rounded':
        return Icons.auto_awesome_rounded;
      case 'diversity_3_rounded':
        return Icons.diversity_3_rounded;
      case 'badge_rounded':
        return Icons.badge_rounded;
      case 'newspaper_rounded':
        return Icons.newspaper_rounded;
      case 'play_circle_rounded':
        return Icons.play_circle_rounded;
      case 'psychology_alt_rounded':
        return Icons.psychology_alt_rounded;
      case 'group_add_rounded':
        return Icons.group_add_rounded;
      case 'event_available_rounded':
        return Icons.event_available_rounded;
      case 'workspace_premium_rounded':
        return Icons.workspace_premium_rounded;
      case 'person_rounded':
        return Icons.person_rounded;
      case 'forum_rounded':
        return Icons.forum_rounded;
      case 'bookmark_rounded':
        return Icons.bookmark_rounded;
      case 'sports_esports_rounded':
        return Icons.sports_esports_rounded;
      case 'movie_creation_rounded':
        return Icons.movie_creation_rounded;
      case 'menu_book_rounded':
        return Icons.menu_book_rounded;
      case 'music_note_rounded':
        return Icons.music_note_rounded;
      case 'emoji_events_rounded':
        return Icons.emoji_events_rounded;
      case 'explore_rounded':
        return Icons.explore_rounded;
      case 'verified_rounded':
        return Icons.verified_rounded;
      case 'star_rounded':
        return Icons.star_rounded;
      case 'favorite_rounded':
        return Icons.favorite_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }

  /// "0xFF3B82F6" (stored as "#3B82F6") -> Color
  static Color parseColor(String? hex, {Color fallback = primary}) {
    if (hex == null || hex.isEmpty) return fallback;
    var value = hex.replaceAll('#', '').trim();
    if (value.length == 6) value = 'FF$value';
    final parsed = int.tryParse(value, radix: 16);
    return parsed == null ? fallback : Color(parsed);
  }

  /// Title of a fan level (1..9) shown next to the points bar.
  static String levelName(int level) {
    if (level >= 8) return 'Legendary Fan';
    if (level >= 6) return 'Elite Fan';
    if (level >= 4) return 'Expert Fan';
    if (level >= 2) return 'Rising Fan';
    return 'New Fan';
  }

  /// Colour of a fan level badge.
  static Color levelColor(int level) {
    if (level >= 8) return amber;
    if (level >= 6) return rose;
    if (level >= 4) return tertiary;
    if (level >= 2) return primary;
    return cyan;
  }

  static String compactCount(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return '$value';
  }
}
