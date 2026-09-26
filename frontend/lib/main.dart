import 'package:flutter/material.dart';
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
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
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
