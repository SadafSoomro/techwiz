import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/event_models.dart';
import '../theme/app_theme.dart';
import '../theme/event_theme.dart';

/// MEMBER 4 - Events & Maps
/// A self contained, stylised map used by the Map / Event Details (Map View)
/// screens. It draws its own cartography with a CustomPainter so the app
/// works offline and does not need a Google Maps API key, while still
/// showing real event coordinates projected onto the canvas.
class EventMapView extends StatelessWidget {
  final List<MapPin> pins;
  final int? selectedPinId;
  final void Function(MapPin pin)? onPinTap;

  final bool showCurrentLocation;
  final double? currentLatitude;
  final double? currentLongitude;
  final String currentLabel;

  /// Shows the compass, scale bar and grid overlay.
  final bool showOverlays;

  const EventMapView({
    super.key,
    required this.pins,
    this.selectedPinId,
    this.onPinTap,
    this.showCurrentLocation = true,
    this.currentLatitude,
    this.currentLongitude,
    this.currentLabel = 'You',
    this.showOverlays = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final bounds = _Bounds.from(
          pins: pins,
          extraLat: showCurrentLocation ? currentLatitude : null,
          extraLng: showCurrentLocation ? currentLongitude : null,
        );

        const pad = EdgeInsets.symmetric(horizontal: 46, vertical: 60);

        return ClipRect(
          child: Stack(
            children: [
              // ---------------------- cartography ----------------------
              Positioned.fill(
                child: CustomPaint(painter: _MapBackgroundPainter()),
              ),
              Positioned.fill(
                child: CustomPaint(painter: _MapGridPainter()),
              ),

              // --------------------- current location -------------------
              if (showCurrentLocation &&
                  currentLatitude != null &&
                  currentLongitude != null)
                _positioned(
                  at: bounds.project(
                    currentLatitude!,
                    currentLongitude!,
                    size,
                    pad,
                  ),
                  width: 26,
                  height: 26,
                  child: const _CurrentLocationMarker(),
                ),

              // -------------------------- pins --------------------------
              ...pins.map((pin) {
                final offset = bounds.project(pin.latitude, pin.longitude, size, pad);
                final selected = pin.id == selectedPinId;

                return _positioned(
                  at: offset,
                  width: selected ? 190 : 52,
                  height: selected ? 86 : 58,
                  anchorBottom: true,
                  child: _MapMarker(
                    pin: pin,
                    selected: selected,
                    onTap: onPinTap == null ? null : () => onPinTap!(pin),
                  ),
                );
              }),

              // ------------------------ overlays ------------------------
              if (showOverlays) ...[
                const Positioned(
                  top: 14,
                  right: 14,
                  child: _Compass(),
                ),
                const Positioned(
                  left: 14,
                  bottom: 14,
                  child: _ScaleBar(),
                ),
                if (showCurrentLocation)
                  Positioned(
                    top: 14,
                    left: 14,
                    child: _CurrentLocationChip(label: currentLabel),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Positions a child so that [at] is the anchor point.
  /// When [anchorBottom] is true the anchor is the bottom-centre of the child
  /// (the tip of a map pin).
  Widget _positioned({
    required Offset at,
    required double width,
    required double height,
    required Widget child,
    bool anchorBottom = false,
  }) {
    return Positioned(
      left: at.dx - width / 2,
      top: anchorBottom ? at.dy - height : at.dy - height / 2,
      width: width,
      height: height,
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Projection
// ---------------------------------------------------------------------------
class _Bounds {
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  const _Bounds(this.minLat, this.maxLat, this.minLng, this.maxLng);

  factory _Bounds.from({
    required List<MapPin> pins,
    double? extraLat,
    double? extraLng,
  }) {
    final lats = <double>[];
    final lngs = <double>[];

    for (final pin in pins) {
      if (pin.latitude != 0 || pin.longitude != 0) {
        lats.add(pin.latitude);
        lngs.add(pin.longitude);
      }
    }
    if (extraLat != null && extraLng != null) {
      lats.add(extraLat);
      lngs.add(extraLng);
    }

    if (lats.isEmpty) {
      return const _Bounds(24.7, 25.0, 66.9, 67.2); // fallback: Karachi
    }

    var minLat = lats.reduce(math.min);
    var maxLat = lats.reduce(math.max);
    var minLng = lngs.reduce(math.min);
    var maxLng = lngs.reduce(math.max);

    // small breathing room so pins are not glued to the edges
    final latPad = math.max((maxLat - minLat) * 0.12, 0.02);
    final lngPad = math.max((maxLng - minLng) * 0.12, 0.02);

    minLat -= latPad;
    maxLat += latPad;
    minLng -= lngPad;
    maxLng += lngPad;

    return _Bounds(minLat, maxLat, minLng, maxLng);
  }

  double get _latSpan => maxLat - minLat;
  double get _lngSpan => maxLng - minLng;

  Offset project(double lat, double lng, Size size, EdgeInsets pad) {
    final w = math.max(size.width - pad.horizontal, 1);
    final h = math.max(size.height - pad.vertical, 1);

    final x = _lngSpan.abs() < 1e-9
        ? pad.left + w / 2
        : pad.left + ((lng - minLng) / _lngSpan) * w;

    final y = _latSpan.abs() < 1e-9
        ? pad.top + h / 2
        : pad.top + ((maxLat - lat) / _latSpan) * h;

    return Offset(x, y);
  }
}

// ---------------------------------------------------------------------------
// Cartography painter
// ---------------------------------------------------------------------------
class _MapBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(11);

    // ------------------------------ land ------------------------------
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = EventTheme.mapBackground,
    );

    // ------------------------------ water -----------------------------
    final river = Path()
      ..moveTo(-40, size.height * 0.18)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.34,
        size.width * 0.62,
        size.height * 0.52,
      )
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.68,
        size.width + 40,
        size.height * 0.86,
      );

    canvas.drawPath(
      river,
      Paint()
        ..color = EventTheme.mapWater
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(size.width * 0.13, 46)
        ..strokeCap = StrokeCap.round,
    );

    // ------------------------------ parks -----------------------------
    final parkPaint = Paint()..color = EventTheme.mapPark;
    for (int i = 0; i < 5; i++) {
      final w = 40 + random.nextDouble() * 90;
      final h = 34 + random.nextDouble() * 70;
      final rect = Rect.fromLTWH(
        random.nextDouble() * (size.width - w),
        random.nextDouble() * (size.height - h),
        w,
        h,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(14)),
        parkPaint,
      );
    }

    // --------------------------- city blocks ---------------------------
    const cell = 54.0;
    final blockPaint = Paint()..color = EventTheme.mapBlock;

    for (double x = 0; x < size.width; x += cell) {
      for (double y = 0; y < size.height; y += cell) {
        if (random.nextDouble() < 0.18) continue; // gaps become open ground

        final rect = Rect.fromLTWH(x + 7, y + 7, cell - 16, cell - 16);
        final radius = random.nextDouble() < 0.3 ? 4.0 : 2.0;

        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(radius)),
          blockPaint,
        );
      }
    }

    // ------------------------------ roads ------------------------------
    final minorRoad = Paint()
      ..color = EventTheme.mapRoad
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final majorRoad = Paint()
      ..color = EventTheme.mapRoadMajor
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    for (double y = 0; y < size.height; y += cell * 2) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), minorRoad);
    }
    for (double x = 0; x < size.width; x += cell * 2) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), minorRoad);
    }

    // two major arteries across the view
    canvas.drawLine(
      Offset(-20, size.height * 0.34),
      Offset(size.width + 20, size.height * 0.28),
      majorRoad,
    );
    canvas.drawLine(
      Offset(size.width * 0.28, -20),
      Offset(size.width * 0.38, size.height + 20),
      majorRoad,
    );
  }

  @override
  bool shouldRepaint(covariant _MapBackgroundPainter oldDelegate) => false;
}

/// Subtle grid + edge vignette drawn above the cartography.
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.022)
      ..strokeWidth = 1;

    const step = 34.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // vignette so overlays stay readable
    final vignette = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black.withValues(alpha: 0.35),
          Colors.transparent,
          Colors.black.withValues(alpha: 0.45),
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Markers
// ---------------------------------------------------------------------------
class _MapMarker extends StatelessWidget {
  final MapPin pin;
  final bool selected;
  final VoidCallback? onTap;

  const _MapMarker({required this.pin, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = EventTheme.categoryColor(pin.category);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // -------------------- label (selected only) --------------------
          if (selected)
            Flexible(
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF10141C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.8)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pin.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${pin.city} · ${EventTheme.prettyDate(pin.eventDate)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // -------------------------- the pin --------------------------
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: selected ? 40 : 34,
            height: selected ? 40 : 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withValues(alpha: 0.72)],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: selected ? 0.95 : 0.8),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.55),
                  blurRadius: selected ? 18 : 10,
                  spreadRadius: selected ? 2 : 0,
                ),
              ],
            ),
            child: Icon(
              EventTheme.categoryIcon(pin.category),
              color: Colors.white,
              size: selected ? 20 : 17,
            ),
          ),

          // pin tip
          Transform.translate(
            offset: const Offset(0, -4),
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentLocationMarker extends StatelessWidget {
  const _CurrentLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: EventTheme.teal.withValues(alpha: 0.22),
          ),
        ),
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: EventTheme.teal,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: EventTheme.teal.withValues(alpha: 0.7),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Overlays
// ---------------------------------------------------------------------------
class _Compass extends StatelessWidget {
  const _Compass();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFF10141C).withValues(alpha: 0.85),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.navigation_rounded, color: EventTheme.primary, size: 16),
          Text(
            'N',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScaleBar extends StatelessWidget {
  const _ScaleBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF10141C).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 6,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.white.withValues(alpha: 0.7), width: 2),
                right: BorderSide(color: Colors.white.withValues(alpha: 0.7), width: 2),
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.7), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '500 km',
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentLocationChip extends StatelessWidget {
  final String label;

  const _CurrentLocationChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF10141C).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EventTheme.teal.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.my_location_rounded, color: EventTheme.teal, size: 13),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
