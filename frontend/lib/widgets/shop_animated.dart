import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// MEMBER 5 - Merchandise Store
/// Reusable animation widgets used across the Shop and AI screens.
///
/// Everything here is driven by Flutter's own animation system - no animated
/// GIF/WebP assets are needed, so the effects stay crisp at any size, work on
/// every platform (web, Windows, Android, iOS) and add no download weight.
///
/// * [ShineSweep]          - a light sweep travelling across product artwork
/// * [FloatingBox]         - gentle "breathing" float for hero imagery
/// * [PulseGlow]           - pulsing halo behind a product / avatar
/// * [AnimatedGradientBox] - slowly shifting gradient (hero banners)
/// * [AutoScrollRow]       - endlessly scrolling row of product cards
/// * [TypingDots]          - three bouncing dots while the AI is answering
/// * [BounceIn]            - staggered entrance for cards / rows
/// * [AnimatedCounter]     - count-up number for the dashboard stat tiles
/// * [AnimatedStars]       - rating stars that fade in one by one
/// * [SpinningGradientRing] - rotating conic ring around the AI avatar

// ---------------------------------------------------------------------------
// ShineSweep - the "glossy product photo" light band
// ---------------------------------------------------------------------------
class ShineSweep extends StatefulWidget {
  final Widget child;
  final Duration period;

  /// Width of the light band as a fraction of the child's width.
  final double bandWidth;
  final double opacity;

  const ShineSweep({
    super.key,
    required this.child,
    this.period = const Duration(milliseconds: 2600),
    this.bandWidth = 0.34,
    this.opacity = 0.30,
  });

  @override
  State<ShineSweep> createState() => _ShineSweepState();
}

class _ShineSweepState extends State<ShineSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.period)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary keeps the constantly repainting mask from invalidating
    // the rest of the scrolling list.
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Travel from fully off-screen left to fully off-screen right.
          final travel = _controller.value * (1 + widget.bandWidth * 2);
          final start = travel - widget.bandWidth;
          final end = start + widget.bandWidth;

          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.white.withValues(alpha: 0),
                  Colors.white.withValues(alpha: widget.opacity),
                  Colors.white.withValues(alpha: 0),
                ],
                stops: [
                  start.clamp(0.0, 1.0),
                  ((start + end) / 2).clamp(0.0, 1.0),
                  end.clamp(0.0, 1.0),
                ],
              ).createShader(bounds);
            },
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// FloatingBox - gentle vertical float (used for hero imagery / badges)
// ---------------------------------------------------------------------------
class FloatingBox extends StatefulWidget {
  final Widget child;
  final double amplitude;
  final Duration period;

  /// Optional horizontal drift so two floating items never sync up.
  final double horizontalAmplitude;
  final double phase;

  const FloatingBox({
    super.key,
    required this.child,
    this.amplitude = 8,
    this.period = const Duration(milliseconds: 3200),
    this.horizontalAmplitude = 0,
    this.phase = 0,
  });

  @override
  State<FloatingBox> createState() => _FloatingBoxState();
}

class _FloatingBoxState extends State<FloatingBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.period)
      ..repeat();
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
      builder: (context, child) {
        final angle = (_controller.value * 2 * math.pi) + widget.phase;
        return Transform.translate(
          offset: Offset(
            math.sin(angle) * widget.horizontalAmplitude,
            math.sin(angle) * widget.amplitude,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ---------------------------------------------------------------------------
// PulseGlow - a halo that breathes behind its child
// ---------------------------------------------------------------------------
class PulseGlow extends StatefulWidget {
  final Widget child;
  final Color color;
  final double minRadius;
  final double maxRadius;
  final Duration period;

  const PulseGlow({
    super.key,
    required this.child,
    required this.color,
    this.minRadius = 10,
    this.maxRadius = 26,
    this.period = const Duration(milliseconds: 2000),
  });

  @override
  State<PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<PulseGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.period)
      ..repeat(reverse: true);
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
      builder: (context, child) {
        final value = Curves.easeInOut.transform(_controller.value);
        final blur =
            widget.minRadius + (widget.maxRadius - widget.minRadius) * value;

        return DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.18 + 0.22 * value),
                blurRadius: blur,
                spreadRadius: 1 + 2 * value,
              ),
            ],
            borderRadius: BorderRadius.circular(24),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ---------------------------------------------------------------------------
// AnimatedGradientBox - slowly shifting multi-stop gradient
// ---------------------------------------------------------------------------
class AnimatedGradientBox extends StatefulWidget {
  final List<Color> colors;
  final Widget? child;
  final Duration period;
  final BorderRadius? borderRadius;

  const AnimatedGradientBox({
    super.key,
    required this.colors,
    this.child,
    this.period = const Duration(milliseconds: 7000),
    this.borderRadius,
  });

  @override
  State<AnimatedGradientBox> createState() => _AnimatedGradientBoxState();
}

class _AnimatedGradientBoxState extends State<AnimatedGradientBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.period)
      ..repeat(reverse: true);
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
      builder: (context, child) {
        final value = Curves.easeInOut.transform(_controller.value);

        // Rotate the palette so the gradient appears to flow.
        final palette = widget.colors.length >= 2
            ? [
                Color.lerp(widget.colors[0], widget.colors[1], value)!,
                Color.lerp(
                  widget.colors[1],
                  widget.colors[widget.colors.length - 1],
                  value,
                )!,
                Color.lerp(
                  widget.colors[0],
                  widget.colors[widget.colors.length - 1],
                  value,
                )!,
              ]
            : widget.colors;

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: palette,
            ),
            borderRadius: widget.borderRadius,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ---------------------------------------------------------------------------
// AutoScrollRow - eternally scrolling row of cards
// ---------------------------------------------------------------------------
class AutoScrollRow extends StatefulWidget {
  final List<Widget> children;
  final double height;
  final Duration period;

  /// When false the row is a plain, user-scrollable list (accessibility /
  /// reduced-motion friendly).
  final bool enabled;

  const AutoScrollRow({
    super.key,
    required this.children,
    required this.height,
    this.period = const Duration(seconds: 26),
    this.enabled = true,
  });

  @override
  State<AutoScrollRow> createState() => _AutoScrollRowState();
}

class _AutoScrollRowState extends State<AutoScrollRow>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _controller;
  bool _userIsScrolling = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.period);

    _controller.addListener(_tick);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) _controller.forward(from: 0);
    });

    // Start once the list has been laid out and has something to scroll.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward(from: 0);
    });
  }

  void _tick() {
    if (!_scrollController.hasClients || _userIsScrolling) return;

    final position = _scrollController.position;
    if (position.maxScrollExtent <= 0) return;

    final target = position.maxScrollExtent * _controller.value;
    _scrollController.jumpTo(target.clamp(0.0, position.maxScrollExtent));
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_tick)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return SizedBox(
        height: widget.height,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: widget.children,
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // Pause the auto-scroll while the user is dragging, then resume.
          if (notification is ScrollStartNotification &&
              notification.dragDetails != null) {
            _userIsScrolling = true;
          } else if (notification is ScrollEndNotification) {
            _userIsScrolling = false;
            _controller.forward(from: (_controller.value).clamp(0.0, 1.0));
          }
          return false;
        },
        child: ListView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: widget.children,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TypingDots - "the assistant is typing" indicator
// ---------------------------------------------------------------------------
class TypingDots extends StatefulWidget {
  final Color color;
  final double size;
  final int count;

  const TypingDots({
    super.key,
    this.color = const Color(0xFF06B6D4),
    this.size = 7,
    this.count = 3,
  });

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
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
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.count, (index) {
            // Stagger each dot by a third of the cycle.
            final offset = index / widget.count;
            final progress = (_controller.value - offset) % 1.0;
            final bounce = math.sin(progress.clamp(0.0, 1.0) * math.pi);

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.size * 0.28),
              child: Transform.translate(
                offset: Offset(0, -bounce * widget.size * 0.85),
                child: Opacity(
                  opacity: 0.35 + 0.65 * bounce,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// BounceIn - staggered entrance used by the shop rows
// ---------------------------------------------------------------------------
class BounceIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;

  const BounceIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 480),
    this.offsetY = 26,
  });

  @override
  State<BounceIn> createState() => _BounceInState();
}

class _BounceInState extends State<BounceIn> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: widget.duration,
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : Offset(0, widget.offsetY / 100),
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AnimatedCounter - count-up number for the stat tiles
// ---------------------------------------------------------------------------
class AnimatedCounter extends StatelessWidget {
  final num value;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final int decimals;
  final Duration duration;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.decimals = 0,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) {
        final text = animated.toStringAsFixed(decimals);
        return Text('$prefix$text$suffix', style: style);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// AnimatedStars - rating stars that fade in one by one
// ---------------------------------------------------------------------------
class AnimatedStars extends StatelessWidget {
  final double rating;
  final double size;
  final Color color;
  final int max;

  const AnimatedStars({
    super.key,
    required this.rating,
    this.size = 13,
    this.color = const Color(0xFFFBBF24),
    this.max = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(max, (index) {
        final filled = index < rating.round();
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 260 + index * 90),
          curve: Curves.easeOutBack,
          builder: (context, value, child) => Transform.scale(
            scale: value,
            child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
          ),
          child: Icon(
            filled ? Icons.star_rounded : Icons.star_border_rounded,
            size: size,
            color: filled ? color : Colors.white.withValues(alpha: 0.22),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// SpinningGradientRing - rotating ring around the AI avatar
// ---------------------------------------------------------------------------
class SpinningGradientRing extends StatefulWidget {
  final Widget child;
  final List<Color> colors;
  final double padding;
  final Duration period;

  const SpinningGradientRing({
    super.key,
    required this.child,
    this.colors = const [
      Color(0xFF06B6D4),
      Color(0xFF7C3AED),
      Color(0xFFEC4899),
    ],
    this.padding = 3,
    this.period = const Duration(milliseconds: 4200),
  });

  @override
  State<SpinningGradientRing> createState() => _SpinningGradientRingState();
}

class _SpinningGradientRingState extends State<SpinningGradientRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.period)
      ..repeat();
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
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: Container(
            padding: EdgeInsets.all(widget.padding),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [...widget.colors, widget.colors.first],
              ),
            ),
            child: Transform.rotate(
              // Counter-rotate so the avatar itself stays upright.
              angle: -_controller.value * 2 * math.pi,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

// ---------------------------------------------------------------------------
// ScaleOnTap - a springy press effect for product cards / buttons
// ---------------------------------------------------------------------------
class ScaleOnTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  const ScaleOnTap({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.965,
  });

  @override
  State<ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<ScaleOnTap> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null
          ? null
          : (_) => setState(() => _pressed = true),
      onTapUp: widget.onTap == null
          ? null
          : (_) => setState(() => _pressed = false),
      onTapCancel: widget.onTap == null
          ? null
          : () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
