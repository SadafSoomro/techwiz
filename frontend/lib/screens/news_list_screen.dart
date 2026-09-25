import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/content_models.dart';
import '../providers/content_provider.dart';
import '../theme/content_theme.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/content_widgets.dart';
import 'fandom_hub_screen.dart';

/// MEMBER 2 - News List ("Latest Updates from your favorite series").
///
/// Supports fandom filtering and sorting, and is reused by the Discover screen
/// for the "Latest" rail.
class NewsListScreen extends StatefulWidget {
  final String fandom;
  final String title;

  const NewsListScreen({
    super.key,
    this.fandom = 'all',
    this.title = 'News',
  });

  @override
  State<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> {
  static const List<String> _fandoms = [
    'all',
    'Anime',
    'Gaming',
    'Movies & TV',
    'Comics',
    'Music',
    'Sports',
    'Sci-Fi',
  ];

  late String _fandom = widget.fandom;
  String _sort = 'latest';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await context.read<ContentProvider>().loadList(
          type: 'news',
          fandom: _fandom,
          sort: _sort,
          query: '',
        );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContentProvider>();
    final items = provider.items;

    return ContentScaffold(
      title: widget.title,
      subtitle: 'Latest Updates from your favorite series',
      actions: [
        IconButton(
          tooltip: 'Sort',
          icon: const Icon(Icons.sort_rounded, color: Colors.white),
          onPressed: _showSortSheet,
        ),
      ],
      child: RefreshIndicator(
        onRefresh: _load,
        color: ContentTheme.primary,
        backgroundColor: ContentTheme.card,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 0, 4),
                child: SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _fandoms.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final value = _fandoms[index];
                      return AnimatedPill(
                        label: value == 'all' ? 'All fandoms' : value,
                        icon: value == 'all'
                            ? Icons.apps_rounded
                            : ContentTheme.fandomIcon(value),
                        selected: _fandom == value,
                        color: value == 'all'
                            ? ContentTheme.primary
                            : ContentTheme.fandomColor(value),
                        onTap: () {
                          setState(() => _fandom = value);
                          _load();
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Row(
                  children: [
                    Text(
                      '${items.length} stories',
                      style: const TextStyle(
                        color: ContentTheme.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.tune_rounded,
                        size: 14, color: ContentTheme.textMuted),
                    const SizedBox(width: 5),
                    Text(
                      _sortLabel,
                      style: const TextStyle(
                        color: ContentTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (provider.loadingList && items.isEmpty)
              const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                sliver: SliverToBoxAdapter(child: ContentLoadingList(count: 3)),
              )
            else if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyContentState(
                  title: 'No stories found',
                  message: provider.errorMessage ??
                      'Try another fandom filter, or pull down to refresh.',
                  icon: Icons.newspaper_rounded,
                  actionLabel: 'Retry',
                  onAction: _load,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: FadeSlideIn(
                          delay: Duration(milliseconds: 55 * (index % 8)),
                          child: ContentCard(
                            item: item,
                            onTap: () => openContentItem(context, item),
                            onBookmark: () =>
                                context.read<ContentProvider>().toggleOffline(item),
                          ),
                        ),
                      );
                    },
                    childCount: items.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String get _sortLabel {
    switch (_sort) {
      case 'popular':
        return 'Most read';
      case 'liked':
        return 'Most liked';
      case 'oldest':
        return 'Oldest first';
      default:
        return 'Newest first';
    }
  }

  void _showSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: ContentTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sort news',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...[
              ('latest', 'Newest first', Icons.schedule_rounded),
              ('popular', 'Most read', Icons.local_fire_department_rounded),
              ('liked', 'Most liked', Icons.favorite_rounded),
              ('oldest', 'Oldest first', Icons.history_rounded),
            ].map(
              (option) => ListTile(
                leading: Icon(
                  option.$3,
                  color: _sort == option.$1
                      ? ContentTheme.primary
                      : ContentTheme.textSecondary,
                ),
                title: Text(
                  option.$2,
                  style: TextStyle(
                    color: _sort == option.$1
                        ? ContentTheme.primary
                        : Colors.white,
                    fontWeight: _sort == option.$1
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: _sort == option.$1
                    ? const Icon(Icons.check_rounded, color: ContentTheme.primary)
                    : null,
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() => _sort = option.$1);
                  _load();
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

/// Small helper so screens can push the news list for a specific fandom.
void openNewsFor(BuildContext context, String fandom) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => NewsListScreen(fandom: fandom, title: '$fandom News'),
    ),
  );
}

/// Convenience for building "see all" routes from sections.
List<ContentItem> takeFirst(List<ContentItem> items, int count) =>
    items.take(count).toList();
