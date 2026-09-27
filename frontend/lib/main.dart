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
import 'screens/splash_screen.dart';
import 'services/auth_storage.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The Inter / Outfit TTFs ship inside the app bundle (assets/fonts), so a
  // font must never be requested over the network. Turning runtime fetching
  // off makes that guarantee explicit: a missing variant falls back to the
  // system font instead of stalling the UI on an HTTP request.
  GoogleFonts.config.allowRuntimeFetching = false;

  // Start loading the bundled fonts, but deliberately do NOT await them before
  // `runApp`. The splash screen is pure artwork with no text on it, so it can
  // paint immediately while the font files stream in from the bundle. Awaiting
  // here used to hold the very first frame hostage to ~2 MB of font data.
  unawaited(_warmUpFonts());

  // Reading SharedPreferences is async and was previously done again on every
  // single API call; doing it once here means the first request never waits.
  // This is a local, single-digit-millisecond call.
  await AuthStorage.preload();

  runApp(const MyApp());
}

/// Loads every Inter / Outfit weight the app actually uses into the font
/// engine, so screens that appear later never re-layout their text. Capped by a
/// timeout so a problem here can never block startup.
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
      // Creating the styles is what queues the asset loads.
      GoogleFonts.inter(fontWeight: weight);
      GoogleFonts.outfit(fontWeight: weight);
    }
    // Covers the weights used by the global text theme (w400 / w500).
    GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    await GoogleFonts.pendingFonts().timeout(const Duration(seconds: 4));
  } catch (_) {
    // Cosmetic only - never hold the app hostage for a font.
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // MEMBER 1 - Profile, Fandom Selection & Home
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        // MEMBER 2 - Fandom Content (hub, news, gallery, video, podcasts)
        ChangeNotifierProvider(create: (_) => ContentProvider()),
        // MEMBER 3 - Search & Community
        ChangeNotifierProvider(create: (_) => CommunityProvider()),
        // MEMBER 4 - Events & Maps
        ChangeNotifierProvider(create: (_) => EventProvider()),
        // MEMBER 5 - Merchandise Store + AI Fan Helper
        ChangeNotifierProvider(create: (_) => ShopProvider()),
        ChangeNotifierProvider(create: (_) => AiProvider()),
        // MEMBER 6 - Admin + Security (separate session, own panel)
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MaterialApp(
        title: 'FANDOM VERSE',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
