import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/content_provider.dart';
import '../models/content_models.dart';
import '../theme/content_theme.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/app_alert.dart';
import '../widgets/content_widgets.dart';
import 'news_details_screen.dart';
import 'video_player_screen.dart';

/// MEMBER 2 - Recently viewed + offline content (SQLite backed).
///
/// SRS: "Offline Bookmarking - Users can save articles, fan stories, and media
/// for offline reading and viewing."
class RecentContentScreen extends StatefulWidget {
  const RecentContentScreen({super.key, this.showOfflineFirst = false});

  final bool showOfflineFirst;

  @override
  State<RecentContentScreen> createState() => _RecentContentScreenState();
}

class _RecentContentScreenState extends State<RecentContentScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.showOfflineFirst ? 1 : 0,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ContentProvider>();
      provider.loadRecent();
      provider.loadOffline();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _open(ContentItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NewsDetailsScreen(item: item)),
    );
  }

  Future<void> _refresh() async {
    final provider = context.read<ContentProvider>();
    await provider.loadRecent();
    await provider.loadOffline();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContentProvider>();
    final recent = provider.recent;
    final offline = provider.offline;

    return ContentScaffold(
      title: 'Your Library',
      subtitle: 'Recent & offline content in SQLite',
      bottomBar: Container(
        color: ContentTheme.card,
        child: TabBar(
          controller: _tabs,
          indicatorColor: ContentTheme.primary,
          labelColor: Colors.white,
          unselectedLabelColor: ContentTheme.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            Tab(text: 'Recent (${recent.recent.length})'),
            Tab(text: 'Offline (${offline.items})'),
          ],
        ),
      ),
      child: TabBarView(
        controller: _tabs,
        children: [
          _buildRecent(provider),
          _buildOffline(provider),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // recent
  // ------------------------------------------------------------------
  Widget _buildRecent(ContentProvider provider) {
    final items = provider.recent.recent;

    if (provider.loadingRecent && items.isEmpty) {
      return const ContentLoadingList(count: 4, imageHeight: 84);
    }

    return RefreshIndicator(
      color: ContentTheme.primary,
      onRefresh: _refresh,
      child: items.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(20),
              children: const [
                SizedBox(height: 60),
                EmptyContentState(
                  title: 'Nothing viewed yet',
                  message:
                      'Open a news story, gallery, video or podcast and it will show up here for quick access.',
                  icon: Icons.history_rounded,
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
              children: [
                _summaryCard(
                  icon: Icons.history_rounded,
                  color: ContentTheme.secondary,
                  title: '${items.length} recently viewed',
                  message: '${provider.recent.offlineCount} saved for offline use',
                ),
                const SizedBox(height: 16),
                ...List.generate(items.length, (index) {
                  final item = items[index];
                  return FadeSlideIn(
                    delay: Duration(milliseconds: 45 * index),
                    child: ContentRowTile(
                      item: item,
                      onTap: () => _open(item),
                      trailing: PressScale(
                        onTap: () => provider.toggleOffline(item),
                        child: Icon(
                          item.isOffline
                              ? Icons.download_done_rounded
                              : Icons.download_rounded,
                          color: item.isOffline
                              ? ContentTheme.primary
                              : ContentTheme.textMuted,
                          size: 20,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }

  // ------------------------------------------------------------------
  // offline
  // ------------------------------------------------------------------
  Widget _buildOffline(ContentProvider provider) {
    final bundle = provider.offline;
    final items = bundle.offline;

    if (provider.loadingRecent && items.isEmpty) {
      return const ContentLoadingList(count: 3, imageHeight: 84);
    }

    return RefreshIndicator(
      color: ContentTheme.primary,
      onRefresh: _refresh,
      child: items.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(20),
              children: const [
                SizedBox(height: 60),
                EmptyContentState(
                  title: 'No offline content',
                  message:
                      'Tap the download icon on any article, gallery, video or podcast to keep it available offline.',
                  icon: Icons.cloud_download_rounded,
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
              children: [
                _storageCard(bundle.items, bundle.sizeMb),
                const SizedBox(height: 16),
                ...List.generate(items.length, (index) {
                  final item = items[index];
                  return FadeSlideIn(
                    delay: Duration(milliseconds: 45 * index),
                    child: ContentRowTile(
                      item: item,
                      onTap: () => item.contentType == 'video'
                          ? Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => VideoPlayerScreen(item: item),
                              ),
                            )
                          : _open(item),
                      trailing: PressScale(
                        onTap: () async {
                          final removed = await provider.toggleOffline(item);
                          if (removed && mounted) {
                            await showInfoAlert(
                              context,
                              'Removed from offline content',
                              title: 'Offline',
                              accent: ContentTheme.primary,
                            );
                          }
                        },
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: ContentTheme.textMuted,
                          size: 20,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
  }) {
    return FadeSlideIn(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ContentTheme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.22),
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
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: const TextStyle(
                      color: ContentTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _storageCard(int items, double sizeMb) {
    // Offline storage meter (purely a local estimate of cached media).
    const capacityMb = 512.0;
    final used = (sizeMb / capacityMb).clamp(0.0, 1.0);

    return FadeSlideIn(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ContentTheme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sd_storage_rounded,
                    color: ContentTheme.primary, size: 18),
                const SizedBox(width: 9),
                const Expanded(
                  child: Text(
                    'Offline storage',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${sizeMb.toStringAsFixed(1)} MB · $items items',
                  style: const TextStyle(
                    color: ContentTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedProgressBar(
              value: used == 0 ? 0.02 : used,
              height: 9,
              colors: const [ContentTheme.primary, ContentTheme.secondary],
            ),
            const SizedBox(height: 8),
            Text(
              'Cached in the local SQLite store - available without a connection.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
