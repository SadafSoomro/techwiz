/// Shared animation toolkit used across the Member 1 and Member 2 screens.
///
/// Everything here is dependency free (plain `AnimationController`s) so the
/// app stays lightweight and the transitions stay consistent:
/// entry fades, staggered lists, press feedback, counting numbers, shimmer
/// loading placeholders, animated progress bars and pulsing dots.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Entry animations
// ---------------------------------------------------------------------------

/// Fades + slides its child in when first built. [delay] lets a column of
/// widgets cascade instead of appearing all at once.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double offsetY;
  final double offsetX;
  final Curve curve;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 520),
    this.delay = Duration.zero,
    this.offsetY = 26,
    this.offsetX = 0,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    final curved = CurvedAnimation(parent: _controller, curve: widget.curve);
    _opacity = Tween<double>(begin: 0, end: 1).animate(curved);
    _slide = Tween<Offset>(
      begin: Offset(widget.offsetX, widget.offsetY / 100),
      end: Offset.zero,
    ).animate(curved);

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _opacity.value,
        child: FractionalTranslation(translation: _slide.value, child: child),
      ),
      child: widget.child,
    );
  }
}

/// Wraps a list of children with an increasing [FadeSlideIn] delay.
class StaggeredColumn extends StatelessWidget {
  final List<Widget> children;
  final Duration step;
  final Duration start;
  final CrossAxisAlignment crossAxisAlignment;

  const StaggeredColumn({
    super.key,
    required this.children,
    this.step = const Duration(milliseconds: 70),
    this.start = Duration.zero,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (var index = 0; index < children.length; index++)
          FadeSlideIn(
            delay: start + step * index,
            child: children[index],
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Press feedback
// ---------------------------------------------------------------------------

/// Scales its child down slightly while pressed - gives every card and chip
/// a tactile, app-like feel.
class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final Duration duration;

  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.96,
    this.duration = const Duration(milliseconds: 120),
  });

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Counters
// ---------------------------------------------------------------------------

/// Smoothly counts from 0 to [value] (used for dashboard stats).
class AnimatedCounter extends StatelessWidget {
  final num value;
  final TextStyle? style;
  final Duration duration;
  final String suffix;
  final String prefix;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 900),
    this.suffix = '',
    this.prefix = '',
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) {
        final shown = value is int ? animated.round() : animated.toStringAsFixed(1);
        return Text('$prefix$shown$suffix', style: style);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Loading placeholders
// ---------------------------------------------------------------------------

/// Animated shimmer sweep - used instead of a plain spinner while content
/// loads, so the layout does not jump around.
class Shimmer extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const Shimmer({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final value = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment(-1.8 + value * 3.6, 0),
              end: Alignment(-0.8 + value * 3.6, 0),
              colors: const [
                Color(0xFF1B2436),
                Color(0xFF283449),
                Color(0xFF1B2436),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A card shaped shimmer block (image + two text lines).
class ShimmerCard extends StatelessWidget {
  final double imageHeight;
  const ShimmerCard({super.key, this.imageHeight = 130});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Shimmer(height: imageHeight, borderRadius: BorderRadius.circular(18)),
        const SizedBox(height: 12),
        const Shimmer(height: 14, width: 200),
        const SizedBox(height: 8),
        const Shimmer(height: 11, width: 140),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Progress
// ---------------------------------------------------------------------------

/// Progress bar that animates to [value] (0..1) with a soft brand gradient.
class AnimatedProgressBar extends StatelessWidget {
  final double value;
  final double height;
  final List<Color>? colors;
  final Duration duration;

  const AnimatedProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.colors,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  Widget build(BuildContext context) {
    final palette =
        colors ?? const [Color(0xFF3B82F6), Color(0xFF8B5CF6)];

    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Stack(
        children: [
          Container(
            height: height,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
            duration: duration,
            curve: Curves.easeOutCubic,
            builder: (context, animated, _) => FractionallySizedBox(
              widthFactor: animated == 0 ? 0.0001 : animated,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: palette),
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pulsing dot (live indicators, unread badges).
class PulseDot extends StatefulWidget {
  final Color color;
  final double size;

  const PulseDot({
    super.key,
    this.color = const Color(0xFFEF4444),
    this.size = 9,
  });

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Container(
        width: widget.size * (1 + _controller.value * 0.35),
        height: widget.size * (1 + _controller.value * 0.35),
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.85 - _controller.value * 0.35),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.35),
              blurRadius: 8 * _controller.value,
              spreadRadius: 2 * _controller.value,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header + pills
// ---------------------------------------------------------------------------

/// "Latest Episodes    See All" style header with an animated underline.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color accent;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.accent = const Color(0xFF3B82F6),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subtitle!,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12.5,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          PressScale(
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                children: [
                  Text(
                    actionLabel!,
                    style: TextStyle(
                      color: accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: accent, size: 18),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Rounded count/filter pill with an animated selected state.
class AnimatedPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final Color color;
  final VoidCallback? onTap;
  final int? count;

  const AnimatedPill({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.color = const Color(0xFF3B82F6),
    this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      pressedScale: 0.94,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [color, color.withValues(alpha: 0.72)],
                )
              : null,
          color: selected ? null : const Color(0xFF151C2C),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? Colors.transparent : Colors.white.withValues(alpha: 0.09),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
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
                size: 15,
                color: selected ? Colors.white : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 7),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF94A3B8),
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
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
// Animated waveform (podcasts)
// ---------------------------------------------------------------------------

/// Bars that dance while [playing] is true - the podcast player visual.
class AnimatedWaveform extends StatefulWidget {
  final bool playing;
  final int bars;
  final double height;
  final Color color;

  const AnimatedWaveform({
    super.key,
    required this.playing,
    this.bars = 26,
    this.height = 46,
    this.color = const Color(0xFF10B981),
  });

  @override
  State<AnimatedWaveform> createState() => _AnimatedWaveformState();
}

class _AnimatedWaveformState extends State<AnimatedWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.playing) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant AnimatedWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playing && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.playing && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(widget.bars, (index) {
            final phase = (_controller.value * 2 * math.pi) + index * 0.42;
            final factor = widget.playing
                ? 0.25 + ((math.sin(phase) + 1) / 2) * 0.75
                : 0.18 + (index % 4) * 0.06;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 90),
                  height: widget.height * factor,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(
                      alpha: widget.playing ? 0.55 + factor * 0.45 : 0.35,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
