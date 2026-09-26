import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/admin_provider.dart';
import '../theme/admin_theme.dart';

/// Applies the administrator's chosen palette to the admin subtree.
///
/// `AdminTheme`'s tokens are getters over a swappable palette, so the palette
/// has to be selected before the children build - which is exactly what this
/// scope does. Wrap every admin screen in it.
class AdminThemeScope extends StatelessWidget {
  const AdminThemeScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final lightMode = context.watch<AdminProvider>().lightMode;
    AdminTheme.use(lightMode ? AdminTheme.light : AdminTheme.dark);
    return Theme(data: AdminTheme.theme, child: child);
  }
}

/* =========================================================================
 * layout primitives
 * ========================================================================= */

/// Standard panel surface used by every admin section.
class AdminPanel extends StatelessWidget {
  const AdminPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isLight = AdminTheme.isLight;
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AdminTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? (isLight ? Colors.black : Colors.white),
          width: 1.1,
        ),
        boxShadow: isLight
            ? [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

/// Page heading: title, one-line subtitle and a trailing action slot.
class AdminSectionHeader extends StatelessWidget {
  const AdminSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: AdminTheme.glow(AdminTheme.primary),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AdminTheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(icon, color: AdminTheme.violet, size: 20),
          ),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        if (action != null) ...[const SizedBox(width: 12), action!],
      ],
    );
  }
}

/* =========================================================================
 * stats
 * ========================================================================= */

class AdminStatCard extends StatefulWidget {
  const AdminStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.caption,
    this.delta,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? caption;
  final String? delta;
  final VoidCallback? onTap;

  @override
  State<AdminStatCard> createState() => _AdminStatCardState();
}

class _AdminStatCardState extends State<AdminStatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isLight = AdminTheme.isLight;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: (_hovered == true) && widget.onTap != null
            ? Matrix4.translationValues(0.0, -2.0, 0.0)
            : Matrix4.identity(),
        child: AdminPanel(
          onTap: widget.onTap,
          borderColor: _hovered && widget.onTap != null ? widget.color : null,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6.5),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: isLight ? 0.16 : 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 15),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AdminTheme.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (widget.onTap != null)
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: _hovered ? widget.color : AdminTheme.textMuted,
                    ),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.value,
                        style: GoogleFonts.outfit(
                          color: AdminTheme.textPrimary,
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (widget.delta != null && widget.delta!.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(
                          alpha: isLight ? 0.15 : 0.14,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: widget.color.withValues(
                            alpha: isLight ? 0.25 : 0.2,
                          ),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        widget.delta!,
                        maxLines: 1,
                        style: TextStyle(
                          color: widget.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (widget.caption != null && widget.caption!.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  widget.caption!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AdminTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Responsive grid of stat cards - 4 across on desktop, 3 on tablet, 2 on mobile.
class AdminStatGrid extends StatelessWidget {
  const AdminStatGrid({super.key, required this.cards});

  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1100
            ? 4
            : width >= 760
            ? 3
            : 2;

        const gap = 12.0;
        final itemWidth = (width - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards
              .map((card) => SizedBox(width: itemWidth, child: card))
              .toList(),
        );
      },
    );
  }
}

/* =========================================================================
 * pills, badges
 * ========================================================================= */

class AdminPill extends StatelessWidget {
  const AdminPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.filled = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: filled ? Colors.white : color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: filled ? Colors.white : color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular avatar with initial fallback - used by the users list.
class AdminAvatar extends StatelessWidget {
  const AdminAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 40,
    this.color,
  });

  final String name;
  final String? imageUrl;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AdminTheme.primary;
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [effectiveColor, effectiveColor.withValues(alpha: 0.55)],
        ),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      child: (imageUrl != null && imageUrl!.isNotEmpty)
          ? Image.network(
              imageUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Text(
                initial,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: size * 0.4,
                ),
              ),
            )
          : Text(
              initial,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.4,
              ),
            ),
    );
  }
}

/* =========================================================================
 * toolbars
 * ========================================================================= */

class AdminSearchField extends StatelessWidget {
  const AdminSearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.onSubmitted,
    this.width,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          return TextField(
            controller: controller,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            style: TextStyle(color: AdminTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: value.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      tooltip: 'Clear search',
                      onPressed: () {
                        controller.clear();
                        onChanged?.call('');
                        onSubmitted?.call('');
                      },
                    ),
            ),
          );
        },
      ),
    );
  }
}

/// Horizontal, scrollable row of filter chips.
class AdminFilterChips extends StatelessWidget {
  const AdminFilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  /// value -> label
  final Map<String, String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final isLight = AdminTheme.isLight;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.entries.map((entry) {
          final isSelected = entry.key == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => onSelected(entry.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AdminTheme.primary.withValues(alpha: isLight ? 0.14 : 0.22)
                        : (isLight ? AdminTheme.surface : AdminTheme.surfaceAlt),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AdminTheme.primary
                          : (isLight
                              ? Colors.black.withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.25)),
                      width: isSelected ? 1.4 : 1.0,
                    ),
                    boxShadow: isSelected && isLight
                        ? [
                            BoxShadow(
                              color: AdminTheme.primary.withValues(alpha: 0.12),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: AdminTheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                      Text(
                        entry.value,
                        style: TextStyle(
                          color: isSelected
                              ? (isLight ? AdminTheme.primary : Colors.white)
                              : AdminTheme.textSecondary,
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/* =========================================================================
 * list rows
 * ========================================================================= */

/// Generic management-list row used by every CRUD screen.
class AdminListRow extends StatefulWidget {
  const AdminListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.pills = const [],
    this.onTap,
    this.menu,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final List<Widget> pills;
  final VoidCallback? onTap;
  final Widget? menu;

  @override
  State<AdminListRow> createState() => _AdminListRowState();
}

class _AdminListRowState extends State<AdminListRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: _hovered
            ? AdminTheme.primary.withValues(alpha: AdminTheme.isLight ? 0.04 : 0.08)
            : Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                if (widget.leading != null) ...[
                  widget.leading!,
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AdminTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          widget.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AdminTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (widget.pills.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(spacing: 6, runSpacing: 6, children: widget.pills),
                      ],
                    ],
                  ),
                ),
                if (widget.trailing != null) ...[
                  const SizedBox(width: 12),
                  widget.trailing!,
                ],
                if (widget.menu != null) ...[
                  const SizedBox(width: 6),
                  widget.menu!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small labelled metric used inside detail panels.
class AdminMiniStat extends StatelessWidget {
  const AdminMiniStat({
    super.key,
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String? value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value ?? '0',
          style: GoogleFonts.outfit(
            color: color ?? AdminTheme.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(color: AdminTheme.textMuted, fontSize: 11.5),
        ),
      ],
    );
  }
}

/* =========================================================================
 * states
 * ========================================================================= */

class AdminLoader extends StatelessWidget {
  const AdminLoader({super.key, this.label = 'Loading...'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AdminTheme.indigo,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: TextStyle(color: AdminTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_rounded,
    this.action,
  });

  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AdminTheme.surfaceAlt,
                shape: BoxShape.circle,
                border: Border.all(color: AdminTheme.border),
              ),
              child: Icon(icon, size: 28, color: AdminTheme.textMuted),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AdminTheme.textSecondary,
                fontSize: 13.5,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

class AdminErrorState extends StatelessWidget {
  const AdminErrorState({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 34,
              color: AdminTheme.red,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AdminTheme.textSecondary,
                fontSize: 13.5,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AdminTheme.textPrimary,
                  side: BorderSide(color: AdminTheme.border),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/* =========================================================================
 * charts
 * ========================================================================= */

/// Smooth area/line chart for the dashboard trend.
///
/// Hand-drawn with a CustomPainter so the panel needs no chart dependency.
class AdminLineChart extends StatelessWidget {
  const AdminLineChart({
    super.key,
    required this.series,
    required this.labels,
    this.height = 180,
    this.color,
  });

  /// Y values, oldest first.
  final List<double> series;
  final List<String> labels;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return const AdminEmptyState(message: 'No data for this period.');
    }

    final maxValue = series.reduce((a, b) => a > b ? a : b);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;
    final effectiveColor = color ?? AdminTheme.indigo;

    return SizedBox(
      height: height,
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _AreaChartPainter(
                values: series,
                maxValue: safeMax,
                color: effectiveColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels
                .map(
                  (l) => Text(
                    l,
                    style: TextStyle(
                      color: AdminTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _AreaChartPainter extends CustomPainter {
  _AreaChartPainter({
    required this.values,
    required this.maxValue,
    required this.color,
  });

  final List<double> values;
  final double maxValue;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final dx = size.width / (values.length - 1);

    // Horizontal grid lines (quarter steps).
    final gridPaint = Paint()
      ..color = AdminTheme.border.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final ratio = (values[i] / maxValue).clamp(0.0, 1.0);
      points.add(Offset(dx * i, size.height - ratio * (size.height - 8) - 4));
    }

    // Filled area under the curve.
    final path = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) {
      path.lineTo(p.dx, p.dy);
    }
    path
      ..lineTo(points.last.dx, size.height)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.35),
            color.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // The line itself.
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Dots at each sample.
    for (final p in points) {
      canvas.drawCircle(p, 4, Paint()..color = AdminTheme.surface);
      canvas.drawCircle(p, 2.8, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _AreaChartPainter old) =>
      old.values != values || old.maxValue != maxValue || old.color != color;
}

/// Horizontal bar used by the breakdown panels ("content by type", "api hits").
class AdminBarRow extends StatelessWidget {
  const AdminBarRow({
    super.key,
    required this.label,
    required this.value,
    required this.maxValue,
    this.color,
    this.trailingText,
  });

  final String label;
  final num? value;
  final num? maxValue;
  final Color? color;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    final v = value ?? 0;
    final maxV = maxValue ?? 1;
    final ratio = maxV <= 0 ? 0.0 : (v / maxV).clamp(0.0, 1.0);
    final effectiveColor = color ?? AdminTheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AdminTheme.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ),
              Text(
                trailingText ?? AdminTheme.compact(v),
                style: TextStyle(
                  color: AdminTheme.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio.toDouble(),
              minHeight: 6,
              backgroundColor: AdminTheme.surfaceAlt,
              valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================================================================
 * buttons & feedback helpers
 * ========================================================================= */

class AdminPrimaryButton extends StatelessWidget {
  const AdminPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = false,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expand;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final button = DecoratedBox(
      decoration: BoxDecoration(
        gradient: color == null
            ? AdminTheme.brandGradient
            : LinearGradient(colors: [color!, color!.withValues(alpha: 0.75)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon ?? Icons.check_rounded, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Shared confirm dialog for every destructive admin action.
Future<bool> adminConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AdminTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        title,
        style: TextStyle(
          color: AdminTheme.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      content: Text(
        message,
        style: TextStyle(color: AdminTheme.textSecondary, fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: TextStyle(color: AdminTheme.textSecondary),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: destructive ? AdminTheme.red : AdminTheme.primary,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

void adminToast(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        backgroundColor: error ? AdminTheme.red : AdminTheme.surfaceAlt,
        content: Row(
          children: [
            Icon(
              error
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
              ),
            ),
          ],
        ),
      ),
    );
}

/// Simple pagination footer shared by the list screens.
class AdminPager extends StatelessWidget {
  const AdminPager({
    super.key,
    this.page = 1,
    this.pages = 1,
    this.total = 0,
    required this.onPage,
  });

  final int? page;
  final int? pages;
  final int? total;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final curPage = (page == null || page! < 1) ? 1 : page!;
    final totalPages = (pages == null || pages! < 1) ? 1 : pages!;
    final totalCount = total ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AdminTheme.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AdminTheme.isLight
                    ? Colors.black.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Text(
              '$totalCount total record${totalCount == 1 ? '' : 's'}',
              style: TextStyle(
                color: AdminTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Spacer(),
          IconButton.outlined(
            onPressed: curPage > 1 ? () => onPage(curPage - 1) : null,
            icon: const Icon(Icons.chevron_left_rounded, size: 18),
            style: IconButton.styleFrom(
              side: BorderSide(
                color: AdminTheme.isLight
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.2),
              ),
              backgroundColor: AdminTheme.surface,
            ),
            tooltip: 'Previous page',
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AdminTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AdminTheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'Page $curPage of $totalPages',
              style: TextStyle(
                color: AdminTheme.primary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            onPressed: curPage < totalPages ? () => onPage(curPage + 1) : null,
            icon: const Icon(Icons.chevron_right_rounded, size: 18),
            style: IconButton.styleFrom(
              side: BorderSide(
                color: AdminTheme.isLight
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.2),
              ),
              backgroundColor: AdminTheme.surface,
            ),
            tooltip: 'Next page',
          ),
        ],
      ),
    );
  }
}
