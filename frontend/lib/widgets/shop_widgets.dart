import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../theme/shop_theme.dart';
import 'shop_animated.dart';

/// MEMBER 5 - Merchandise Store
/// Small reusable UI pieces shared by the Shop, Wishlist, Cart, Checkout,
/// Order and AI screens.

// ---------------------------------------------------------------------------
// Filter / category chip
// ---------------------------------------------------------------------------
class ShopFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? accentColor;
  final int? count;

  const ShopFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.accentColor,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? ShopTheme.primary;

    return ScaleOnTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(colors: [accent, accent.withValues(alpha: 0.72)])
              : null,
          color: selected ? null : ShopTheme.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.08),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.38),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                color: selected ? Colors.white : AppTheme.textSecondary,
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.24)
                      : Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.inter(
                    color: selected ? Colors.white : AppTheme.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section heading with an optional action
// ---------------------------------------------------------------------------
class ShopSectionTitle extends StatelessWidget {
  final String text;
  final String? subtitle;
  final Widget? trailing;

  const ShopSectionTitle(this.text, {super.key, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, style: ShopTheme.title(size: 17)),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(subtitle!, style: ShopTheme.label(size: 12)),
                ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// "See all" text button used next to section titles
// ---------------------------------------------------------------------------
class ShopSeeAll extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const ShopSeeAll({
    super.key,
    this.label = 'See all',
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? ShopTheme.secondary;

    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: accent,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 2),
          Icon(Icons.chevron_right_rounded, size: 17, color: accent),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Metric tile (overview counters / order totals)
// ---------------------------------------------------------------------------
class ShopStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  /// When set, the value animates from zero up to this number.
  final num? counterValue;
  final String counterPrefix;
  final String counterSuffix;

  const ShopStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = ShopTheme.primary,
    this.counterValue,
    this.counterPrefix = '',
    this.counterSuffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: ShopTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ShopTheme.label(size: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          if (counterValue != null)
            AnimatedCounter(
              value: counterValue!,
              prefix: counterPrefix,
              suffix: counterSuffix,
              style: ShopTheme.title(size: 19),
            )
          else
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ShopTheme.title(size: 19),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Price row: current price + struck-through old price + discount badge
// ---------------------------------------------------------------------------
class ShopPriceRow extends StatelessWidget {
  final double price;
  final double? oldPrice;
  final int discountPercent;
  final String currency;
  final double size;

  const ShopPriceRow({
    super.key,
    required this.price,
    this.oldPrice,
    this.discountPercent = 0,
    this.currency = 'USD',
    this.size = 18,
  });

  bool get _hasDiscount => oldPrice != null && oldPrice! > price;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          ShopTheme.formatPrice(price, currency: currency),
          style: ShopTheme.price(size: size),
        ),
        if (_hasDiscount) ...[
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              ShopTheme.formatPrice(oldPrice, currency: currency),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: AppTheme.textMuted,
                fontSize: size * 0.68,
                decoration: TextDecoration.lineThrough,
                decorationColor: AppTheme.textMuted,
              ),
            ),
          ),
        ],
        if (discountPercent > 0) ...[
          const SizedBox(width: 7),
          ShopDealBadge(percent: discountPercent, compact: true),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Discount badge (animated gradient)
// ---------------------------------------------------------------------------
class ShopDealBadge extends StatelessWidget {
  final int percent;
  final bool compact;
  final String? label;

  const ShopDealBadge({
    super.key,
    this.percent = 0,
    this.compact = false,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final text = label ?? (percent > 0 ? '-$percent%' : 'DEAL');

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 10,
        vertical: compact ? 2.5 : 5,
      ),
      decoration: BoxDecoration(
        gradient: ShopTheme.dealGradient,
        borderRadius: BorderRadius.circular(compact ? 7 : 10),
        boxShadow: [
          BoxShadow(
            color: ShopTheme.orange.withValues(alpha: 0.35),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: compact ? 10 : 11.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stock pill: In Stock / Only N left / Out of stock / Instant download
// ---------------------------------------------------------------------------
class ShopStockPill extends StatelessWidget {
  final String label;
  final int stock;
  final bool isDigital;
  final bool compact;

  const ShopStockPill({
    super.key,
    required this.label,
    this.stock = 0,
    this.isDigital = false,
    this.compact = true,
  });

  Color get _color {
    if (isDigital) return ShopTheme.accent;
    if (stock <= 0) return ShopTheme.red;
    if (stock <= 10) return ShopTheme.orange;
    return ShopTheme.green;
  }

  IconData get _icon {
    if (isDigital) return Icons.bolt_rounded;
    if (stock <= 0) return Icons.block_rounded;
    if (stock <= 10) return Icons.local_fire_department_rounded;
    return Icons.check_circle_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 3.5 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: compact ? 11 : 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: compact ? 10.5 : 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rating row
// ---------------------------------------------------------------------------
class ShopRatingRow extends StatelessWidget {
  final double rating;
  final int ratingCount;
  final bool showCount;

  const ShopRatingRow({
    super.key,
    required this.rating,
    this.ratingCount = 0,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedStars(rating: rating, size: 13),
        const SizedBox(width: 5),
        Text(
          rating.toStringAsFixed(1),
          style: GoogleFonts.inter(
            color: ShopTheme.gold,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (showCount && ratingCount > 0) ...[
          const SizedBox(width: 4),
          Text(
            '($ratingCount)',
            style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 11),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Heart / wishlist toggle with a pop animation
// ---------------------------------------------------------------------------
class ShopWishButton extends StatefulWidget {
  final bool active;
  final VoidCallback? onTap;
  final double size;
  final bool filled;

  const ShopWishButton({
    super.key,
    required this.active,
    this.onTap,
    this.size = 18,
    this.filled = true,
  });

  @override
  State<ShopWishButton> createState() => _ShopWishButtonState();
}

class _ShopWishButtonState extends State<ShopWishButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant ShopWishButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.active ? ShopTheme.secondary : AppTheme.textMuted;

    return GestureDetector(
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: Tween(begin: 0.72, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
        ),
        child: Container(
          padding: EdgeInsets.all(widget.size * 0.5),
          decoration: BoxDecoration(
            color: widget.filled
                ? Colors.black.withValues(alpha: 0.42)
                : color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.active
                  ? ShopTheme.secondary.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.10),
            ),
          ),
          child: Icon(
            widget.active
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            size: widget.size,
            color: color,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quantity stepper used on the Cart and Product Details screens
// ---------------------------------------------------------------------------
class ShopQuantityStepper extends StatelessWidget {
  final int quantity;
  final int max;
  final ValueChanged<int> onChanged;
  final bool compact;

  const ShopQuantityStepper({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.max = 99,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final dimension = compact ? 27.0 : 34.0;

    return Container(
      decoration: BoxDecoration(
        color: ShopTheme.surfaceLight,
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _button(
            icon: Icons.remove_rounded,
            enabled: quantity > 1,
            dimension: dimension,
            onTap: () => onChanged(quantity - 1),
          ),
          SizedBox(
            width: compact ? 30 : 40,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: compact ? 13 : 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _button(
            icon: Icons.add_rounded,
            enabled: quantity < max,
            dimension: dimension,
            onTap: () => onChanged(quantity + 1),
          ),
        ],
      ),
    );
  }

  Widget _button({
    required IconData icon,
    required bool enabled,
    required double dimension,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: dimension,
        height: dimension,
        child: Icon(
          icon,
          size: compact ? 14 : 17,
          color: enabled ? Colors.white : AppTheme.textMuted,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gradient primary button with a loading state
// ---------------------------------------------------------------------------
class ShopPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final Gradient? gradient;
  final double height;
  final bool expanded;

  const ShopPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.gradient,
    this.height = 52,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;

    final button = Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          gradient: gradient ?? ShopTheme.buyGradient,
          borderRadius: BorderRadius.circular(15),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: ShopTheme.primary.withValues(alpha: 0.34),
                    blurRadius: 16,
                    offset: const Offset(0, 7),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.3,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );

    return ScaleOnTap(
      onTap: enabled ? onPressed : null,
      child: expanded
          ? SizedBox(width: double.infinity, child: button)
          : button,
    );
  }
}

// ---------------------------------------------------------------------------
// Secondary (outlined) button
// ---------------------------------------------------------------------------
class ShopOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final double height;
  final bool expanded;

  const ShopOutlineButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color,
    this.height = 52,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? ShopTheme.primary;

    final button = Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: accent.withValues(alpha: 0.48)),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.outfit(
                color: accent,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );

    return ScaleOnTap(
      onTap: onPressed,
      child: expanded
          ? SizedBox(width: double.infinity, child: button)
          : button,
    );
  }
}

// ---------------------------------------------------------------------------
// One line of the bill: "Subtotal ......... $69.98"
// ---------------------------------------------------------------------------
class ShopBillRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool emphasised;
  final String? note;

  const ShopBillRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.emphasised = false,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: emphasised ? 7 : 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    color: emphasised ? Colors.white : AppTheme.textSecondary,
                    fontSize: emphasised ? 15 : 13.5,
                    fontWeight: emphasised ? FontWeight.bold : FontWeight.w400,
                  ),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.outfit(
                  color:
                      valueColor ??
                      (emphasised ? Colors.white : Colors.white70),
                  fontSize: emphasised ? 19 : 14,
                  fontWeight: emphasized(emphasised),
                ),
              ),
            ],
          ),
          if (note != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                note!,
                style: GoogleFonts.inter(
                  color: ShopTheme.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  FontWeight emphasized(bool value) =>
      value ? FontWeight.bold : FontWeight.w600;
}

// ---------------------------------------------------------------------------
// Empty state used by wishlist / cart / orders / search
// ---------------------------------------------------------------------------
class ShopEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color color;

  const ShopEmptyState({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.actionLabel,
    this.onAction,
    this.color = ShopTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PulseGlow(
              color: color,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.32)),
                ),
                child: Icon(icon, size: 46, color: color),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: ShopTheme.title(size: 19),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: ShopTheme.body(size: 13.5),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ShopPrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                expanded: false,
                height: 48,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error / retry block
// ---------------------------------------------------------------------------
class ShopErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ShopErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 44, color: ShopTheme.red),
            const SizedBox(height: 14),
            Text('Something went wrong', style: ShopTheme.title(size: 17)),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: ShopTheme.body(size: 13),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              ShopOutlineButton(
                label: 'Try again',
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
                expanded: false,
                height: 44,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Count badge for the cart / wishlist icons
// ---------------------------------------------------------------------------
class ShopCountBadge extends StatelessWidget {
  final int count;
  final Widget child;
  final Color color;

  const ShopCountBadge({
    super.key,
    required this.count,
    required this.child,
    this.color = ShopTheme.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              constraints: const BoxConstraints(minWidth: 17),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.78)],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.cardColor, width: 1.4),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Small "used by" chip, e.g. "One Piece" / brand / category
// ---------------------------------------------------------------------------
class ShopTag extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;

  const ShopTag({super.key, required this.label, this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final accent = color ?? ShopTheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: accent),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              color: accent,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Horizontal scrolling chip row (category + fandom filters)
// ---------------------------------------------------------------------------
class ShopChipRow extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  const ShopChipRow({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) => Center(child: children[index]),
      ),
    );
  }
}
