import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/shop_theme.dart';

/// FANDOM VERSE - AI Fan Helper companion.
///
/// A cute cartoon robot that floats a little above the navigation bar, on the
/// bottom-left of the app shell. It deliberately lives *outside* the bottom bar
/// so the AI helper keeps its own, always-reachable entry point instead of
/// being buried inside the Shop tab. Tapping it opens `AiHelperScreen`.
class AiAgentButton extends StatefulWidget {
  const AiAgentButton({super.key, this.onTap, this.size = 62});

  /// Invoked when the little robot is tapped.
  final VoidCallback? onTap;

  /// Size of the robot itself (the speech bubble may overflow slightly).
  final double size;

  @override
  State<AiAgentButton> createState() => _AiAgentButtonState();
}

class _AiAgentButtonState extends State<AiAgentButton>
    with TickerProviderStateMixin {
  /// Slow up/down bob + a tiny wobble so it feels alive.
  late final AnimationController _bob;

  /// Periodic blink.
  late final AnimationController _blink;

  /// Fades the "Hi!" bubble in and out.
  late final AnimationController _greet;

  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
    _greet = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();
  }

  @override
  void dispose() {
    _bob.dispose();
    _blink.dispose();
    _greet.dispose();
    super.dispose();
  }

  /// 1 while the eyes are open, squeezed shut for a blink at the end of every
  /// cycle.
  double get _eyeScale {
    final t = _blink.value;
    if (t < 0.9) return 1;
    final p = (t - 0.9) / 0.1;
    return (1 - math.sin(p * math.pi) * 0.94).clamp(0.06, 1.0);
  }

  /// 0 -> bubble hidden, 1 -> bubble fully visible.
  double get _greetOpacity {
    final t = _greet.value;
    if (t < 0.08) return t / 0.08;
    if (t < 0.55) return 1;
    if (t < 0.7) return 1 - (t - 0.55) / 0.15;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    return Semantics(
      button: true,
      label: 'AI Fan Helper',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: Listenable.merge([_bob, _blink, _greet]),
          builder: (context, _) {
            final bob = _bob.value;
            return Transform.translate(
              offset: Offset(0, (bob * -5) + 2.5),
              child: Transform.rotate(
                angle: (bob - 0.5) * 0.1,
                child: Transform.scale(
                  scale: _pressed ? 0.9 : 1,
                  child: SizedBox(
                    width: size,
                    height: size,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        _halo(size),
                        _antenna(size),
                        _pods(size),
                        _head(size),
                        _bubble(size),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // --------------------------------------------------------------- pieces

  /// Soft cyan glow behind the robot.
  Widget _halo(double size) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              ShopTheme.accent.withValues(alpha: 0.38),
              ShopTheme.accent.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _antenna(double size) {
    return Positioned(
      top: size * 0.04,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 2.4,
            height: size * 0.11,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: size * 0.15,
            height: size * 0.15,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9AD8), Color(0xFFEC4899)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEC4899).withValues(alpha: 0.85),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Little side "headphones" so the robot reads as a friendly gadget.
  Widget _pods(double size) {
    Widget pod() => Container(
          width: size * 0.11,
          height: size * 0.26,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.35),
                Colors.white.withValues(alpha: 0.12),
              ],
            ),
            borderRadius: BorderRadius.circular(size * 0.055),
          ),
        );

    return Positioned(
      top: size * 0.38,
      child: SizedBox(
        width: size * 0.9,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [pod(), pod()],
        ),
      ),
    );
  }

  Widget _head(double size) {
    return Positioned(
      top: size * 0.26,
      child: Transform.rotate(
        angle: -0.04,
        child: Container(
          width: size * 0.78,
          height: size * 0.66,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.26),
            gradient: ShopTheme.aiGradient,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.55),
              width: 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: ShopTheme.primary.withValues(alpha: 0.6),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _eye(size),
                  SizedBox(width: size * 0.14),
                  _eye(size),
                ],
              ),
              SizedBox(height: size * 0.055),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _cheek(size),
                  SizedBox(width: size * 0.06),
                  _smile(size),
                  SizedBox(width: size * 0.06),
                  _cheek(size),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _eye(double size) {
    return Transform.scale(
      scaleY: _eyeScale,
      child: Container(
        width: size * 0.145,
        height: size * 0.17,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: Center(
          child: Container(
            width: size * 0.07,
            height: size * 0.085,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF111827),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cheek(double size) {
    return Container(
      width: size * 0.12,
      height: size * 0.07,
      decoration: BoxDecoration(
        color: const Color(0xFFFF7AB6).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(size * 0.04),
      ),
    );
  }

  Widget _smile(double size) {
    return Container(
      width: size * 0.23,
      height: size * 0.11,
      decoration: BoxDecoration(
        border: const Border(
          bottom: BorderSide(color: Colors.white, width: 2.2),
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(size * 0.12),
          bottomRight: Radius.circular(size * 0.12),
        ),
      ),
    );
  }

  Widget _bubble(double size) {
    return Positioned(
      top: -size * 0.12,
      right: -size * 0.24,
      child: IgnorePointer(
        child: Opacity(
          opacity: _greetOpacity,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              'Hi!',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: ShopTheme.primaryDark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
