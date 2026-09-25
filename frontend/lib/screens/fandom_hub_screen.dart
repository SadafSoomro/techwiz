import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/content_models.dart';
import '../providers/content_provider.dart';
import '../theme/content_theme.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/app_image.dart';
import '../widgets/content_widgets.dart';
import 'gallery_screen.dart';
import 'news_details_screen.dart';
import 'news_list_screen.dart';
import 'podcasts_screen.dart';
import 'video_player_screen.dart';

/// MEMBER 2 - opens the right screen for a content item based on its type.
/// Shared by every list, section and "related content" rail.
void openContentItem(BuildContext context, ContentItem item) {
  Widget screen;
  switch (item.contentType) {
    case 'video':
      screen = VideoPlayerScreen(item: item);
      break;
    case 'podcast':
      screen = PodcastsScreen(initialItem: item);
      break;
    case 'gallery':
      screen = GalleryViewerScreen(item: item);
      break;
    default:
      screen = NewsDetailsScreen(item: item);
  }

  Navigator.of(context).push(
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, _, _) => screen,
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

/// MEMBER 2 - Fandom Hub / Explore Fandoms.
///
/// Shows the trending fandoms carousel plus every fandom hub as a cover card.
/// Tapping a hub opens [HubContentScreen].
class FandomHubScreen extends StatefulWidget {
  const FandomHubScreen({super.key, this.embedded = false});

  /// When true the screen is rendered inside the bottom-nav shell (no back
  /// button, scrollable body only).
  final bool embedded;

  /// Opens the content page of one fandom hub (news, gallery, video,
  /// podcast, deep dive and the beginner glossary).
  static void openHub(BuildContext context, FandomHub hub) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HubContentScreen(hub: hub)),
    );
  }

  @override
  State<FandomHubScreen> createState() => _FandomHubScreenState();
}

class _FandomHubScreenState extends State<FandomHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ContentProvider>().loadHubs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContentProvider>();
    final bundle = provider.hubs;

    final body = RefreshIndicator(
      onRefresh: () => provider.loadHubs(),
      color: ContentTheme.primary,
      backgroundColor: ContentTheme.card,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeSlideIn(
                    child: _buildHeaderCard(bundle),
                  ),
                  const SizedBox(height: 24),
                  if (bundle.trending.isNotEmpty) ...[
                    const FadeSlideIn(
                      delay: Duration(milliseconds: 80),
                      child: SectionHeader(
                        title: 'Trending Fandoms',
                        subtitle: 'What everyone is reading this week',
                        accent: ContentTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 116,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: bundle.trending.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, index) => FadeSlideIn(
                          delay: Duration(milliseconds: 60 * index),
                          offsetX: 30,
                          offsetY: 0,
                          child: _TrendingChip(hub: bundle.trending[index]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                  ],
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 140),
                    child: SectionHeader(
                      title: 'Explore Fandoms',
                      subtitle: '${bundle.hubs.length} hubs · ${bundle.totalItems} stories',
                      accent: ContentTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
          if (provider.loadingHubs && bundle.hubs.isEmpty)
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              sliver: SliverToBoxAdapter(child: ContentLoadingList(count: 3)),
            )
          else if (bundle.hubs.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyContentState(
                title: 'No fandom hubs yet',
                message: provider.errorMessage ??
                    'Run "npm run seed:content" in the backend to load the demo content.',
                icon: Icons.explore_off_rounded,
                actionLabel: 'Retry',
                onAction: () => provider.loadHubs(),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 26),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.78,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => FadeSlideIn(
                    delay: Duration(milliseconds: 50 * index),
                    child: _HubCoverCard(hub: bundle.hubs[index]),
                  ),
                  childCount: bundle.hubs.length,
                ),
              ),
            ),
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
      title: 'Fandom Hub',
      subtitle: 'Explore Fandoms',
      child: body,
    );
  }

  Widget _buildHeaderCard(HubsBundle bundle) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: ContentTheme.headerGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: ContentTheme.primary.withValues(alpha: 0.32),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -22,
            bottom: -26,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 130,
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  PulseDot(color: Colors.white, size: 8),
                  SizedBox(width: 8),
                  Text(
                    'MULTIMEDIA HUB',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Every fandom.\nOne place.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'News, galleries, video clips and podcasts - filtered by the fandoms you love.',
                style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _MiniStat(
                    icon: Icons.dashboard_customize_rounded,
                    value: '${bundle.hubs.length}',
                    label: 'Hubs',
                  ),
                  const SizedBox(width: 10),
                  _MiniStat(
                    icon: Icons.article_rounded,
                    value: '${bundle.totalItems}',
                    label: 'Stories',
                  ),
                  const SizedBox(width: 10),
                  _MiniStat(
                    icon: Icons.visibility_rounded,
                    value: ContentTheme.compactCount(bundle.totalViews),
                    label: 'Views',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MiniStat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: Colors.white70),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 9.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// Trending pill (horizontal rail on the Explore Fandoms screen).
class _TrendingChip extends StatelessWidget {
  final FandomHub hub;

  const _TrendingChip({required this.hub});

  @override
  Widget build(BuildContext context) {
    final color = ContentTheme.fandomColor(hub.name);

    return PressScale(
      onTap: () => FandomHubScreen.openHub(context, hub),
      child: Container(
        width: 152,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ContentTheme.card,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.6)],
                ),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                ContentTheme.fandomIcon(hub.name),
                size: 16,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            Text(
              hub.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${ContentTheme.compactCount(hub.followersCount)} fans',
              style: const TextStyle(color: ContentTheme.textMuted, fontSize: 10.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// Big cover card used in the Explore Fandoms grid.
class _HubCoverCard extends StatelessWidget {
  final FandomHub hub;

  const _HubCoverCard({required this.hub});

  @override
  Widget build(BuildContext context) {
    final color = ContentTheme.fandomColor(hub.name);

    return PressScale(
      onTap: () => FandomHubScreen.openHub(context, hub),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AppImage(
              path: hub.imageUrl,
              fallbackColors: [color, ContentTheme.primaryDark],
              fallbackIcon: ContentTheme.fandomIcon(hub.name),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.18),
                    Colors.black.withValues(alpha: 0.88),
                  ],
                  stops: const [0.28, 1],
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  ContentTheme.fandomIcon(hub.name),
                  size: 15,
                  color: Colors.white,
                ),
              ),
            ),
            if (hub.isTrending)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: ContentTheme.rose.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'HOT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hub.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hub.tagline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10.5,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.article_rounded, size: 11, color: color),
                      const SizedBox(width: 4),
                      Text(
                        '${hub.itemsCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.visibility_rounded,
                          size: 11, color: Colors.white54),
                      const SizedBox(width: 4),
                      Text(
                        ContentTheme.compactCount(hub.totalViews),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
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
    );
  }
}

// ---------------------------------------------------------------------------
// Hub content screen (one fandom: Anime / Gaming / ...)
// ---------------------------------------------------------------------------
class HubContentScreen extends StatefulWidget {
  final FandomHub hub;

  const HubContentScreen({super.key, required this.hub});

  @override
  State<HubContentScreen> createState() => _HubContentScreenState();
}

class _HubContentScreenState extends State<HubContentScreen> {
  String _tab = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ContentProvider>().loadHub(widget.hub.slug);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContentProvider>();
    final bundle = provider.hubBundle;
    final color = ContentTheme.fandomColor(widget.hub.name);

    return Scaffold(
      backgroundColor: ContentTheme.background,
      body: Container(
        decoration: const BoxDecoration(gradient: ContentTheme.backgroundGradient),
        child: RefreshIndicator(
          onRefresh: () => provider.loadHub(widget.hub.slug, force: true),
          color: ContentTheme.primary,
          backgroundColor: ContentTheme.card,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 236,
                backgroundColor: ContentTheme.background,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppImage(
                        path: widget.hub.imageUrl,
                        fallbackColors: [color, ContentTheme.primaryDark],
                        fallbackIcon: ContentTheme.fandomIcon(widget.hub.name),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.25),
                              Colors.black.withValues(alpha: 0.9),
                            ],
                            stops: const [0.22, 1],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 18,
                        right: 18,
                        bottom: 18,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  ContentTheme.fandomIcon(widget.hub.name),
                                  size: 17,
                                  color: color,
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  'FANDOM HUB',
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              bundle?.hub.name ?? widget.hub.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 27,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bundle?.hub.tagline ?? widget.hub.tagline,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _HeaderStat(
                                  icon: Icons.article_rounded,
                                  value: '${bundle?.hub.itemsCount ?? widget.hub.itemsCount}',
                                  label: 'items',
                                ),
                                const SizedBox(width: 16),
                                _HeaderStat(
                                  icon: Icons.visibility_rounded,
                                  value: ContentTheme.compactCount(
                                    bundle?.hub.totalViews ?? widget.hub.totalViews,
                                  ),
                                  label: 'views',
                                ),
                                const SizedBox(width: 16),
                                _HeaderStat(
                                  icon: Icons.group_rounded,
                                  value: ContentTheme.compactCount(
                                    bundle?.hub.followersCount ?? widget.hub.followersCount,
                                  ),
                                  label: 'fans',
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
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarHeader(
                  child: AnimatedPill(
                    label: 'All',
                    icon: Icons.apps_rounded,
                    selected: _tab == 'all',
                    color: color,
                    onTap: () => setState(() => _tab = 'all'),
                  ),
                  extra: [
                    AnimatedPill(
                      label: 'News',
                      icon: Icons.newspaper_rounded,
                      selected: _tab == 'news',
                      color: color,
                      count: bundle?.news.length,
                      onTap: () => setState(() => _tab = 'news'),
                    ),
                    AnimatedPill(
                      label: 'Gallery',
                      icon: Icons.photo_library_rounded,
                      selected: _tab == 'gallery',
                      color: color,
                      count: bundle?.galleries.length,
                      onTap: () => setState(() => _tab = 'gallery'),
                    ),
                    AnimatedPill(
                      label: 'Videos',
                      icon: Icons.play_circle_rounded,
                      selected: _tab == 'video',
                      color: color,
                      count: bundle?.videos.length,
                      onTap: () => setState(() => _tab = 'video'),
                    ),
                    AnimatedPill(
                      label: 'Podcasts',
                      icon: Icons.podcasts_rounded,
                      selected: _tab == 'podcast',
                      color: color,
                      count: bundle?.podcasts.length,
                      onTap: () => setState(() => _tab = 'podcast'),
                    ),
                    AnimatedPill(
                      label: 'Deep Dive',
                      icon: Icons.psychology_alt_rounded,
                      selected: _tab == 'deep_dive',
                      color: color,
                      count: bundle?.deepDives.length,
                      onTap: () => setState(() => _tab = 'deep_dive'),
                    ),
                    AnimatedPill(
                      label: 'Glossary',
                      icon: Icons.menu_book_rounded,
                      selected: _tab == 'glossary',
                      color: color,
                      count: bundle?.glossary.length,
                      onTap: () => setState(() => _tab = 'glossary'),
                    ),
                  ],
                ),
              ),
              if (provider.loadingHub || bundle == null)
                const SliverPadding(
                  padding: EdgeInsets.all(18),
                  sliver: SliverToBoxAdapter(child: ContentLoadingList(count: 2)),
                )
              else if (_tab == 'glossary')
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => FadeSlideIn(
                        delay: Duration(milliseconds: 45 * index),
                        child: _GlossaryCard(term: bundle.glossary[index], accent: color),
                      ),
                      childCount: bundle.glossary.length,
                    ),
                  ),
                )
              else
                ..._buildSections(bundle),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSections(HubBundle bundle) {
    final showAll = _tab == 'all';

    List<ContentItem> pick(String type) {
      switch (type) {
        case 'news':
          return bundle.news;
        case 'gallery':
          return bundle.galleries;
        case 'video':
          return bundle.videos;
        case 'podcast':
          return bundle.podcasts;
        case 'deep_dive':
          return bundle.deepDives;
        default:
          return [];
      }
    }

    if (!showAll) {
      final items = pick(_tab);
      if (items.isEmpty) {
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyContentState(
              title: 'Nothing here yet',
              message: 'No ${ContentTheme.contentTypeLabel(_tab).toLowerCase()} for '
                  '${widget.hub.name} yet. Pull down to refresh.',
              icon: ContentTheme.contentTypeIcon(_tab),
            ),
          ),
        ];
      }

      if (_tab == 'gallery') {
        return [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => FadeSlideIn(
                  delay: Duration(milliseconds: 45 * index),
                  child: _GalleryPreviewCard(item: items[index]),
                ),
                childCount: items.length,
              ),
            ),
          ),
        ];
      }

      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => FadeSlideIn(
                delay: Duration(milliseconds: 45 * index),
                child: items[index].contentType == 'podcast'
                    ? PodcastTile(
                        item: items[index],
                        onTap: () => openContentItem(context, items[index]),
                      )
                    : ContentCard(
                        item: items[index],
                        onTap: () => openContentItem(context, items[index]),
                        showSummary: items[index].contentType != 'podcast',
                      ),
              ),
              childCount: items.length,
            ),
          ),
        ),
      ];
    }

    return [
      if (bundle.news.isNotEmpty)
        _HorizontalSection(
          title: 'Latest News',
          subtitle: 'Updates from ${widget.hub.name}',
          items: bundle.news.take(6).toList(),
          style: _SectionStyle.card,
          onSeeAll: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NewsListScreen(fandom: bundle.hub.name),
            ),
          ),
        ),
      if (bundle.deepDives.isNotEmpty)
        _HorizontalSection(
          title: 'Deep Dive',
          subtitle: 'Hidden trivia & advanced lore',
          items: bundle.deepDives,
          style: _SectionStyle.card,
        ),
      if (bundle.galleries.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Gallery',
                  subtitle: '${bundle.galleries.length} photo collections',
                  accent: ContentTheme.secondary,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 168,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: bundle.galleries.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) => FadeSlideIn(
                      delay: Duration(milliseconds: 55 * index),
                      offsetX: 30,
                      offsetY: 0,
                      child: SizedBox(
                        width: 168,
                        child: _GalleryPreviewCard(item: bundle.galleries[index]),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      if (bundle.videos.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Video Player',
                  subtitle: 'Trailers, breakdowns & community clips',
                  accent: ContentTheme.violet,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 208,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: bundle.videos.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) => FadeSlideIn(
                      delay: Duration(milliseconds: 55 * index),
                      offsetX: 30,
                      offsetY: 0,
                      child: VideoStillCard(
                        item: bundle.videos[index],
                        onTap: () => openContentItem(context, bundle.videos[index]),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      if (bundle.podcasts.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Podcasts',
                  subtitle: 'Latest Episodes',
                  accent: ContentTheme.primary,
                  actionLabel: 'All episodes',
                  onAction: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PodcastsScreen(fandom: bundle.hub.name),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...bundle.podcasts.take(3).map(
                      (podcast) => FadeSlideIn(
                        delay: const Duration(milliseconds: 60),
                        child: PodcastTile(
                          item: podcast,
                          onTap: () => openContentItem(context, podcast),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      if (bundle.glossary.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Beginner Glossary',
                  subtitle: 'New to the fandom? Start here',
                  accent: ContentTheme.amber,
                ),
                const SizedBox(height: 12),
                ...bundle.glossary.take(6).map(
                      (term) => FadeSlideIn(
                        delay: const Duration(milliseconds: 40),
                        child: _GlossaryCard(term: term, accent: ContentTheme.amber),
                      ),
                    ),
                const SizedBox(height: 6),
                PressScale(
                  onTap: () => setState(() => _tab = 'glossary'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: ContentTheme.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: ContentTheme.amber.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'View all glossary terms',
                        style: TextStyle(
                          color: ContentTheme.amber,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    ];
  }
}

enum _SectionStyle { card }

class _HorizontalSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<ContentItem> items;
  final _SectionStyle style;
  final VoidCallback? onSeeAll;

  const _HorizontalSection({
    required this.title,
    required this.subtitle,
    required this.items,
    this.style = _SectionStyle.card,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: title,
              subtitle: subtitle,
              accent: ContentTheme.primary,
              actionLabel: onSeeAll == null ? null : 'See All',
              onAction: onSeeAll,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 268,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) => FadeSlideIn(
                  delay: Duration(milliseconds: 55 * index),
                  offsetX: 30,
                  offsetY: 0,
                  child: SizedBox(
                    width: 244,
                    child: ContentCard(
                      item: items[index],
                      imageHeight: 132,
                      onTap: () => openContentItem(context, items[index]),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryPreviewCard extends StatelessWidget {
  final ContentItem item;

  const _GalleryPreviewCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: () => openContentItem(context, item),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AppImage(path: item.artwork, fallbackIcon: Icons.photo_library_rounded),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.82),
                  ],
                  stops: const [0.42, 1],
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.photo_library_rounded, size: 11, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      'GALLERY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
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
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${ContentTheme.compactCount(item.viewsCount)} views',
                    style: const TextStyle(color: Colors.white60, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlossaryCard extends StatefulWidget {
  final GlossaryTerm term;
  final Color accent;

  const _GlossaryCard({required this.term, this.accent = ContentTheme.primary});

  @override
  State<_GlossaryCard> createState() => _GlossaryCardState();
}

class _GlossaryCardState extends State<_GlossaryCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final term = widget.term;
    final accent = widget.accent;

    return PressScale(
      onTap: () => setState(() => _open = !_open),
      pressedScale: 0.98,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ContentTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _open
                ? accent.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    term.category.toUpperCase(),
                    style: TextStyle(
                      color: accent,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    term.term,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 260),
                  child: const Icon(Icons.expand_more_rounded,
                      color: ContentTheme.textMuted, size: 20),
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 9),
                child: Text(
                  term.definition,
                  style: const TextStyle(
                    color: ContentTheme.textSecondary,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ),
              crossFadeState:
                  _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 240),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _HeaderStat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white60),
        const SizedBox(width: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}

/// Pinned, horizontally scrolling filter chips below the hub header.
class _TabBarHeader extends SliverPersistentHeaderDelegate {
  final Widget child;
  final List<Widget> extra;

  _TabBarHeader({required this.child, required this.extra});

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: 56,
      color: ContentTheme.background.withValues(alpha: 0.96),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        children: [
          child,
          ...extra.map((widget) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: widget,
              )),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarHeader oldDelegate) => true;
}
