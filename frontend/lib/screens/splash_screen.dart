import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/fandom_logo.dart';
import 'admin/admin_shell.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'maintenance_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressController;
  late final Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    );

    _progressController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _navigateNext();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _navigateNext() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final profileProvider = context.read<ProfileProvider>();

      // Safe parallel fetch with timeouts
      final results = await Future.wait<dynamic>([
        ApiService.getSystemStatus().timeout(
          const Duration(seconds: 3),
          onTimeout: () => {'maintenance': false, 'registration': true},
        ),
        authProvider.checkAuthStatus().timeout(
          const Duration(seconds: 3),
          onTimeout: () => false,
        ),
        Future<void>.delayed(const Duration(milliseconds: 1400)),
      ]);

      final systemStatus = results[0] as Map<String, dynamic>;
      final isMaintenance = systemStatus['maintenance'] == true;

      final isAdmin = authProvider.isAuthenticated &&
          (authProvider.user?['role'] ?? 'user').toString().toLowerCase() ==
              'admin';

      if (authProvider.isAuthenticated && !isAdmin && !isMaintenance) {
        unawaited(
          profileProvider
              .loadDashboard()
              .timeout(const Duration(seconds: 5), onTimeout: () => null),
        );
      }

      if (!mounted) return;

      if (isAdmin) {
        Navigator.of(context).pushReplacement(_readyRoute(const AdminShell()));
      } else if (isMaintenance) {
        Navigator.of(context)
            .pushReplacement(_readyRoute(const MaintenanceScreen()));
      } else if (authProvider.isAuthenticated) {
        Navigator.of(context).pushReplacement(_readyRoute(const HomeScreen()));
      } else {
        Navigator.of(context).pushReplacement(_readyRoute(const LoginScreen()));
      }
    } catch (_) {
      if (mounted) {
        Navigator.of(context).pushReplacement(_readyRoute(const LoginScreen()));
      }
    }
  }

  PageRouteBuilder<void> _readyRoute(Widget screen) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (_, _, _) => screen,
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080612),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0B24),
              Color(0xFF0A0716),
              Color(0xFF05030A),
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ambient soft glowing aura behind the logo
            Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6366F1).withValues(alpha: 0.22),
                    const Color(0xFFA855F7).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // Centered Fandom Brand & Identity
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FandomLogoWidget(height: 120),
                      const SizedBox(height: 20),
                      Text(
                        'FANDOM VERSE',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 3.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your Ultimate Fandom Universe',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Sleek animated progress bar at the bottom
            Positioned(
              bottom: 45,
              left: 0,
              right: 0,
              child: SafeArea(
                top: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, _) {
                          return Container(
                            width: 160,
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF131127),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFA855F7)
                                    .withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: LinearProgressIndicator(
                                value: _progressAnimation.value,
                                minHeight: 4.5,
                                backgroundColor: Colors.transparent,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFA855F7),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Loading your universe...',
                        style: GoogleFonts.inter(
                          color: AppTheme.textMuted,
                          fontSize: 11.5,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
