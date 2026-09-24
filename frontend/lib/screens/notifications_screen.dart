import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/community_models.dart';
import '../providers/community_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/community_chips.dart';
import '../widgets/community_scaffold.dart';
import 'post_details_screen.dart';

/// MEMBER 3 - Search & Community
/// Notifications screen: new follower, likes, comments and bookmarks,
/// with unread filter, mark-all-read and swipe-to-delete.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityProvider>().loadNotifications();
    });
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'follow':
        return Icons.person_add_alt_1_rounded;
      case 'like':
        return Icons.favorite_rounded;
      case 'comment':
        return Icons.mode_comment_rounded;
      case 'bookmark':
        return Icons.bookmark_rounded;
      default:
        return Icons.campaign_rounded;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'follow':
        return AppTheme.accentCyan;
      case 'like':
        return AppTheme.secondaryColor;
      case 'comment':
        return AppTheme.primaryColor;
      case 'bookmark':
        return AppTheme.successColor;
      default:
        return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CommunityProvider>();
    final items = _filter == 'unread'
        ? provider.notifications.where((n) => !n.isRead).toList()
        : provider.notifications;

    return CommunityScaffold(
      title: 'Notifications',
      subtitle: provider.unreadCount > 0
          ? '${provider.unreadCount} unread'
          : 'You are all caught up',
      actions: [
        IconButton(
          tooltip: 'Mark all as read',
          icon: const Icon(Icons.done_all_rounded, color: Colors.white),
          onPressed: () => context.read<CommunityProvider>().markAllRead(),
        ),
      ],
      child: Column(
        children: [
          // --------------------------- filter ---------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                CommunityFilterChip(
                  label: 'All',
                  selected: _filter == 'all',
                  onTap: () => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 8),
                CommunityFilterChip(
                  label: 'Unread (${provider.unreadCount})',
                  selected: _filter == 'unread',
                  onTap: () => setState(() => _filter = 'unread'),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: AppTheme.textMuted, size: 20),
                  onPressed: () =>
                      context.read<CommunityProvider>().loadNotifications(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ---------------------------- list ----------------------------
          Expanded(
            child: provider.loading && provider.notifications.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.secondaryColor,
                    ),
                  )
                : items.isEmpty
                    ? const CommunityEmptyState(
                        icon: Icons.notifications_off_outlined,
                        title: 'No notifications',
                        message:
                            'When someone follows you, likes your post or\ncomments, it will show up here.',
                      )
                    : RefreshIndicator(
                        color: AppTheme.secondaryColor,
                        onRefresh: () =>
                            context.read<CommunityProvider>().loadNotifications(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final notification = items[index];
                            return Dismissible(
                              key: ValueKey(notification.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorColor.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.delete_rounded,
                                    color: Colors.white),
                              ),
                              onDismissed: (_) => context
                                  .read<CommunityProvider>()
                                  .removeNotification(notification),
                              child: _NotificationTile(
                                notification: notification,
                                icon: _iconFor(notification.type),
                                color: _colorFor(notification.type),
                                onTap: () => _open(notification),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _open(AppNotification notification) {
    context.read<CommunityProvider>().markRead(notification);

    if (notification.referenceId != null && notification.referenceId! > 0) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PostDetailsScreen(postId: notification.referenceId!),
        ),
      );
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unread
              ? AppTheme.primaryColor.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 19),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.message,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight:
                              unread ? FontWeight.w600 : FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.createdAgo,
                        style: GoogleFonts.inter(
                          color: AppTheme.textMuted,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (unread)
                  Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: AppTheme.secondaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
