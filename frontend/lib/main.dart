import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/admin_provider.dart';
import 'providers/ai_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/community_provider.dart';
import 'providers/content_provider.dart';
import 'providers/event_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/shop_provider.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/admin_storage.dart';
import 'services/auth_storage.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  GoogleFonts.config.allowRuntimeFetching = false;
  unawaited(_warmUpFonts());

  await Future.wait([
    AuthStorage.preload(),
    AdminStorage.preload(),
  ]);

  PaintingBinding.instance.imageCache.maximumSize = 150;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 120 << 20;

  runApp(const MyApp());
}

Future<void> _warmUpFonts() async {
  const weights = <FontWeight>[
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
    FontWeight.w800,
    FontWeight.w900,
  ];

  try {
    for (final weight in weights) {
      GoogleFonts.inter(fontWeight: weight);
      GoogleFonts.outfit(fontWeight: weight);
    }
    GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    await GoogleFonts.pendingFonts().timeout(const Duration(seconds: 4));
  } catch (_) {}
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => ContentProvider()),
        ChangeNotifierProvider(create: (_) => CommunityProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => ShopProvider()),
        ChangeNotifierProvider(create: (_) => AiProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MaterialApp(
        title: 'FANDOM VERSE',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          final clampedTextScaler = mediaQuery.textScaler.clamp(
            minScaleFactor: 0.85,
            maxScaleFactor: 1.15,
          );
          return MediaQuery(
            data: mediaQuery.copyWith(textScaler: clampedTextScaler),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF080612),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA855F7)),
          ),
        ),
      );
    }
    if (auth.isAuthenticated) {
      final isAdmin =
          (auth.user?['role'] ?? 'user').toString().toLowerCase() == 'admin';
      return isAdmin ? const AdminShell() : const HomeScreen();
    }
    return const LoginScreen();
  }
}
