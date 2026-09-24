import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../theme/shop_theme.dart';
import 'shop_animated.dart';

/// MEMBER 5 - Merchandise Store
/// Shared scaffold for the Shop module: dark gradient background, an animated
/// purple/pink header glow, a title row with optional actions and an optional
/// sticky bottom bar for the Cart / Checkout totals.
class ShopScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;
  final Widget? floatingActionButton;
  final Widget? bottomBar;
  final bool showBackButton;
  final bool resizeToAvoidBottomInset;
  final bool showHeaderGlow;
  final Color glowColor;

  const ShopScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.floatingActionButton,
    this.bottomBar,
    this.showBackButton = true,
    this.resizeToAvoidBottomInset = true,
    this.showHeaderGlow = true,
    this.glowColor = ShopTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: AppTheme.backgroundColor,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomBar,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Stack(
          children: [
            if (showHeaderGlow)
              Positioned(
                top: -110,
                left: -60,
                right: -60,
                child: IgnorePointer(
                  child: AnimatedGradientBox(
                    colors: [
                      glowColor.withValues(alpha: 0.34),
                      ShopTheme.secondary.withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                    child: const SizedBox(height: 262, width: double.infinity),
                  ),
                ),
              ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: Row(
                      children: [
                        if (showBackButton)
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.of(context).maybePop(),
                          )
                        else
                          const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (subtitle != null)
                                Text(
                                  subtitle!,
                                  style: GoogleFonts.inter(
                                    color: AppTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        ...actions,
                      ],
                    ),
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tappable header icon with an optional count badge
/// (used for the wishlist heart and the cart bag).
class ShopHeaderAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final int badgeCount;
  final Color badgeColor;

  const ShopHeaderAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badgeCount = 0,
    this.badgeColor = ShopTheme.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onTap,
        icon: badgeCount > 0
            ? Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: Colors.white),
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      constraints: const BoxConstraints(minWidth: 16),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: AppTheme.cardColor,
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Icon(icon, color: Colors.white),
      ),
    );
  }
}
