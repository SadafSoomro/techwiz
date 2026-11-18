import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/event_provider.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../theme/event_theme.dart';
import '../widgets/fandom_logo.dart';
import 'home_screen.dart';

/// Mandatory Location Permission Screen.
/// Displayed after login on mobile or any device. User must allow location
/// before proceeding to use the rest of the application.
class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _detecting = false;
  String _statusText = 'Allow location to locate yourself on the live map';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleAllowLocation() async {
    setState(() {
      _detecting = true;
      _statusText = 'Tracing your current location...';
    });

    try {
      final location = await LocationService.detectCurrentLocation();

      // Persist location
      await LocationService.saveLocation(location);

      if (!mounted) return;

      // Update EventProvider with real-time detected coordinates & area
      final eventProvider = context.read<EventProvider>();
      eventProvider.useDeviceLocation(
        lat: location.latitude,
        lng: location.longitude,
        city: location.city,
        area: location.area,
      );
      await eventProvider.loadMapPins(city: location.city);
      await eventProvider.loadNearby(radiusKm: 200);

      if (!mounted) return;

      setState(() {
        _statusText = '📍 Located: ${location.displayName}!';
      });

      await Future.delayed(const Duration(milliseconds: 600));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Location enabled! Welcome to ${location.displayName}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: EventTheme.teal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );

      // Navigate to Home Screen and clear navigation stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _detecting = false;
        _statusText = 'Could not acquire GPS fix. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // User must grant permission to continue
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0F172A), // Dark slate
                Color(0xFF070B14), // Deep void
              ],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxHeight < 720;
                final radarScale = isCompact ? 0.78 : 1.0;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 20 : 24,
                          vertical: isCompact ? 14 : 20,
                        ),
                        child: Column(
                          children: [
                            // Logo
                            Center(
                              child: FandomLogoWidget(height: isCompact ? 32 : 38),
                            ),
                            SizedBox(height: isCompact ? 16 : 24),

                            // Animated Radar Pulse with GPS Pin
                            Center(
                              child: AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  final val = _pulseController.value;
                                  return Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Outer ring
                                      Container(
                                        width: (150 + (val * 34)) * radarScale,
                                        height: (150 + (val * 34)) * radarScale,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: EventTheme.teal.withValues(alpha: (1 - val) * 0.4),
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      // Middle ring
                                      Container(
                                        width: (115 + (val * 24)) * radarScale,
                                        height: (115 + (val * 24)) * radarScale,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppTheme.primaryColor.withValues(alpha: (1 - val) * 0.6),
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      // Glowing inner radar circle
                                      Container(
                                        width: 96 * radarScale,
                                        height: 96 * radarScale,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              EventTheme.teal.withValues(alpha: 0.35),
                                              AppTheme.primaryColor.withValues(alpha: 0.15),
                                              Colors.transparent,
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: EventTheme.teal.withValues(alpha: 0.3),
                                              blurRadius: 24,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: 56 * radarScale,
                                            height: 56 * radarScale,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFF00E5FF),
                                                  Color(0xFF7047EB),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                                                  blurRadius: 14,
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              Icons.location_on_rounded,
                                              size: 30 * radarScale,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),

                            SizedBox(height: isCompact ? 18 : 26),

                            // Headline
                            Text(
                              'Allow Location Access',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.rajdhani(
                                fontSize: isCompact ? 24 : 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Explanation
                            Text(
                              'To unlock FandomVerse, allow location access. Your live coordinates will be traced to pinpoint you on the interactive map and show anime meetups near you.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: isCompact ? 12.5 : 13.5,
                                color: Colors.white70,
                                height: 1.4,
                              ),
                            ),

                            SizedBox(height: isCompact ? 16 : 22),

                            // Feature bullets
                            _featureRow(
                              icon: Icons.map_rounded,
                              title: 'Live Location on Map',
                              subtitle: 'Trace your real position with an active GPS pin on the map.',
                              isCompact: isCompact,
                            ),
                            SizedBox(height: isCompact ? 10 : 12),
                            _featureRow(
                              icon: Icons.event_available_rounded,
                              title: 'Nearby Anime Events',
                              subtitle: 'Discover fan conventions, screenings, and meetups in your city.',
                              isCompact: isCompact,
                            ),
                            SizedBox(height: isCompact ? 10 : 12),
                            _featureRow(
                              icon: Icons.navigation_rounded,
                              title: 'Interactive City Navigation',
                              subtitle: 'Filter and jump between cities with instant camera navigation.',
                              isCompact: isCompact,
                            ),

                            const Spacer(),
                            SizedBox(height: isCompact ? 14 : 20),

                            // Status Text
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                _statusText,
                                key: ValueKey(_statusText),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: _detecting ? EventTheme.teal : Colors.white60,
                                  fontWeight: _detecting ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Mandatory Allow Button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF00E5FF),
                                      Color(0xFF7047EB),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: _detecting ? null : _handleAllowLocation,
                                  child: _detecting
                                      ? const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              'Tracing Location...',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.my_location_rounded, color: Colors.white, size: 20),
                                            const SizedBox(width: 8),
                                            Text(
                                              'ALLOW LOCATION ACCESS',
                                              style: GoogleFonts.rajdhani(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.0,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _featureRow({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isCompact = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(isCompact ? 6 : 8),
          decoration: BoxDecoration(
            color: EventTheme.teal.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: EventTheme.teal.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, size: isCompact ? 16 : 18, color: EventTheme.teal),
        ),
        SizedBox(width: isCompact ? 10 : 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: isCompact ? 12.5 : 13.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: isCompact ? 10.5 : 11.5,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
