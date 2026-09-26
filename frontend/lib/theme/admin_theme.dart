import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'admin_palette.dart';

/// Design tokens for the Member 6 admin portal.
///
/// Shares the Fandom Verse purple with the fan app so the product still feels
/// like one thing, but shifts the surfaces colder (slate/indigo instead of the
/// app's warmer midnight) so an administrator always knows they are inside the
/// panel and not the fan experience.
///
/// Every colour below is a [getter] on the *active* palette rather than a
/// `const`, because the administrator can flip the panel between dark and
/// light mode at runtime.
class AdminTheme {
  // ------------------------------ palettes --------------------------------
  static const AdminPalette dark = AdminPalette(
    brightness: Brightness.dark,
    bg: Color(0xFF090D1A),
    bgElevated: Color(0xFF0D1222),
    surface: Color(0xFF121626),
    surfaceAlt: Color(0xFF161C33),
    sidebar: Color(0xFF0A0E1B),
    border: Color(0xFFFFFFFF),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF94A3B8),
    textMuted: Color(0xFF64748B),
    primary: Color(0xFF7047EB),
    indigo: Color(0xFF6366F1),
    violet: Color(0xFF8B5CF6),
    cyan: Color(0xFF06B6D4),
    pink: Color(0xFFEC4899),
    green: Color(0xFF10B981),
    amber: Color(0xFFF59E0B),
    red: Color(0xFFEF4444),
    heroColors: [Color(0xFF381A7A), Color(0xFF1E1146), Color(0xFF150D33)],
  );

  static const AdminPalette light = AdminPalette(
    brightness: Brightness.light,
    bg: Color(0xFFF4F6FC),
    bgElevated: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF0F2F9),
    sidebar: Color(0xFFFFFFFF),
    border: Color(0xFF000000),
    textPrimary: Color(0xFF141A26),
    textSecondary: Color(0xFF4A5568),
    textMuted: Color(0xFF7A8699),
    primary: Color(0xFF6D28D9),
    indigo: Color(0xFF4F46E5),
    violet: Color(0xFF7C3AED),
    cyan: Color(0xFF0E7490),
    pink: Color(0xFFDB2777),
    green: Color(0xFF047857),
    amber: Color(0xFFB45309),
    red: Color(0xFFDC2626),
    heroColors: [Color(0xFFE8E5FF), Color(0xFFF4F6FC), Color(0xFFDDF3F8)],
  );

  static AdminPalette _active = dark;

  /// Switches the panel over to [palette]. Called by `AdminThemeScope` during
  /// build, so every token read below resolves against the mode the
  /// administrator picked.
  static void use(AdminPalette palette) => _active = palette;

  static AdminPalette get palette => _active;
  static bool get isLight => _active.isLight;

  // ------------------------------- surfaces -------------------------------
  static Color get bg => _active.bg;
  static Color get bgElevated => _active.bgElevated;
  static Color get surface => _active.surface;
  static Color get surfaceAlt => _active.surfaceAlt;
  static Color get sidebar => _active.sidebar;
  static Color get border => _active.border;
  static Color get subtleBorder =>
      _active.border.withValues(alpha: isLight ? 0.12 : 0.18);

  // --------------------------------- brand --------------------------------
  static Color get primary => _active.primary;
  static Color get indigo => _active.indigo;
  static Color get violet => _active.violet;
  static Color get cyan => _active.cyan;
  static Color get pink => _active.pink;
  static Color get green => _active.green;
  static Color get amber => _active.amber;
  static Color get red => _active.red;

  // ---------------------------------- text --------------------------------
  static Color get textPrimary => _active.textPrimary;
  static Color get textSecondary => _active.textSecondary;
  static Color get textMuted => _active.textMuted;

  // -------------------------------- gradients -----------------------------
  /// Brand gradient for primary buttons - identical in both modes.
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF6366F1), Color(0xFF06B6D4)],
  );

  static LinearGradient get heroGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: _active.heroColors,
  );

  static LinearGradient glow(Color color) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0.04)],
  );

  // -------------------------------- helpers -------------------------------
  static Color forLevel(String level) {
    switch (level.toLowerCase()) {
      case 'warn':
      case 'warning':
        return amber;
      case 'error':
      case 'critical':
        return red;
      case 'success':
        return green;
      default:
        return cyan;
    }
  }

  static Color forStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'published':
      case 'upcoming':
      case 'completed':
      case 'placed':
        return green;
      case 'draft':
      case 'ongoing':
      case 'info':
        return cyan;
      case 'cancelled':
      case 'blocked':
      case 'error':
        return red;
      case 'deactivated':
      case 'out_of_stock':
      case 'warn':
        return amber;
      default:
        return textSecondary;
    }
  }

  static Color forRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return primary;
      case 'editor':
        return cyan;
      default:
        return textSecondary;
    }
  }

  /// 1248 -> "1,248". Used by every stat card and table cell.
  static String compact(num? value) {
    if (value == null) return '0';
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value.abs() >= 10000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    final text = value.round().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
      buffer.write(text[i]);
    }
    return buffer.toString();
  }

  static String money(num? value, {String currency = 'PKR'}) =>
      '$currency ${compact(value ?? 0)}';

  /// The panel's own ThemeData for the active palette - applied locally so the
  /// fan app's theme is untouched when an admin logs out.
  static ThemeData get theme {
    final base = isLight ? ThemeData.light() : ThemeData.dark();

    return base.copyWith(
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      primaryColor: primary,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: primary,
            brightness: _active.brightness,
          ).copyWith(
            primary: primary,
            secondary: cyan,
            surface: surface,
            onSurface: textPrimary,
            error: red,
          ),
      dividerColor: subtleBorder,
      iconTheme: IconThemeData(color: textSecondary),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displaySmall: GoogleFonts.outfit(
          color: textPrimary,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.inter(color: textPrimary, fontSize: 15),
        bodyMedium: GoogleFonts.inter(color: textSecondary, fontSize: 14),
        bodySmall: GoogleFonts.inter(color: textMuted, fontSize: 12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: TextStyle(color: textMuted, fontSize: 14),
        labelStyle: TextStyle(color: textSecondary, fontSize: 14),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isLight
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.25),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isLight
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.25),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: indigo, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: red, width: 1.6),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isLight ? textPrimary : surfaceAlt,
        contentTextStyle: TextStyle(color: isLight ? bgElevated : textPrimary),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(backgroundColor: surface),
      popupMenuTheme: PopupMenuThemeData(color: surfaceAlt),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: indigo,
        linearTrackColor: surfaceAlt,
      ),
      dividerTheme: DividerThemeData(color: subtleBorder, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(surfaceAlt),
        ),
      ),
    );
  }
}
