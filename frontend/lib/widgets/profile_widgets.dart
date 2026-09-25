import 'package:flutter/material.dart';

import '../models/profile_models.dart';
import '../theme/profile_theme.dart';
import 'animated_widgets.dart';
import 'app_image.dart';

/// MEMBER 1 - Profile, Fandom Selection & Home
/// Reusable widgets for the profile, badges, tasks, invite and settings
/// screens.

// ---------------------------------------------------------------------------
// scaffold
// ---------------------------------------------------------------------------
class ProfileScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;
  final Widget? bottomBar;
  final bool showBackButton;

  const ProfileScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.bottomBar,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfileTheme.background,
      bottomNavigationBar: bottomBar,
      body: Container(
        decoration: const BoxDecoration(gradient: ProfileTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
                child: Row(
                  children: [
                    if (showBackButton)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        onPressed: () => Navigator.of(context).maybePop(),
                      )
                    else
                      const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              style: const TextStyle(
                                color: ProfileTheme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    ...actions,
                  ],
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// primary gradient button (with press animation + busy state)
// ---------------------------------------------------------------------------
class GradientActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool busy;
  final bool enabled;
  final LinearGradient gradient;
  final double height;

  const GradientActionButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.busy = false,
    this.enabled = true,
    this.gradient = ProfileTheme.buttonGradient,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    final active = enabled && !busy && onPressed != null;

    return PressScale(
      onTap: active ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: height,
        decoration: BoxDecoration(
          gradient: active ? gradient : null,
          color: active ? null : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: ProfileTheme.primary.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 19,
                        color: active ? Colors.white : ProfileTheme.textMuted,
                      ),
                      const SizedBox(width: 9),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        color: active ? Colors.white : ProfileTheme.textMuted,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// stat tile
// ---------------------------------------------------------------------------
class StatTile extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = ProfileTheme.primary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: ProfileTheme.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(height: 9),
            AnimatedCounter(
              value: value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: ProfileTheme.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wide stat row (label on the left, animated number on the right).
class StatRowTile extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const StatRowTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = ProfileTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: ProfileTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: ProfileTheme.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          AnimatedCounter(
            value: value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// badge tile (Public Badges)
// ---------------------------------------------------------------------------
class BadgeTile extends StatelessWidget {
  final ProfileBadge badge;
  final bool compact;

  const BadgeTile({super.key, required this.badge, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final color = badge.displayColor;
    final locked = !badge.isEarned;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: locked ? ProfileTheme.card.withValues(alpha: 0.6) : ProfileTheme.card,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: locked
              ? Colors.white.withValues(alpha: 0.05)
              : color.withValues(alpha: 0.45),
          width: locked ? 1 : 1.4,
        ),
        boxShadow: locked
            ? null
            : [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(compact ? 8 : 10),
                decoration: BoxDecoration(
                  gradient: locked ? null : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withValues(alpha: 0.55)],
                  ),
                  color: locked ? Colors.white.withValues(alpha: 0.05) : null,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  locked ? Icons.lock_rounded : ProfileTheme.icon(badge.icon),
                  size: compact ? 17 : 21,
                  color: locked ? ProfileTheme.textMuted : Colors.white,
                ),
              ),
              const Spacer(),
              if (!locked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: ProfileTheme.green.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 11, color: ProfileTheme.green),
                      SizedBox(width: 4),
                      Text(
                        'EARNED',
                        style: TextStyle(
                          color: ProfileTheme.green,
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            badge.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: locked ? ProfileTheme.textSecondary : Colors.white,
              fontSize: compact ? 12.5 : 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 4),
            Text(
              badge.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ProfileTheme.textMuted,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
          if (!locked && badge.earnedAgo.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              badge.earnedAgo,
              style: TextStyle(
                color: color.withValues(alpha: 0.85),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// social task tile
// ---------------------------------------------------------------------------
class TaskTile extends StatelessWidget {
  final SocialTask task;
  final bool busy;
  final VoidCallback? onComplete;

  const TaskTile({super.key, required this.task, this.busy = false, this.onComplete});

  @override
  Widget build(BuildContext context) {
    final color = task.displayColor;
    final done = task.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ProfileTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: done
              ? ProfileTheme.green.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  done ? Icons.check_rounded : ProfileTheme.icon(task.icon),
                  size: 18,
                  color: done ? ProfileTheme.green : color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        decoration: done ? TextDecoration.lineThrough : null,
                        decorationColor: ProfileTheme.textMuted,
                      ),
                    ),
                    if (task.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          task.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ProfileTheme.textSecondary,
                            fontSize: 11.5,
                            height: 1.3,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  gradient: ProfileTheme.pointsGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '+${task.rewardPoints}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AnimatedProgressBar(
                  value: task.percentage / 100,
                  height: 7,
                  colors: done
                      ? const [ProfileTheme.green, ProfileTheme.cyan]
                      : [color, color.withValues(alpha: 0.6)],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                task.progressLabel,
                style: TextStyle(
                  color: done ? ProfileTheme.green : ProfileTheme.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (!done) ...[
                const SizedBox(width: 10),
                PressScale(
                  onTap: busy ? null : onComplete,
                  pressedScale: 0.9,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withValues(alpha: 0.45)),
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Do it',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// fandom selection card (Fandom Selection + My Fandoms)
// ---------------------------------------------------------------------------
class FandomSelectCard extends StatelessWidget {
  final FandomOption fandom;
  final bool selected;
  final VoidCallback? onTap;

  const FandomSelectCard({
    super.key,
    required this.fandom,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = fandom.displayColor;

    return PressScale(
      onTap: onTap,
      pressedScale: 0.94,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.white.withValues(alpha: 0.08),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AppImage(
                path: fandom.imageUrl.isEmpty
                    ? ProfileTheme.fandomArtwork(fandom.name)
                    : fandom.imageUrl,
                fallbackColors: [color, ProfileTheme.primaryDark],
                fallbackIcon: ProfileTheme.fandomIcon(fandom.name),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: selected ? 0.15 : 0.3),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    stops: const [0.3, 1],
                  ),
                ),
              ),
              Positioned(
                top: 9,
                right: 9,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 260),
                  scale: selected ? 1 : 0.86,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: selected ? color : Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: selected ? 0.9 : 0.35),
                        width: 1.6,
                      ),
                    ),
                    child: Icon(
                      selected ? Icons.check_rounded : Icons.add_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 11,
                right: 11,
                bottom: 11,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      ProfileTheme.fandomIcon(fandom.name),
                      size: 19,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      fandom.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${ProfileTheme.compactCount(fandom.followersCount)} fans',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// settings tiles
// ---------------------------------------------------------------------------
class SettingsSwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const SettingsSwitchTile({
    super.key,
    required this.title,
    required this.icon,
    required this.value,
    this.subtitle,
    this.color = ProfileTheme.primary,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: ProfileTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: color,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 17, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: ProfileTheme.textPrimary,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                style: const TextStyle(color: ProfileTheme.textMuted, fontSize: 11),
              ),
      ),
    );
  }
}

class SettingsActionTile extends StatelessWidget {
  final String title;
  final String? value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final Widget? trailing;

  const SettingsActionTile({
    super.key,
    required this.title,
    required this.icon,
    this.value,
    this.color = ProfileTheme.primary,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      pressedScale: 0.98,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: ProfileTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: ProfileTheme.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: const TextStyle(color: ProfileTheme.textSecondary, fontSize: 12.5),
              ),
            const SizedBox(width: 6),
            trailing ??
                const Icon(Icons.chevron_right_rounded,
                    color: ProfileTheme.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Points / level card shown on the profile and dashboard headers.
class PointsCard extends StatelessWidget {
  final ProfileUser user;

  const PointsCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: ProfileTheme.pointsGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ProfileTheme.amber.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
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
                Row(
                  children: [
                    Text(
                      'Level ${user.level}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        '${user.points} pts',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AnimatedProgressBar(
                  value: user.levelProgress,
                  height: 6,
                  colors: const [Colors.white, Colors.white70],
                ),
                const SizedBox(height: 5),
                Text(
                  '${user.nextLevelPoints - user.points} points to level ${user.level + 1}',
                  style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// invite summary card (profile + dashboard + home)
// ---------------------------------------------------------------------------

/// "Refer a friend and earn rewards" card: shows the invite code, how many
/// friends joined and the points earned so far.
class InviteSummaryCard extends StatelessWidget {
  final ProfileUser? user;
  final VoidCallback? onTap;
  final int? inviteCount;
  final int? pointsEarned;
  final String? inviteCode;

  const InviteSummaryCard({
    super.key,
    this.user,
    this.onTap,
    this.inviteCount,
    this.pointsEarned,
    this.inviteCode,
  });

  @override
  Widget build(BuildContext context) {
    final code = inviteCode ?? user?.inviteCode ?? '——';
    final invited = inviteCount ?? user?.inviteCount ?? 0;
    final points = pointsEarned ?? invited * 50;

    return PressScale(
      onTap: onTap,
      pressedScale: 0.97,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: ProfileTheme.headerGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: ProfileTheme.primary.withValues(alpha: 0.3),
              blurRadius: 18,
              offset: const Offset(0, 8),
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
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.group_add_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Invite Friends',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Refer a friend and earn rewards',
                        style: TextStyle(color: Colors.white70, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white70),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _stat('$invited', 'Friends joined'),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.white.withValues(alpha: 0.22),
                ),
                const SizedBox(width: 14),
                _stat('$points', 'Points earned'),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.confirmation_number_outlined,
                          color: Colors.white, size: 13),
                      const SizedBox(width: 6),
                      Text(
                        code,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10.5),
        ),
      ],
    );
  }
}
