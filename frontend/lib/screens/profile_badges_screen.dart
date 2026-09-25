import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/profile_models.dart';
import '../providers/profile_provider.dart';
import '../theme/profile_theme.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/profile_widgets.dart';

/// MEMBER 1 - Public Badges.
///
/// Every badge in the catalogue plus the ones this fan has already unlocked.
class ProfileBadgesScreen extends StatefulWidget {
  const ProfileBadgesScreen({super.key});

  @override
  State<ProfileBadgesScreen> createState() => _ProfileBadgesScreenState();
}

class _ProfileBadgesScreenState extends State<ProfileBadgesScreen> {
  String _category = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProfileProvider>().loadBadges();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final bundle = provider.badges;

    final badges = bundle?.badges ?? const <ProfileBadge>[];
    final categories = <String>[
      'All',
      ...{for (final badge in badges) badge.category},
    ];
    final visible = _category == 'All'
        ? badges
        : badges.where((b) => b.category == _category).toList();

    return ProfileScaffold(
      title: 'Public Badges',
      subtitle: bundle == null
          ? 'Loading your achievements'
          : '${bundle.earnedCount} of ${bundle.totalCount} unlocked',
      child: provider.loading && bundle == null
          ? const Center(
              child: CircularProgressIndicator(color: ProfileTheme.amber),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
              children: [
                // ------------------------------------------- progress hero
                FadeSlideIn(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: ProfileTheme.pointsGradient,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: ProfileTheme.amber.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 9),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.workspace_premium_rounded,
                                  color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${bundle?.earnedCount ?? 0} badges unlocked',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Keep exploring to unlock the rest',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${bundle?.progress ?? 0}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        AnimatedProgressBar(
                          value: (bundle?.progress ?? 0) / 100,
                          height: 8,
                          colors: const [Colors.white, Color(0xFFFFE4E6)],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ------------------------------------------- filters
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final count = category == 'All'
                          ? badges.length
                          : badges.where((b) => b.category == category).length;
                      return AnimatedPill(
                        label: category,
                        count: count,
                        selected: _category == category,
                        color: ProfileTheme.amber,
                        onTap: () => setState(() => _category = category),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),

                // ------------------------------------------- grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.86,
                  ),
                  itemCount: visible.length,
                  itemBuilder: (context, index) => FadeSlideIn(
                    delay: Duration(milliseconds: 45 * index),
                    child: BadgeTile(badge: visible[index]),
                  ),
                ),
              ],
            ),
    );
  }
}
