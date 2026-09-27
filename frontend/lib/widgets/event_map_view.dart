import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../config/api_config.dart';
import '../models/event_models.dart';
import '../theme/app_theme.dart';
import '../theme/event_theme.dart';

/// MEMBER 4 - Events & Maps
/// Mapbox powered interactive map widget using `flutter_map` and the Mapbox API key.
/// Displays real-world map tiles with pins, interactive pan/zoom, compass, scale bar,
/// and smooth recentering.
class EventMapView extends StatefulWidget {
  final List<MapPin> pins;
  final int? selectedPinId;
  final void Function(MapPin pin)? onPinTap;

  final bool showCurrentLocation;
  final double? currentLatitude;
  final double? currentLongitude;
  final String currentLabel;

  /// Shows the compass, scale bar, zoom controls, and location chip overlay.
  final bool showOverlays;

  /// Space reserved by screen chrome (filters at top, card/carousel at bottom).
  final EdgeInsets overlayPadding;

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
    this.overlayPadding = EdgeInsets.zero,
  });

  @override
  State<EventMapView> createState() => _EventMapViewState();
}

class _EventMapViewState extends State<EventMapView> {
  final MapController _mapController = MapController();

  LatLng get _initialCenter {
    if (widget.showCurrentLocation &&
        widget.currentLatitude != null &&
        widget.currentLongitude != null &&
        widget.currentLatitude != 0 &&
        widget.currentLongitude != 0) {
      return LatLng(widget.currentLatitude!, widget.currentLongitude!);
    }
    if (widget.pins.isNotEmpty) {
      final validPins = widget.pins.where((p) => p.latitude != 0 || p.longitude != 0).toList();
      if (validPins.isNotEmpty) {
        final avgLat = validPins.map((p) => p.latitude).reduce((a, b) => a + b) / validPins.length;
        final avgLng = validPins.map((p) => p.longitude).reduce((a, b) => a + b) / validPins.length;
        return LatLng(avgLat, avgLng);
      }
    }
    return const LatLng(24.8607, 67.0011); // Fallback: Karachi
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1.0);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1.0);
  }

  void _recenter() {
    _mapController.move(_initialCenter, 13.0);
  }

  @override
  void didUpdateWidget(covariant EventMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedPinId != null && widget.selectedPinId != oldWidget.selectedPinId) {
      final pin = widget.pins.where((p) => p.id == widget.selectedPinId).firstOrNull;
      if (pin != null && (pin.latitude != 0 || pin.longitude != 0)) {
        _mapController.move(LatLng(pin.latitude, pin.longitude), 14.0);
      }
    } else if (widget.pins != oldWidget.pins ||
        widget.currentLatitude != oldWidget.currentLatitude ||
        widget.currentLongitude != oldWidget.currentLongitude) {
      final center = _initialCenter;
      _mapController.move(center, 12.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _initialCenter;

    return ClipRect(
      child: Stack(
        children: [
          // -------------------------- Mapbox Tile Map --------------------------
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 12.0,
              minZoom: 2.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              // Mapbox Vector Dark Style Tile Layer
              TileLayer(
                urlTemplate: ApiConfig.mapboxTileUrl(style: 'dark-v11'),
                fallbackUrl: ApiConfig.fallbackTileUrl,
                userAgentPackageName: 'com.fandomverse.app',
                maxZoom: 19,
                tileProvider: NetworkTileProvider(),
              ),

              // Markers Layer
              MarkerLayer(
                markers: [
                  // Current user location marker
                  if (widget.showCurrentLocation &&
                      widget.currentLatitude != null &&
                      widget.currentLongitude != null &&
                      widget.currentLatitude != 0 &&
                      widget.currentLongitude != 0)
                    Marker(
                      point: LatLng(widget.currentLatitude!, widget.currentLongitude!),
                      width: 28,
                      height: 28,
                      child: const _CurrentLocationMarker(),
                    ),

                  // Event pin markers
                  ...widget.pins.map((pin) {
                    if (pin.latitude == 0 && pin.longitude == 0) return null;
                    final selected = pin.id == widget.selectedPinId;

                    return Marker(
                      point: LatLng(pin.latitude, pin.longitude),
                      width: selected ? 190 : 52,
                      height: selected ? 86 : 58,
                      alignment: Alignment.bottomCenter,
                      child: _MapMarker(
                        pin: pin,
                        selected: selected,
                        onTap: widget.onPinTap == null ? null : () => widget.onPinTap!(pin),
                      ),
                    );
                  }).whereType<Marker>(),
                ],
              ),
            ],
          ),

          // Edge vignette gradient to maintain app aesthetic
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _VignettePainter()),
            ),
          ),

          // ------------------------ Map Overlays ------------------------
          if (widget.showOverlays) ...[
            // Compass N
            Positioned(
              top: 14 + widget.overlayPadding.top,
              right: 14,
              child: _Compass(onTap: _recenter),
            ),

            // Zoom (+/-) controls
            Positioned(
              top: 68 + widget.overlayPadding.top,
              right: 14,
              child: _ZoomControls(
                onZoomIn: _zoomIn,
                onZoomOut: _zoomOut,
              ),
            ),

            // Scale Bar
            Positioned(
              left: 14,
              bottom: 14 + widget.overlayPadding.bottom,
              child: const _ScaleBar(),
            ),

            // User location chip
            if (widget.showCurrentLocation)
              Positioned(
                top: 14 + widget.overlayPadding.top,
                left: 14,
                child: _CurrentLocationChip(
                  label: widget.currentLabel,
                  onTap: _recenter,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Vignette Painter
// ---------------------------------------------------------------------------
class _VignettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Pin Marker Widget
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
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected)
            Flexible(
              child: Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10141C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.85)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
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

          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: selected ? 40 : 34,
            height: selected ? 40 : 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withValues(alpha: 0.75)],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: selected ? 0.95 : 0.8),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.6),
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

          Transform.translate(
            offset: const Offset(0, -3),
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 8,
                height: 8,
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

// ---------------------------------------------------------------------------
// User Location Pulse Marker
// ---------------------------------------------------------------------------
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
            color: EventTheme.teal.withValues(alpha: 0.25),
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
                color: EventTheme.teal.withValues(alpha: 0.75),
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
// Compass Control
// ---------------------------------------------------------------------------
class _Compass extends StatelessWidget {
  final VoidCallback? onTap;
  const _Compass({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF10141C).withValues(alpha: 0.9),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 8,
            ),
          ],
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Zoom (+/-) Controls
// ---------------------------------------------------------------------------
class _ZoomControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const _ZoomControls({required this.onZoomIn, required this.onZoomOut});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF10141C).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            onPressed: onZoomIn,
          ),
          Divider(height: 1, thickness: 1, color: Colors.white.withValues(alpha: 0.1)),
          IconButton(
            constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.remove_rounded, color: Colors.white, size: 20),
            onPressed: onZoomOut,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scale Bar
// ---------------------------------------------------------------------------
class _ScaleBar extends StatelessWidget {
  const _ScaleBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF10141C).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 5,
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
            'Mapbox Maps',
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Location Chip
// ---------------------------------------------------------------------------
class _CurrentLocationChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _CurrentLocationChip({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF10141C).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: EventTheme.teal.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.my_location_rounded, color: EventTheme.teal, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
