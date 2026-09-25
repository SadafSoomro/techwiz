import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    final authProvider = context.read<AuthProvider>();
    final profileProvider = context.read<ProfileProvider>();

    // The splash always stays on screen for at least this long, so it is never
    // skipped (or flashed) before the next screen is ready.
    final minimumDisplay = Future<void>.delayed(
      const Duration(milliseconds: 2500),
    );

    // 1. Restore the saved session while the artwork is on screen.
    await authProvider.checkAuthStatus();

    if (authProvider.isAuthenticated) {
      // 2. Load the dashboard aggregate BEFORE navigating, so the Home screen
      //    is fully populated the moment it appears (no shimmer / empty state).
      await _prepareHome(profileProvider);
    } else {
      // 3. Make the login screen ready before it is shown: its artwork is
      //    precached so nothing pops in after the transition.
      await _prepareLoginArtwork();
    }

    // 4. Hold the splash until the minimum display time has also elapsed.
    await minimumDisplay;
    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        _readyRoute(const HomeScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        _readyRoute(const LoginScreen()),
      );
    }
  }

  /// Preloads the Home dashboard. A slow or failing request can never hold the
  /// splash hostage - it is capped and errors are swallowed.
  Future<void> _prepareHome(ProfileProvider profileProvider) async {
    try {
      await profileProvider
          .loadDashboard()
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      // The Home screen shows its own error/empty state if this fails.
    }
  }

  /// Warms the image cache with the artwork the login screen renders.
  Future<void> _prepareLoginArtwork() async {
    const assets = [
      'assets/images/fandom_logo.png',
      'assets/images/google_logo.png',
    ];

    for (final path in assets) {
      try {
        await precacheImage(AssetImage(path), context)
            .timeout(const Duration(seconds: 3));
      } catch (_) {
        // A missing asset must never block the splash.
      }
    }
  }

  /// A fade-through route so the next screen is fully built before the splash
  /// fades away instead of appearing abruptly.
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Exact User-Provided Full HD Splash Screen Artwork
          Positioned.fill(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Image.asset(
                'assets/images/splash_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: AppTheme.backgroundGradient,
                    ),
                  );
                },
              ),
            ),
          ),

          // Subtle Bottom Progress Bar
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 130,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: const LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA855F7)),
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
