import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/profile_provider.dart';
import '../theme/profile_theme.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/app_alert.dart';
import '../widgets/profile_widgets.dart';
import 'invite_friends_screen.dart';
import 'my_fandoms_screen.dart';
import 'profile_badges_screen.dart';

/// MEMBER 1 - Social & Tasks.
///
/// Daily fan tasks (invite, complete profile, pick fandoms, read news, watch a
/// clip, join a discussion, bookmark media, follow fans) with progress and the
/// fan points earned from them.
class SocialTasksScreen extends StatefulWidget {
  const SocialTasksScreen({super.key});

  @override
  State<SocialTasksScreen> createState() => _SocialTasksScreenState();
}

class _SocialTasksScreenState extends State<SocialTasksScreen> {
  String? _busyCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProfileProvider>().loadTasks();
    });
  }

  Future<void> _complete(String code) async {
    setState(() => _busyCode = code);
    final provider = context.read<ProfileProvider>();
    final message = await provider.completeTask(code);

    if (!mounted) return;
    setState(() => _busyCode = null);

    if (message != null) {
      await showSuccessAlert(context, message, title: 'Task Complete');
    } else {
      await showErrorAlert(
        context,
        provider.errorMessage ?? 'Could not complete',
        title: 'Could Not Complete',
        accent: ProfileTheme.rose,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final bundle = provider.tasks;

    return ProfileScaffold(
      title: 'Social & Tasks',
      subtitle: bundle == null
          ? 'Earn fan points by exploring'
          : '${bundle.completedCount}/${bundle.totalCount} completed',
      child: provider.loading && bundle == null
          ? const Center(
              child: CircularProgressIndicator(color: ProfileTheme.green),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
              children: [
                // ------------------------------------------- points hero
                FadeSlideIn(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: ProfileTheme.headerGradient,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: ProfileTheme.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 9),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(Icons.emoji_events_rounded,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Fan points',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11.5,
                                ),
                              ),
                              AnimatedCounter(
                                value: bundle?.points ?? 0,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${bundle?.earnedPoints ?? 0} earned from tasks',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${bundle?.completedCount ?? 0}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'completed',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ------------------------------------------- shortcuts
                const SectionHeader(
                  title: 'Quick actions',
                  accent: ProfileTheme.cyan,
                ),
                const SizedBox(height: 10),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 60),
                  child: Row(
                    children: [
                      Expanded(
                        child: _shortcut(
                          'Invite',
                          Icons.group_add_rounded,
                          ProfileTheme.cyan,
                          () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const InviteFriendsScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _shortcut(
                          'Fandoms',
                          Icons.auto_awesome_rounded,
                          ProfileTheme.tertiary,
                          () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MyFandomsScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _shortcut(
                          'Badges',
                          Icons.workspace_premium_rounded,
                          ProfileTheme.amber,
                          () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ProfileBadgesScreen(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // ------------------------------------------- task list
                const SectionHeader(
                  title: 'Your tasks',
                  subtitle: 'Complete a task to claim the points',
                  accent: ProfileTheme.green,
                ),
                const SizedBox(height: 12),
                if (bundle == null || bundle.tasks.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: ProfileTheme.card,
                      borderRadius: BorderRadius.circular(18),
                      border:
                          Border.all(color: Colors.white.withValues(alpha: 0.07)),
                    ),
                    child: const Text(
                      'No tasks available right now.',
                      style: TextStyle(color: ProfileTheme.textSecondary),
                    ),
                  )
                else
                  ...List.generate(bundle.tasks.length, (index) {
                    final task = bundle.tasks[index];
                    final actionable = !task.isCompleted &&
                        task.action == 'in_app';
                    return FadeSlideIn(
                      delay: Duration(milliseconds: 50 * index),
                      child: TaskTile(
                        task: task,
                        busy: _busyCode == task.code,
                        onComplete:
                            actionable ? () => _complete(task.code) : null,
                      ),
                    );
                  }),
              ],
            ),
    );
  }

  Widget _shortcut(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: ProfileTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 7),
            Text(
              label,
              style: const TextStyle(
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
