import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/fandom_logo.dart';
import 'admin/admin_shell.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _navigateNext();
    });
  }

  Future<void> _navigateNext() async {
    final authProvider = context.read<AuthProvider>();
    final profileProvider = context.read<ProfileProvider>();

    final minimumDisplay = Future<void>.delayed(
      const Duration(milliseconds: 900),
    );

    await authProvider.checkAuthStatus();

    final isAdmin =
        authProvider.isAuthenticated &&
        (authProvider.user?['role'] ?? 'user').toString().toLowerCase() ==
            'admin';

    if (authProvider.isAuthenticated && !isAdmin) {
      await _prepareHome(profileProvider);
    } else {
      await _prepareLoginArtwork();
    }

    await minimumDisplay;
    if (!mounted) return;

    if (isAdmin) {
      Navigator.of(context).pushReplacement(_readyRoute(const AdminShell()));
    } else if (authProvider.isAuthenticated) {
      Navigator.of(context).pushReplacement(_readyRoute(const HomeScreen()));
    } else {
      Navigator.of(context).pushReplacement(_readyRoute(const LoginScreen()));
    }
  }

  Future<void> _prepareHome(ProfileProvider profileProvider) async {
    try {
      await profileProvider.loadDashboard().timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  Future<void> _prepareLoginArtwork() async {
    const assets = [
      'assets/images/fandom_logo.png',
      'assets/images/google_logo.png',
      'assets/images/splash_bg.png',
    ];

    for (final path in assets) {
      try {
        await precacheImage(
          AssetImage(path),
          context,
        ).timeout(const Duration(seconds: 3));
      } catch (_) {}
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash_bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.backgroundGradient,
                  ),
                  child: const Center(child: FandomLogoWidget(height: 120)),
                );
              },
            ),
          ),

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
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFA855F7),
                    ),
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
