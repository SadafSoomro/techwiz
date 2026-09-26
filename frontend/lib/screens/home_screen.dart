import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/content_models.dart';
import '../models/profile_models.dart';
import '../providers/ai_provider.dart';
import '../providers/community_provider.dart';
import '../providers/content_provider.dart';
import '../providers/event_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/shop_provider.dart';
import '../theme/app_theme.dart';
import '../theme/content_theme.dart';
import '../theme/event_theme.dart';
import '../theme/profile_theme.dart';
import '../widgets/ai_agent_button.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/app_image.dart';
import '../widgets/content_widgets.dart';
import '../widgets/fandom_logo.dart';
import '../widgets/profile_widgets.dart';
import 'ai_helper_screen.dart';
import 'bookmarks_screen.dart';
import 'discussions_screen.dart';
import 'discover_screen.dart';
import 'event_calendar_screen.dart';
import 'event_categories_screen.dart';
import 'event_map_screen.dart';
import 'events_screen.dart';
import 'fandom_hub_screen.dart';
import 'gallery_screen.dart';
import 'invite_friends_screen.dart';
import 'my_fandoms_screen.dart';
import 'notifications_screen.dart';
import 'news_details_screen.dart';
import 'news_list_screen.dart';
import 'podcasts_screen.dart';
import 'profile_badges_screen.dart';
import 'profile_screen.dart';
import 'recent_content_screen.dart';
import 'saved_events_screen.dart';
import 'search_screen.dart';
import 'shop_screen.dart';
import 'social_tasks_screen.dart';
import 'trending_screen.dart';
import 'video_player_screen.dart';

/// FANDOM VERSE - application shell.
///
/// Tab 0  Home Dashboard   -> MEMBER 1 (Profile, Fandom Selection & Home)
/// Tab 1  Explore          -> MEMBER 2 (Fandom Content)
/// Tab 2  Events           -> MEMBER 4 (Events & Maps)
/// Tab 3  Shop             -> MEMBER 5 (Merchandise Store + AI Fan Helper)
/// Tab 4  Saved            -> MEMBER 3 (Search & Community bookmarks)
/// Tab 5  Profile          -> MEMBER 1 (Profile & account)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // MEMBER 1 - Profile & Home dashboard aggregate.
      context.read<ProfileProvider>().loadDashboard();

      // MEMBER 2 - Fandom content (Discover rail).
      context.read<ContentProvider>().loadDiscover();

      // MEMBER 3 - Search & Community.
      final community = context.read<CommunityProvider>();
      community.refreshUnreadCount();
      community.loadOverview();

      // MEMBER 4 - Events & Maps.
      final events = context.read<EventProvider>();
      events.loadOverview();
      events.loadEvents();

      // MEMBER 5 - Merchandise Store + AI Fan Helper.
      final shop = context.read<ShopProvider>();
      shop.loadOverview();
      shop.loadFilters();
      shop.loadProducts();
      shop.loadPersonal();
      context.read<AiProvider>().initialise(restoreHistory: false);
    });
  }

  void _openTab(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  /// Opens the AI Fan Helper from the cartoon companion that floats above the
  /// bottom bar.
  Future<void> _openAiHelper() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AiHelperScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Stack(
          children: [
            Positioned.fill(
              child: SafeArea(
                child: IndexedStack(
                  index: _currentIndex,
                  children: [
                    _HomeDashboardTab(onOpenTab: _openTab),
                    const DiscoverScreen(embedded: true),
                    const EventsScreen(embedded: true),
                    const ShopScreen(embedded: true),
                    const BookmarksScreen(embedded: true),
                    const ProfileScreen(embedded: true),
                  ],
                ),
              ),
            ),

            // MEMBER 5 - AI Fan Helper: its own little companion, floating
            // just above the bottom bar on the left, kept apart from the tabs.
            Positioned(
              left: 14,
              bottom: 12,
              child: AiAgentButton(onTap: _openAiHelper),
            ),
          ],
        ),
      ),
      // The gradient is repeated behind the floating bar so the rounded corners
      // never reveal a flat strip of the scaffold colour.
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: _FandomNavBar(
          currentIndex: _currentIndex,
          onSelect: _openTab,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// floating bottom navigation
// ---------------------------------------------------------------------------
class _FandomNavBar extends StatelessWidget {
  const _FandomNavBar({required this.currentIndex, required this.onSelect});

  final int currentIndex;
  final ValueChanged<int> onSelect;

  static const List<
      ({IconData icon, IconData activeIcon, String label, Color accent})>
      _items = [
    (
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
      accent: Color(0xFF6D8BFF),
    ),
    (
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore_rounded,
      label: 'Explore',
      accent: Color(0xFFEC4899),
    ),
    (
      icon: Icons.celebration_outlined,
      activeIcon: Icons.celebration_rounded,
      label: 'Events',
      accent: Color(0xFFFBBF24),
    ),
    (
      icon: Icons.shopping_bag_outlined,
      activeIcon: Icons.shopping_bag_rounded,
      label: 'Shop',
      accent: Color(0xFFA855F7),
    ),
    (
      icon: Icons.bookmark_border_rounded,
      activeIcon: Icons.bookmark_rounded,
      label: 'Saved',
      accent: Color(0xFF06B6D4),
    ),
    (
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
      accent: Color(0xFF10B981),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 9),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1B2337), Color(0xFF111827)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: List.generate(
              _items.length,
              (index) => Expanded(
                child: _NavItem(
                  icon: _items[index].icon,
                  activeIcon: _items[index].activeIcon,
                  label: _items[index].label,
                  accent: _items[index].accent,
                  selected: index == currentIndex,
                  onTap: () => onSelect(index),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A single tab: the active one lifts into a glowing gradient capsule, the
/// others stay as quiet outlined glyphs.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      pressedScale: 0.85,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: selected ? 1.08 : 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                gradient: selected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent,
                          Color.lerp(accent, Colors.white, 0.28)!,
                        ],
                      )
                    : null,
                borderRadius: BorderRadius.circular(15),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.55),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                selected ? activeIcon : icon,
                size: 20,
                color: selected ? Colors.white : AppTheme.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : AppTheme.textMuted,
              letterSpacing: 0.1,
            ),
            child: Text(label, maxLines: 1, overflow: TextOverflow.clip),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MEMBER 1 - Home Dashboard
// ---------------------------------------------------------------------------
class _HomeDashboardTab extends StatelessWidget {
  const _HomeDashboardTab({required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  Future<void> _push(BuildContext context, Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  /// Opens a fandom hub card: prefers the matching hub from the dashboard
  /// payload, otherwise lands on the Explore Fandoms list.
  void _openFandom(BuildContext context, String name) {
    final hubs = context.read<ProfileProvider>().dashboard?.hubs ?? const [];
    FandomHub? match;
    for (final hub in hubs) {
      if (hub.name.toLowerCase() == name.toLowerCase()) {
        match = hub;
        break;
      }
    }
    if (match != null) {
      FandomHubScreen.openHub(context, match);
    } else {
      _push(context, const FandomHubScreen());
    }
  }

  void _openContent(BuildContext context, ContentItem item) {
    if (item.contentType == 'video') {
      _push(context, VideoPlayerScreen(item: item));
      return;
    }
    _push(context, NewsDetailsScreen(item: item));
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final content = context.watch<ContentProvider>();
    final dashboard = profile.dashboard;

    if (dashboard == null) {
      return RefreshIndicator(
        color: ProfileTheme.primary,
        onRefresh: () => profile.loadDashboard(refresh: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          children: const [
            Shimmer(height: 62, borderRadius: BorderRadius.all(Radius.circular(20))),
            SizedBox(height: 18),
            Shimmer(height: 150, borderRadius: BorderRadius.all(Radius.circular(22))),
            SizedBox(height: 18),
            ShimmerCard(imageHeight: 130),
            SizedBox(height: 22),
            ShimmerCard(imageHeight: 130),
          ],
        ),
      );
    }

    final user = dashboard.user;

    return RefreshIndicator(
      color: ProfileTheme.primary,
      onRefresh: () async {
        await profile.loadDashboard(refresh: true);
        await content.loadDiscover();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
        physics: const BouncingScrollPhysics(),
        children: [
          // ------------------------------------------------ app bar
          FadeSlideIn(child: _buildHeader(context, dashboard)),
          const SizedBox(height: 18),

          // ------------------------------------------------ greeting
          FadeSlideIn(
            delay: const Duration(milliseconds: 60),
            child: _buildGreetingCard(context, user),
          ),
          const SizedBox(height: 16),

          // ------------------------------------------------ search
          FadeSlideIn(
            delay: const Duration(milliseconds: 100),
            child: _buildSearchBar(context),
          ),
          const SizedBox(height: 24),

          // ------------------------------------------------ trending fandoms carousel
          SectionHeader(
            title: 'Trending Fandoms',
            subtitle: 'Popular right now',
            actionLabel: 'See all',
            accent: ProfileTheme.primary,
            onAction: () => _push(context, const FandomHubScreen()),
          ),
          const SizedBox(height: 12),
          FadeSlideIn(
            delay: const Duration(milliseconds: 140),
            child: SizedBox(
              height: 168,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: dashboard.trending.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final fandom = dashboard.trending[index];
                  return _TrendingFandomCard(
                    fandom: fandom,
                    onTap: () => _openFandom(context, fandom.name),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ------------------------------------------------ your fandoms
          if (dashboard.fandoms.isNotEmpty) ...[
            SectionHeader(
              title: 'Your Fandoms',
              subtitle: '${dashboard.fandoms.length} selected',
              actionLabel: 'Edit',
              accent: ProfileTheme.primary,
              onAction: () => _push(context, const MyFandomsScreen()),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: const Duration(milliseconds: 160),
              child: SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: dashboard.fandoms.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 9),
                  itemBuilder: (context, index) {
                    final fandom = dashboard.fandoms[index];
                    final color = fandom.displayColor;
                    return AnimatedPill(
                      label: fandom.name,
                      icon: ProfileTheme.fandomIcon(fandom.name),
                      color: color,
                      selected: true,
                      onTap: () => _openFandom(context, fandom.name),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ------------------------------------------------ continue
          if (dashboard.continueWatching.isNotEmpty) ...[
            SectionHeader(
              title: 'Continue',
              subtitle: 'Pick up where you left off',
              actionLabel: 'Library',
              accent: ContentTheme.primary,
              onAction: () => _push(context, const RecentContentScreen()),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: const Duration(milliseconds: 180),
              child: SizedBox(
                height: 158,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: dashboard.continueWatching.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = dashboard.continueWatching[index];
                    return _ContinueCard(
                      item: item,
                      onTap: () => _openContent(
                        context,
                        ContentItem(
                          id: item.id,
                          title: item.title,
                          imageUrl: item.imageUrl,
                          contentType: item.contentType,
                          fandom: item.fandom,
                          durationSeconds: item.durationSeconds,
                          isOffline: item.isOffline,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ------------------------------------------------ latest news
          if (dashboard.latestNews.isNotEmpty) ...[
            SectionHeader(
              title: 'Latest Updates',
              subtitle: 'From your favorite series',
              actionLabel: 'See all',
              accent: ContentTheme.primary,
              onAction: () => _push(
                context,
                const NewsListScreen(title: 'Latest Updates'),
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(
              dashboard.latestNews.take(2).length,
              (index) {
                final item = dashboard.latestNews[index];
                return FadeSlideIn(
                  delay: Duration(milliseconds: 200 + index * 60),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: ContentCard(
                      item: item,
                      imageHeight: 140,
                      showSummary: true,
                      onTap: () => _openContent(context, item),
                    ),
                  ),
                );
              },
            ),
            // compact list for the remaining stories
            ...List.generate(
              dashboard.latestNews.skip(2).length,
              (index) {
                final item = dashboard.latestNews.skip(2).elementAt(index);
                return FadeSlideIn(
                  delay: Duration(milliseconds: 260 + index * 50),
                  child: ContentRowTile(
                    item: item,
                    onTap: () => _openContent(context, item),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ],

          // ------------------------------------------------ fandom hub quick rail
          if (dashboard.hubs.isNotEmpty) ...[
            SectionHeader(
              title: 'Fandom Hub',
              subtitle: 'Explore every universe',
              actionLabel: 'See all',
              accent: ContentTheme.primary,
              onAction: () => _push(context, const FandomHubScreen()),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: const Duration(milliseconds: 220),
              child: SizedBox(
                height: 158,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: dashboard.hubs.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final hub = dashboard.hubs[index];
                    return FandomHubCard(
                      hub: hub,
                      width: 224,
                      height: 158,
                      onTap: () => FandomHubScreen.openHub(context, hub),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ------------------------------------------------ for you
          if (dashboard.forYou.isNotEmpty) ...[
            SectionHeader(
              title: 'For You',
              subtitle: 'Based on your fandoms',
              actionLabel: 'Discover',
              accent: ContentTheme.primary,
              onAction: () => onOpenTab(1),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: const Duration(milliseconds: 240),
              child: SizedBox(
                height: 214,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: dashboard.forYou.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = dashboard.forYou[index];
                    return VideoStillCard(
                      item: item,
                      width: 240,
                      onTap: () => _openContent(context, item),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ------------------------------------------------ media shortcuts (MEMBER 2)
          SectionHeader(
            title: 'Explore Content',
            subtitle: 'News · Gallery · Videos · Podcasts',
            accent: ContentTheme.primary,
          ),
          const SizedBox(height: 12),
          FadeSlideIn(
            delay: const Duration(milliseconds: 260),
            child: Column(
              children: [
                Row(
                  children: [
                    _quickTile(context, 'News', Icons.newspaper_rounded,
                        ContentTheme.amber,
                        () => _push(context,
                            const NewsListScreen(title: 'News'))),
                    const SizedBox(width: 12),
                    _quickTile(context, 'Gallery', Icons.photo_library_rounded,
                        ContentTheme.rose,
                        () => _push(context, const GalleryScreen())),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _quickTile(context, 'Videos', Icons.play_circle_rounded,
                        ContentTheme.violet, () => onOpenTab(1)),
                    const SizedBox(width: 12),
                    _quickTile(context, 'Podcasts', Icons.podcasts_rounded,
                        ContentTheme.primary,
                        () => _push(context, const PodcastsScreen())),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _quickTile(context, 'Fandom Hub', Icons.explore_rounded,
                        ContentTheme.secondary,
                        () => _push(context, const FandomHubScreen())),
                    const SizedBox(width: 12),
                    _quickTile(context, 'Library', Icons.history_rounded,
                        ContentTheme.primaryDark,
                        () => _push(context, const RecentContentScreen())),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ------------------------------------------------ badges + tasks
          SectionHeader(
            title: 'Your Badges',
            subtitle: '${dashboard.badges.length} unlocked · ${dashboard.stats.badgeCount} total',
            actionLabel: 'See all',
            accent: ProfileTheme.amber,
            onAction: () => _push(context, const ProfileBadgesScreen()),
          ),
          const SizedBox(height: 12),
          FadeSlideIn(
            delay: const Duration(milliseconds: 280),
            child: SizedBox(
              height: 74,
              child: dashboard.badges.isEmpty
                  ? const Center(
                      child: Text(
                        'Complete tasks to unlock your first badge',
                        style: TextStyle(
                          color: ProfileTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: dashboard.badges.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) =>
                          _BadgeChip(badge: dashboard.badges[index]),
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // ------------------------------------------------ tasks + invite
          FadeSlideIn(
            delay: const Duration(milliseconds: 300),
            child: _buildTaskProgress(context, dashboard),
          ),
          const SizedBox(height: 14),
          FadeSlideIn(
            delay: const Duration(milliseconds: 320),
            child: InviteSummaryCard(
              user: user,
              onTap: () => _push(context, const InviteFriendsScreen()),
            ),
          ),
          const SizedBox(height: 24),

          // ------------------------------------------------ community (MEMBER 3)
          SectionHeader(
            title: 'Community',
            subtitle: 'Discussions, trending & search',
            actionLabel: 'All discussions',
            accent: AppTheme.primaryColor,
            onAction: () => _push(context, const DiscussionsScreen()),
          ),
          const SizedBox(height: 12),
          FadeSlideIn(
            delay: const Duration(milliseconds: 340),
            child: Column(
              children: [
                Row(
                  children: [
                    _quickTile(context, 'Trending',
                        Icons.local_fire_department_rounded,
                        AppTheme.secondaryColor,
                        () => _push(context, const TrendingScreen())),
                    const SizedBox(width: 12),
                    _quickTile(context, 'Deep Dive',
                        Icons.auto_awesome_rounded, AppTheme.primaryColor,
                        () => _push(context, const DiscussionsScreen())),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _quickTile(context, 'Search', Icons.search_rounded,
                        AppTheme.accentCyan,
                        () => _push(context, const SearchScreen())),
                    const SizedBox(width: 12),
                    _quickTile(context, 'Bookmarks',
                        Icons.bookmark_rounded, Colors.amber,
                        () => onOpenTab(4)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ------------------------------------------------ events (MEMBER 4)
          SectionHeader(
            title: 'Events Near You',
            subtitle: 'Conventions, meetups & screenings',
            actionLabel: 'See all',
            accent: EventTheme.primary,
            onAction: () => onOpenTab(2),
          ),
          const SizedBox(height: 12),
          FadeSlideIn(
            delay: const Duration(milliseconds: 360),
            child: _buildNextEvent(context, dashboard.nextEvent),
          ),
          const SizedBox(height: 12),
          FadeSlideIn(
            delay: const Duration(milliseconds: 380),
            child: Column(
              children: [
                Row(
                  children: [
                    _quickTile(context, 'Map', Icons.map_rounded,
                        EventTheme.teal,
                        () => _push(context, const EventMapScreen())),
                    const SizedBox(width: 12),
                    _quickTile(context, 'Calendar', Icons.calendar_month_rounded,
                        EventTheme.amber,
                        () => _push(context, const EventCalendarScreen())),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _quickTile(context, 'Categories', Icons.category_rounded,
                        EventTheme.primary,
                        () => _push(context, const EventCategoriesScreen())),
                    const SizedBox(width: 12),
                    _quickTile(context, 'Interested', Icons.favorite_rounded,
                        EventTheme.secondary,
                        () => _push(context, const SavedEventsScreen())),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          Center(
            child: Text(
              'FANDOM VERSE · One App · All Fandoms · Infinite Possibilities',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.25),
                fontSize: 10.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // pieces
  // ------------------------------------------------------------------

  Widget _buildHeader(BuildContext context, HomeDashboard dashboard) {
    final community = context.watch<CommunityProvider>();

    return Row(
      children: [
        const FandomLogoWidget(height: 34),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.search_rounded, color: Colors.white, size: 22),
          onPressed: () => _push(context, const SearchScreen()),
        ),
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded,
                  color: Colors.white, size: 22),
              onPressed: () async {
                await _push(context, const NotificationsScreen());
                if (context.mounted) community.refreshUnreadCount();
              },
            ),
            if (community.unreadCount > 0 || dashboard.unreadNotifications > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${community.unreadCount > 0 ? community.unreadCount : dashboard.unreadNotifications}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 4),
        PressScale(
          onTap: () => onOpenTab(5),
          child: AppAvatar(
            path: dashboard.user.avatar,
            name: dashboard.user.name,
            radius: 18,
            ringColor: ProfileTheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildGreetingCard(BuildContext context, ProfileUser user) {
    final stats = context.watch<ProfileProvider>().stats;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${context.watch<ProfileProvider>().dashboard?.greeting ?? 'Welcome'}, ${user.name.split(' ').first}!',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Ready to explore your fandoms?',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.28)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Lv ${user.level}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ProfileTheme.levelName(user.level),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 8.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _greetingStat(Icons.workspace_premium_rounded,
                  '${user.points}', 'Points'),
              Container(
                width: 1,
                height: 28,
                color: Colors.white.withValues(alpha: 0.22),
              ),
              _greetingStat(Icons.auto_awesome_rounded,
                  '${stats.fandomCount}', 'Fandoms'),
              Container(
                width: 1,
                height: 28,
                color: Colors.white.withValues(alpha: 0.22),
              ),
              _greetingStat(Icons.task_alt_rounded,
                  '${stats.completedTasks}/${stats.totalTasks}', 'Tasks'),
              Container(
                width: 1,
                height: 28,
                color: Colors.white.withValues(alpha: 0.22),
              ),
              _greetingStat(Icons.download_done_rounded,
                  '${stats.offlineCount}', 'Offline'),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedProgressBar(
            value: user.levelProgress,
            height: 6,
            colors: const [Colors.white, Color(0xFFE0E7FF)],
          ),
        ],
      ),
    );
  }

  Widget _greetingStat(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return PressScale(
      onTap: () => _push(context, const SearchScreen()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: AppTheme.inputFillColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 19),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Search fandoms, news, events...',
                style: GoogleFonts.inter(
                  color: AppTheme.textMuted,
                  fontSize: 13.5,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: ProfileTheme.primary.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.tune_rounded,
                  color: ProfileTheme.primary, size: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskProgress(BuildContext context, HomeDashboard dashboard) {
    final completed = dashboard.stats.completedTasks;
    final total = dashboard.stats.totalTasks == 0 ? 1 : dashboard.stats.totalTasks;

    return PressScale(
      onTap: () => _push(context, const SocialTasksScreen()),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ProfileTheme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ProfileTheme.green.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.task_alt_rounded,
                  color: ProfileTheme.green, size: 20),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Social & Tasks',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '$completed/$total',
                        style: const TextStyle(
                          color: ProfileTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  AnimatedProgressBar(
                    value: completed / total,
                    height: 8,
                    colors: const [ProfileTheme.green, ProfileTheme.cyan],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: ProfileTheme.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNextEvent(BuildContext context, NextEventPreview? event) {
    if (event == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: const [
            Icon(Icons.event_busy_rounded, color: EventTheme.primary),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No upcoming events yet - check back soon.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return PressScale(
      onTap: () => onOpenTab(2),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: EventTheme.featuredGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: EventTheme.primary.withValues(alpha: 0.34),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -22,
              bottom: -26,
              child: Icon(
                EventTheme.categoryIcon(event.category),
                size: 116,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.32),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'NEXT EVENT · ${event.eventDate}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: Colors.white70, size: 13),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${event.venue}, ${event.city}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                    Text(
                      event.category,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickTile(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: PressScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
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
// dashboard pieces
// ---------------------------------------------------------------------------

class _TrendingFandomCard extends StatelessWidget {
  const _TrendingFandomCard({required this.fandom, this.onTap});

  final TrendingFandom fandom;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = ProfileTheme.parseColor(
      fandom.color,
      fallback: ProfileTheme.fandomColor(fandom.name),
    );

    return PressScale(
      onTap: onTap,
      child: Hero(
        tag: 'fandom-${fandom.name}',
        child: Container(
          width: 158,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: fandom.isSelected
                  ? color.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.08),
              width: fandom.isSelected ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppImage(
                  path: ProfileTheme.fandomArtwork(fandom.name),
                  fallbackColors: [color, ProfileTheme.primaryDark],
                  fallbackIcon: ProfileTheme.fandomIcon(fandom.name),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.88),
                      ],
                      stops: const [0.35, 1],
                    ),
                  ),
                ),
                if (fandom.isSelected)
                  Positioned(
                    top: 9,
                    right: 9,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 11),
                    ),
                  ),
                Positioned(
                  left: 11,
                  right: 11,
                  bottom: 11,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          fandom.hashtag,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        fandom.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
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
                          fontSize: 10,
                        ),
                      ),
                    ],
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

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.item, this.onTap});

  final ContinueWatching item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = ContentTheme.contentTypeColor(item.contentType);

    return PressScale(
      onTap: onTap,
      child: Container(
        width: 208,
        decoration: BoxDecoration(
          color: ContentTheme.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(17),
              ),
              child: AppImage(
                path: item.imageUrl,
                height: 84,
                fallbackIcon: ContentTheme.contentTypeIcon(item.contentType),
                fallbackColors: [color, ContentTheme.primaryDark],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 7),
                  AnimatedProgressBar(
                    value: item.percentage / 100,
                    height: 5,
                    colors: [color, ContentTheme.secondary],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        '${item.percentage}% complete',
                        style: const TextStyle(
                          color: ContentTheme.textMuted,
                          fontSize: 9.5,
                        ),
                      ),
                      if (item.isOffline) ...[
                        const Spacer(),
                        const Icon(Icons.download_done_rounded,
                            size: 11, color: ContentTheme.primary),
                      ],
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

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge});

  final ProfileBadge badge;

  @override
  Widget build(BuildContext context) {
    final color = badge.displayColor;

    return PressScale(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProfileBadgesScreen()),
      ),
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: ProfileTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(ProfileTheme.icon(badge.icon), color: color, size: 15),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                badge.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
