import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/content_models.dart';
import '../providers/content_provider.dart';
import '../theme/content_theme.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/app_image.dart';
import '../widgets/content_widgets.dart';
import 'fandom_hub_screen.dart';
import 'gallery_screen.dart';
import 'news_list_screen.dart';
import 'podcasts_screen.dart';
import 'recent_content_screen.dart';

/// MEMBER 2 - Discover.
///
/// The mixed feed of the multimedia hub: spotlight story, trending content,
/// latest updates, gallery collections and recently viewed items. It is also
/// the tab the bottom navigation opens for "Explore".
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ContentProvider>();
      provider.loadDiscover();
      provider.loadRecent();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContentProvider>();
    final discover = provider.discover;

    final body = RefreshIndicator(
      onRefresh: () async {
        await provider.loadDiscover();
        await provider.loadRecent();
      },
      color: ContentTheme.primary,
      backgroundColor: ContentTheme.card,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ------------------------------------------------ header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeSlideIn(child: _buildTopBar()),
                  const SizedBox(height: 20),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 60),
                    child: _buildSearchBar(provider),
                  ),
                  const SizedBox(height: 18),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 90),
                    child: SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          AnimatedPill(
                            label: 'News',
                            icon: Icons.newspaper_rounded,
                            color: ContentTheme.amber,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const NewsListScreen(title: 'News'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedPill(
                            label: 'Gallery',
                            icon: Icons.photo_library_rounded,
                            color: ContentTheme.rose,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const GalleryScreen(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedPill(
                            label: 'Videos',
                            icon: Icons.play_circle_rounded,
                            color: ContentTheme.violet,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const VideoHubScreen(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedPill(
                            label: 'Podcasts',
                            icon: Icons.podcasts_rounded,
                            color: ContentTheme.primary,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const PodcastsScreen(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedPill(
                            label: 'Offline',
                            icon: Icons.download_done_rounded,
                            color: ContentTheme.secondary,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RecentContentScreen(showOfflineFirst: true),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
              ),
            ),
          ),

          // ------------------------------------------------ search results
          if (_query.trim().isNotEmpty)
            ..._buildSearchResults(provider, discover)
          else ...[
            // ---------------------------------- spotlight
            if (discover.spotlight != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                  child: FadeSlideIn(
                    delay: const Duration(milliseconds: 120),
                    child: _SpotlightCard(
                      item: discover.spotlight!,
                      onTap: () => openContentItem(context, discover.spotlight!),
                    ),
                  ),
                ),
              ),

            // ---------------------------------- trending grid
            if (discover.trending.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 26, 18, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        title: 'Trending Now',
                        subtitle: 'What the community is into',
                        accent: ContentTheme.rose,
                      ),
                      const SizedBox(height: 13),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 13,
                          mainAxisSpacing: 13,
                          childAspectRatio: 0.80,
                        ),
                        itemCount: discover.trending.length > 4
                            ? 4
                            : discover.trending.length,
                        itemBuilder: (context, index) => FadeSlideIn(
                          delay: Duration(milliseconds: 60 * index),
                          child: _TrendingMiniCard(
                            item: discover.trending[index],
                            onTap: () =>
                                openContentItem(context, discover.trending[index]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ---------------------------------- collections
            if (discover.collections.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 26, 18, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: 'Gallery Collections',
                        subtitle: 'Photo sets from the hub',
                        accent: ContentTheme.secondary,
                        actionLabel: 'See All',
                        onAction: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const GalleryScreen()),
                        ),
                      ),
                      const SizedBox(height: 13),
                      SizedBox(
                        height: 172,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: discover.collections.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (context, index) => FadeSlideIn(
                            delay: Duration(milliseconds: 55 * index),
                            offsetX: 30,
                            offsetY: 0,
                            child: SizedBox(
                              width: 172,
                              child: GalleryTile(
                                imageUrl: discover.collections[index].artwork,
                                caption: discover.collections[index].title,
                                height: 172,
                                onTap: () => openContentItem(
                                    context, discover.collections[index]),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ---------------------------------- latest list
            if (discover.latest.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 26, 18, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: 'Latest Updates',
                        subtitle: 'Fresh from every fandom',
                        accent: ContentTheme.primary,
                        actionLabel: 'See All',
                        onAction: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NewsListScreen(title: 'Latest'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 13),
                      ...discover.latest.take(6).map(
                            (item) => FadeSlideIn(
                              delay: const Duration(milliseconds: 45),
                              child: ContentRowTile(
                                item: item,
                                onTap: () => openContentItem(context, item),
                                trailing: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: ContentTheme.textMuted,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),

            // ---------------------------------- recently viewed
            if (provider.recent.recent.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: 'Continue',
                        subtitle: 'Jump back into what you were reading',
                        accent: ContentTheme.amber,
                        actionLabel: 'History',
                        onAction: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RecentContentScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 13),
                      SizedBox(
                        height: 96,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: provider.recent.recent.length > 6
                              ? 6
                              : provider.recent.recent.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (context, index) =>
                              _ContinueCard(item: provider.recent.recent[index]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (provider.loadingDiscover && discover.spotlight == null)
              const SliverPadding(
                padding: EdgeInsets.all(18),
                sliver: SliverToBoxAdapter(child: ContentLoadingList(count: 3)),
              ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );

    if (widget.embedded) {
      return Container(
        decoration: const BoxDecoration(gradient: ContentTheme.backgroundGradient),
        child: SafeArea(child: body),
      );
    }

    return ContentScaffold(
      title: 'Discover',
      subtitle: 'Explore the multimedia hub',
      child: body,
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Discover',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'News · Gallery · Video · Podcasts',
                style: TextStyle(
                  color: ContentTheme.textSecondary.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        PressScale(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FandomHubScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: ContentTheme.headerGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.explore_rounded, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(ContentProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: ContentTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: ContentTheme.textMuted, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Search news, galleries, videos...',
                hintStyle: TextStyle(color: ContentTheme.textMuted, fontSize: 13.5),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
              ),
              onSubmitted: (value) {
                setState(() => _query = value);
                provider.loadList(query: value, type: 'all');
              },
            ),
          ),
          if (_query.isNotEmpty)
            PressScale(
              onTap: () {
                _searchController.clear();
                setState(() => _query = '');
              },
              child: const Icon(Icons.close_rounded,
                  color: ContentTheme.textMuted, size: 19),
            )
          else
            PressScale(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RecentContentScreen()),
              ),
              child: const Icon(Icons.history_rounded,
                  color: ContentTheme.textMuted, size: 19),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildSearchResults(ContentProvider provider, DiscoverBundle discover) {
    final items = provider.items;

    if (provider.loadingList && items.isEmpty) {
      return const [
        SliverPadding(
          padding: EdgeInsets.all(18),
          sliver: SliverToBoxAdapter(child: ContentLoadingList(count: 2)),
        ),
      ];
    }

    if (items.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyContentState(
            title: 'No results for "$_query"',
            message: 'Try another keyword, or browse the fandom hubs instead.',
            icon: Icons.search_off_rounded,
            actionLabel: 'Open Fandom Hub',
            onAction: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FandomHubScreen()),
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: FadeSlideIn(
                delay: Duration(milliseconds: 40 * (index % 8)),
                child: ContentRowTile(
                  item: items[index],
                  onTap: () => openContentItem(context, items[index]),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: ContentTheme.textMuted, size: 20),
                ),
              ),
            ),
            childCount: items.length,
          ),
        ),
      ),
    ];
  }
}

/// Video hub list (all video clips).
class VideoHubScreen extends StatefulWidget {
  const VideoHubScreen({super.key, this.fandom = 'all'});

  final String fandom;

  @override
  State<VideoHubScreen> createState() => _VideoHubScreenState();
}

class _VideoHubScreenState extends State<VideoHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContentProvider>().loadList(type: 'video', fandom: widget.fandom);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContentProvider>();
    final items = provider.items;

    return ContentScaffold(
      title: 'Video Player',
      subtitle: 'Trailers, breakdowns & community clips',
      child: RefreshIndicator(
        onRefresh: () => provider.loadList(type: 'video', fandom: widget.fandom),
        color: ContentTheme.primary,
        backgroundColor: ContentTheme.card,
        child: items.isEmpty && provider.loadingList
            ? const Padding(
                padding: EdgeInsets.all(18),
                child: ContentLoadingList(count: 3, imageHeight: 130),
              )
            : items.isEmpty
                ? ListView(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                      EmptyContentState(
                        title: 'No clips yet',
                        message: provider.errorMessage ?? 'Pull down to refresh.',
                        icon: Icons.play_circle_rounded,
                        actionLabel: 'Retry',
                        onAction: () =>
                            provider.loadList(type: 'video', fandom: widget.fandom),
                      ),
                    ],
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 13,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) => FadeSlideIn(
                      delay: Duration(milliseconds: 55 * (index % 8)),
                      child: VideoStillCard(
                        item: items[index],
                        width: double.infinity,
                        onTap: () => openContentItem(context, items[index]),
                      ),
                    ),
                  ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// local widgets
// ---------------------------------------------------------------------------
class _SpotlightCard extends StatelessWidget {
  final ContentItem item;
  final VoidCallback onTap;

  const _SpotlightCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = ContentTheme.fandomColor(item.fandom);

    return PressScale(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: 268,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: 'content-hero-${item.id}',
                child: AppImage(
                  path: item.artwork,
                  fallbackColors: [color, ContentTheme.primaryDark],
                  fallbackIcon: ContentTheme.fandomIcon(item.fandom),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.9),
                    ],
                    stops: const [0.32, 1],
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: ContentTheme.rose,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.local_fire_department_rounded,
                          size: 12, color: Colors.white),
                      SizedBox(width: 5),
                      Text(
                        'SPOTLIGHT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        TypeBadge(type: item.contentType, solid: false),
                        const SizedBox(width: 8),
                        FandomChip(fandom: item.fandom),
                      ],
                    ),
                    const SizedBox(height: 11),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                      ),
                    ),
                    if (item.summary.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                ContentTheme.contentTypeIcon(item.contentType),
                                size: 15,
                                color: ContentTheme.background,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                item.contentType == 'video' ? 'Watch now' : 'Read more',
                                style: const TextStyle(
                                  color: ContentTheme.background,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item.publishedAgo,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
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

class _TrendingMiniCard extends StatelessWidget {
  final ContentItem item;
  final VoidCallback onTap;

  const _TrendingMiniCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = ContentTheme.fandomColor(item.fandom);

    return PressScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: ContentTheme.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AppImage(
                  path: item.artwork,
                  height: 104,
                  width: double.infinity,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  fallbackColors: [color, ContentTheme.primaryDark],
                  fallbackIcon: ContentTheme.fandomIcon(item.fandom),
                ),
                Positioned(
                  top: 9,
                  left: 9,
                  child: TypeBadge(type: item.contentType, solid: false, fontSize: 8.5),
                ),
                if (item.durationLabel.isNotEmpty)
                  Positioned(
                    bottom: 8,
                    right: 9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.durationLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        height: 1.28,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.visibility_rounded,
                            size: 11, color: color),
                        const SizedBox(width: 4),
                        Text(
                          ContentTheme.compactCount(item.viewsCount),
                          style: const TextStyle(
                            color: ContentTheme.textMuted,
                            fontSize: 10.5,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          item.publishedAgo,
                          style: const TextStyle(
                            color: ContentTheme.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final ContentItem item;

  const _ContinueCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: () => openContentItem(context, item),
      child: SizedBox(
        width: 158,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AppImage(
                path: item.artwork,
                fallbackIcon: ContentTheme.contentTypeIcon(item.contentType),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.88),
                    ],
                    stops: const [0.35, 1],
                  ),
                ),
              ),
              Positioned(
                left: 9,
                right: 9,
                bottom: 9,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 7),
                    AnimatedProgressBar(
                      value: item.progress,
                      height: 3,
                      colors: const [ContentTheme.primary, ContentTheme.secondary],
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
