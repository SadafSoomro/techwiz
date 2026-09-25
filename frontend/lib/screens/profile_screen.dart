import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/profile_theme.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/app_alert.dart';
import '../widgets/app_image.dart';
import '../widgets/profile_widgets.dart';
import 'edit_profile_screen.dart';
import 'invite_friends_screen.dart';
import 'login_screen.dart';
import 'my_fandoms_screen.dart';
import 'notifications_screen.dart';
import 'profile_badges_screen.dart';
import 'settings_screen.dart';
import 'social_tasks_screen.dart';

/// MEMBER 1 - Profile and dashboard account screen.
///
/// Rendered either as a standalone page (from the app bar / settings) or
/// embedded as the "Profile" tab of `HomeScreen`.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProfileProvider>().loadProfile();
    });
  }

  Future<void> _push(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ProfileTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Logout Confirmation',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to log out of FANDOM VERSE?',
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Logout',
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
    final auth = context.watch<AuthProvider>();
    final user = provider.user;
    final name = user?.name ?? auth.user?['name'] ?? 'Fan';
    final email = user?.email ?? auth.user?['email'] ?? '';

    final content = _buildContent(provider, name, email);

    if (widget.embedded) {
      return RefreshIndicator(
        color: ProfileTheme.primary,
        onRefresh: () => provider.loadProfile(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 30),
          children: content,
        ),
      );
    }

    return ProfileScaffold(
      title: 'Profile',
      subtitle: 'Your FANDOM VERSE account',
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_rounded, color: Colors.white),
          onPressed: () async {
            await _push(const EditProfileScreen());
            if (mounted) provider.loadProfile();
          },
        ),
      ],
      child: RefreshIndicator(
        color: ProfileTheme.primary,
        onRefresh: () => provider.loadProfile(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
          children: content,
        ),
      ),
    );
  }

  List<Widget> _buildContent(
    ProfileProvider provider,
    String name,
    String email,
  ) {
    final user = provider.user;
    final stats = provider.stats;
    final badges = provider.earnedBadges;

    return [
      // ------------------------------------------------ header card
      FadeSlideIn(
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: ProfileTheme.headerGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: ProfileTheme.primary.withValues(alpha: 0.32),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _AnimatedAvatar(
                    path: user?.avatar ?? '',
                    name: name,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            _headerChip(
                              Icons.workspace_premium_rounded,
                              'Level ${user?.level ?? 1}',
                            ),
                            const SizedBox(width: 7),
                            _headerChip(
                              Icons.local_fire_department_rounded,
                              '${user?.points ?? 0} pts',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if ((user?.bio ?? '').isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    user!.bio,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              ProfileTheme.levelName(user?.level ?? 1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${user?.points ?? 0} / ${user?.nextLevelPoints ?? 100} pts',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        AnimatedProgressBar(
                          value: user?.levelProgress ?? 0,
                          height: 7,
                          colors: const [Colors.white, Color(0xFFE0E7FF)],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GradientActionButton(
                label: 'Edit Profile',
                icon: Icons.edit_rounded,
                height: 46,
                gradient: const LinearGradient(
                  colors: [Colors.white, Color(0xFFE0E7FF)],
                ),
                onPressed: () async {
                  await _push(const EditProfileScreen());
                  if (mounted) provider.loadProfile();
                },
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 22),

      // ------------------------------------------------ stats
      const SectionHeader(title: 'Your Activity', accent: ProfileTheme.cyan),
      const SizedBox(height: 12),
      FadeSlideIn(
        delay: const Duration(milliseconds: 60),
        child: Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'Fandoms',
                value: stats.fandomCount,
                icon: Icons.auto_awesome_rounded,
                color: ProfileTheme.tertiary,
                onTap: () => _push(const MyFandomsScreen()),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'Badges',
                value: stats.badgeCount,
                icon: Icons.workspace_premium_rounded,
                color: ProfileTheme.amber,
                onTap: () => _push(const ProfileBadgesScreen()),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'Bookmarks',
                value: stats.bookmarksCount,
                icon: Icons.bookmark_rounded,
                color: ProfileTheme.rose,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      FadeSlideIn(
        delay: const Duration(milliseconds: 120),
        child: Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'Viewed',
                value: stats.viewedCount,
                icon: Icons.visibility_rounded,
                color: ProfileTheme.cyan,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'Offline',
                value: stats.offlineCount,
                icon: Icons.download_done_rounded,
                color: ProfileTheme.green,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'Events',
                value: stats.savedEventsCount,
                icon: Icons.event_available_rounded,
                color: ProfileTheme.rose,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),

      // ------------------------------------------------ badges
      SectionHeader(
        title: 'Profile Badges',
        subtitle: '${badges.length} unlocked',
        actionLabel: 'See all',
        accent: ProfileTheme.primary,
        onAction: () => _push(const ProfileBadgesScreen()),
      ),
      const SizedBox(height: 12),
      FadeSlideIn(
        delay: const Duration(milliseconds: 180),
        child: badges.isEmpty
            ? _emptyCard(
                Icons.workspace_premium_outlined,
                'No badges yet',
                'Complete tasks to unlock your first badge.',
              )
            : SizedBox(
                height: 128,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: badges.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) => SizedBox(
                    width: 132,
                    child: BadgeTile(badge: badges[index], compact: true),
                  ),
                ),
              ),
      ),
      const SizedBox(height: 22),

      // ------------------------------------------------ tasks
      if (provider.tasks != null) ...[
        SectionHeader(
          title: 'Social & Tasks',
          subtitle:
              '${provider.tasks!.completedCount}/${provider.tasks!.totalCount} completed',
          actionLabel: 'View all',
          accent: ProfileTheme.primary,
          onAction: () => _push(const SocialTasksScreen()),
        ),
        const SizedBox(height: 12),
        FadeSlideIn(
          delay: const Duration(milliseconds: 220),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ProfileTheme.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.task_alt_rounded,
                        color: ProfileTheme.green, size: 18),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        '${provider.tasks!.earnedPoints} points earned from tasks',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AnimatedProgressBar(
                  value: provider.tasks!.totalCount == 0
                      ? 0
                      : provider.tasks!.completedCount /
                          provider.tasks!.totalCount,
                  height: 9,
                  colors: const [ProfileTheme.green, ProfileTheme.cyan],
                ),
                const SizedBox(height: 14),
                ...provider.tasks!.tasks.take(2).map(
                      (task) => TaskTile(
                        task: task,
                        onComplete: () async {
                          final message = await provider.completeTask(task.code);
                          if (message != null && mounted) _toast(message);
                        },
                      ),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
      ],

      // ------------------------------------------------ invite
      SectionHeader(
        title: 'Invite Friends',
        subtitle: 'Refer a friend and earn rewards',
        accent: ProfileTheme.primary,
        onAction: () => _push(const InviteFriendsScreen()),
        actionLabel: 'Open',
      ),
      const SizedBox(height: 12),
      FadeSlideIn(
        delay: const Duration(milliseconds: 260),
        child: InviteSummaryCard(
          user: user,
          onTap: () => _push(const InviteFriendsScreen()),
        ),
      ),
      const SizedBox(height: 22),

      // ------------------------------------------------ menu
      const SectionHeader(title: 'Account', accent: ProfileTheme.primary),
      const SizedBox(height: 12),
      SettingsActionTile(
        title: 'My Fandoms',
        value: '${stats.fandomCount} selected',
        icon: Icons.auto_awesome_rounded,
        color: ProfileTheme.tertiary,
        onTap: () => _push(const MyFandomsScreen()),
      ),
      SettingsActionTile(
        title: 'Public Badges',
        value: '${badges.length} unlocked',
        icon: Icons.workspace_premium_rounded,
        color: ProfileTheme.amber,
        onTap: () => _push(const ProfileBadgesScreen()),
      ),
      SettingsActionTile(
        title: 'Social & Tasks',
        value: '${stats.completedTasks}/${stats.totalTasks}',
        icon: Icons.task_alt_rounded,
        color: ProfileTheme.green,
        onTap: () => _push(const SocialTasksScreen()),
      ),
      SettingsActionTile(
        title: 'Invite Friends',
        value: '${user?.inviteCount ?? 0} invited',
        icon: Icons.group_add_rounded,
        color: ProfileTheme.cyan,
        onTap: () => _push(const InviteFriendsScreen()),
      ),
      SettingsActionTile(
        title: 'Notifications',
        icon: Icons.notifications_none_rounded,
        color: ProfileTheme.rose,
        onTap: () => _push(const NotificationsScreen()),
      ),
      SettingsActionTile(
        title: 'Settings',
        icon: Icons.settings_outlined,
        color: ProfileTheme.textSecondary,
        onTap: () => _push(const SettingsScreen()),
      ),
      const SizedBox(height: 8),
      PressScale(
        onTap: _handleLogout,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: ProfileTheme.rose.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ProfileTheme.rose.withValues(alpha: 0.35),
            ),
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
      const SizedBox(height: 10),
      Center(
        child: Text(
          'FANDOM VERSE · Pocket Edition',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.28),
            fontSize: 11,
          ),
        ),
      ),
    ];
  }

  void _toast(String message) {
    showInfoAlert(context, message, title: 'Fandom Verse');
  }

  Widget _headerChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(IconData icon, String title, String message) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ProfileTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Icon(icon, color: ProfileTheme.textMuted, size: 26),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    color: ProfileTheme.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar with a slowly rotating gradient ring (a small, cheap animation that
/// makes the profile header feel alive).
class _AnimatedAvatar extends StatefulWidget {
  const _AnimatedAvatar({required this.path, required this.name});

  final String path;
  final String name;

  @override
  State<_AnimatedAvatar> createState() => _AnimatedAvatarState();
}

class _AnimatedAvatarState extends State<_AnimatedAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            startAngle: 0,
            endAngle: 6.2832,
            transform: GradientRotation(_controller.value * 6.2832),
            colors: const [
              Color(0xFF22D3EE),
              Color(0xFF3B82F6),
              Color(0xFF8B5CF6),
              Color(0xFF22D3EE),
            ],
          ),
        ),
        child: child,
      ),
      child: AppAvatar(
        path: widget.path,
        name: widget.name,
        radius: 38,
        showRing: false,
        ringColor: ProfileTheme.primary,
      ),
    );
  }
}
