import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/profile_theme.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/profile_widgets.dart';
import 'login_screen.dart';

/// MEMBER 1 - Settings.
///
/// Language, dark mode, notification preferences, offline sync, privacy and
/// log out (SRS: "Edit Profile, Notifications, Language, Dark Mode, Log Out").
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const List<String> _languages = [
    'English',
    'اردو',
    'हिन्दी',
    'العربية',
    'Español',
    '日本語',
    '한국어',
  ];

  static IconData _languageIcon(String language) {
    switch (language) {
      case 'اردو':
      case 'العربية':
        return Icons.language_rounded;
      case 'हिन्दी':
        return Icons.translate_rounded;
      case '日本語':
        return Icons.translate_rounded;
      case '한국어':
        return Icons.translate_rounded;
      default:
        return Icons.language_rounded;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProfileProvider>().loadSettings();
    });
  }

  Future<void> _pickLanguage(String current) async {
    final provider = context.read<ProfileProvider>();

    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: ProfileTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'App language',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ..._languages.map(
              (language) => ListTile(
                leading: Icon(
                  _languageIcon(language),
                  color: language == current
                      ? ProfileTheme.primary
                      : ProfileTheme.textSecondary,
                  size: 20,
                ),
                title: Text(
                  language,
                  style: TextStyle(
                    color: language == current
                        ? ProfileTheme.primary
                        : Colors.white,
                    fontWeight: language == current
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
                trailing: language == current
                    ? const Icon(Icons.check_rounded,
                        color: ProfileTheme.primary, size: 19)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(language),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (chosen == null || !mounted) return;
    await provider.updateSettings(provider.settings.copyWith(language: chosen));
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ProfileTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Log out?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'You will need your email and password to sign back in.',
          style: TextStyle(color: ProfileTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: ProfileTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ProfileTheme.rose,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Log out',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final settings = provider.settings;
    final user = provider.user;

    return ProfileScaffold(
      title: 'Settings',
      subtitle: 'Preferences for your account',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
        children: [
          // ------------------------------------------- account header
          FadeSlideIn(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: ProfileTheme.headerGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.manage_accounts_rounded,
                      color: Colors.white, size: 26),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Your account',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Lv ${user?.level ?? 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),

          // ------------------------------------------- appearance
          const SectionHeader(title: 'Appearance', accent: ProfileTheme.tertiary),
          const SizedBox(height: 10),
          FadeSlideIn(
            delay: const Duration(milliseconds: 50),
            child: SettingsSwitchTile(
              title: 'Dark Mode',
              subtitle: 'Optimised for late-night browsing',
              icon: Icons.dark_mode_rounded,
              color: ProfileTheme.tertiary,
              value: settings.darkMode,
              onChanged: (value) => provider
                  .updateSettings(provider.settings.copyWith(darkMode: value)),
            ),
          ),
          SettingsActionTile(
            title: 'Language',
            value: settings.language,
            icon: _languageIcon(settings.language),
            color: ProfileTheme.cyan,
            onTap: () => _pickLanguage(settings.language),
          ),
          const SizedBox(height: 20),

          // ------------------------------------------- notifications
          const SectionHeader(
            title: 'Notifications',
            accent: ProfileTheme.rose,
          ),
          const SizedBox(height: 10),
          FadeSlideIn(
            delay: const Duration(milliseconds: 100),
            child: Column(
              children: [
                SettingsSwitchTile(
                  title: 'Push notifications',
                  subtitle: 'Master switch for all push alerts',
                  icon: Icons.notifications_active_rounded,
                  color: ProfileTheme.rose,
                  value: settings.pushEnabled,
                  onChanged: (value) => provider.updateSettings(
                    provider.settings.copyWith(pushEnabled: value),
                  ),
                ),
                SettingsSwitchTile(
                  title: 'Event reminders',
                  subtitle: 'Conventions, meetups and screenings',
                  icon: Icons.event_available_rounded,
                  color: ProfileTheme.amber,
                  value: settings.pushEvents,
                  onChanged: settings.pushEnabled
                      ? (value) => provider.updateSettings(
                            provider.settings.copyWith(pushEvents: value),
                          )
                      : null,
                ),
                SettingsSwitchTile(
                  title: 'New fandom content',
                  subtitle: 'News, galleries, videos and podcasts',
                  icon: Icons.newspaper_rounded,
                  color: ProfileTheme.green,
                  value: settings.pushContent,
                  onChanged: settings.pushEnabled
                      ? (value) => provider.updateSettings(
                            provider.settings.copyWith(pushContent: value),
                          )
                      : null,
                ),
                SettingsSwitchTile(
                  title: 'Community activity',
                  subtitle: 'Replies, likes and new followers',
                  icon: Icons.forum_rounded,
                  color: ProfileTheme.primary,
                  value: settings.pushCommunity,
                  onChanged: settings.pushEnabled
                      ? (value) => provider.updateSettings(
                            provider.settings.copyWith(pushCommunity: value),
                          )
                      : null,
                ),
                SettingsSwitchTile(
                  title: 'Email updates',
                  subtitle: 'Weekly fandom digest by email',
                  icon: Icons.mark_email_unread_rounded,
                  color: ProfileTheme.textSecondary,
                  value: settings.emailUpdates,
                  onChanged: (value) => provider.updateSettings(
                    provider.settings.copyWith(emailUpdates: value),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ------------------------------------------- content
          const SectionHeader(title: 'Content', accent: ProfileTheme.green),
          const SizedBox(height: 10),
          FadeSlideIn(
            delay: const Duration(milliseconds: 150),
            child: Column(
              children: [
                SettingsSwitchTile(
                  title: 'Autoplay video',
                  subtitle: 'Start video clips automatically',
                  icon: Icons.play_circle_rounded,
                  color: ProfileTheme.green,
                  value: settings.autoplayVideo,
                  onChanged: (value) => provider.updateSettings(
                    provider.settings.copyWith(autoplayVideo: value),
                  ),
                ),
                SettingsSwitchTile(
                  title: 'Offline sync',
                  subtitle: 'Keep recent and saved content available offline',
                  icon: Icons.cloud_sync_rounded,
                  color: ProfileTheme.cyan,
                  value: settings.offlineSync,
                  onChanged: (value) => provider.updateSettings(
                    provider.settings.copyWith(offlineSync: value),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ------------------------------------------- privacy
          const SectionHeader(title: 'Privacy', accent: ProfileTheme.primary),
          const SizedBox(height: 10),
          FadeSlideIn(
            delay: const Duration(milliseconds: 180),
            child: SettingsSwitchTile(
              title: 'Public profile',
              subtitle: 'Let other fans find you',
              icon: Icons.visibility_rounded,
              color: ProfileTheme.primary,
              value: settings.isPublic,
              onChanged: (value) => provider.updateSettings(
                provider.settings.copyWith(isPublic: value),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ------------------------------------------- about + logout
          const SectionHeader(title: 'About', accent: ProfileTheme.textSecondary),
          const SizedBox(height: 10),
          SettingsActionTile(
            title: 'App version',
            value: '1.0.0 (Pocket Edition)',
            icon: Icons.info_outline_rounded,
            color: ProfileTheme.textSecondary,
            onTap: null,
            trailing: const SizedBox.shrink(),
          ),
          SettingsActionTile(
            title: 'Built with',
            value: 'Flutter + SQLite',
            icon: Icons.favorite_rounded,
            color: ProfileTheme.rose,
            onTap: null,
            trailing: const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),
          PressScale(
            onTap: _logout,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: ProfileTheme.rose.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: ProfileTheme.rose.withValues(alpha: 0.35)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.logout_rounded, color: ProfileTheme.rose, size: 19),
                  SizedBox(width: 12),
                  Text(
                    'Log Out',
                    style: TextStyle(
                      color: ProfileTheme.rose,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
