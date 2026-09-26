import 'package:flutter/material.dart';

/// A complete set of admin panel design tokens for one brightness.
///
/// The panel is themed by swapping this object at build time (see
/// `AdminTheme.use`), which is why the previous `static const Color` tokens in
/// [AdminTheme] became getters: a colour that changes at runtime can no longer
/// be a compile-time constant.
@immutable
class AdminPalette {
  const AdminPalette({
    required this.brightness,
    required this.bg,
    required this.bgElevated,
    required this.surface,
    required this.surfaceAlt,
    required this.sidebar,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.primary,
    required this.indigo,
    required this.violet,
    required this.cyan,
    required this.pink,
    required this.green,
    required this.amber,
    required this.red,
    required this.heroColors,
  });

  final Brightness brightness;

  // surfaces
  final Color bg;
  final Color bgElevated;
  final Color surface;
  final Color surfaceAlt;
  final Color sidebar;
  final Color border;

  // text
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  // accents - the light palette uses darker variants so they keep enough
  // contrast against white card surfaces.
  final Color primary;
  final Color indigo;
  final Color violet;
  final Color cyan;
  final Color pink;
  final Color green;
  final Color amber;
  final Color red;

  /// Start/middle/end stops for the dashboard hero banner.
  final List<Color> heroColors;

  bool get isLight => brightness == Brightness.light;
}
