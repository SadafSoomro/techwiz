import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/community_models.dart';
import '../providers/community_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/community_chips.dart';
import '../widgets/community_post_card.dart';
import '../widgets/community_scaffold.dart';
import '../widgets/community_user_tile.dart';
import 'discussions_screen.dart';
import 'post_details_screen.dart';
import 'search_results_screen.dart';
import 'user_profile_screen.dart';

/// MEMBER 3 - Search & Community
/// Trending screen: trending hashtags + top results
/// (Users / Posts / Fandoms / Deep Dive discussions).
class TrendingScreen extends StatefulWidget {
  const TrendingScreen({super.key});

  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityProvider>().loadTrending();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CommunityProvider>();
    final bundle = provider.trending;

    return CommunityScaffold(
      title: 'Trending',
      subtitle: 'What the fandom is talking about',
      actions: [
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: () => context.read<CommunityProvider>().loadTrending(),
        ),
      ],
      child: provider.loading && bundle == null
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.secondaryColor),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                // ------------------------- hashtags -------------------------
                const CommunitySectionTitle('Trending Hashtags'),
                const SizedBox(height: 12),
                if (bundle == null || bundle.hashtags.isEmpty)
                  Text(
                    'No hashtags yet. Create a post with hashtags to start a trend!',
                    style: GoogleFonts.inter(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  )
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: bundle.hashtags
                        .map((tag) => _HashtagChip(tag: tag))
                        .toList(),
                  ),

                const SizedBox(height: 24),

                // --------------------------- tabs ---------------------------
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorColor: AppTheme.secondaryColor,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppTheme.textMuted,
                    labelStyle:
                        GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
                    unselectedLabelStyle: GoogleFonts.inter(fontSize: 12.5),
                    tabs: const [
                      Tab(text: 'Users'),
                      Tab(text: 'Posts'),
                      Tab(text: 'Fandoms'),
                      Tab(text: 'Deep Dive'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  height: 620,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _usersTab(bundle),
                      _postsTab(bundle),
                      _fandomsTab(bundle),
                      _deepDiveTab(bundle),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ------------------------------------------------------------------
  Widget _usersTab(TrendingBundle? bundle) {
    final users = bundle?.users ?? const <CommunityUser>[];
    if (users.isEmpty) {
      return const CommunityEmptyState(
        icon: Icons.people_outline_rounded,
        title: 'No trending users',
        message: 'Follow other fans to build your community.',
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: users
          .map(
            (user) => CommunityUserTile(
              user: user,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => UserProfileScreen(userId: user.id),
                ),
              ),
              onFollowTap: () =>
                  context.read<CommunityProvider>().toggleFollow(user),
            ),
          )
          .toList(),
    );
  }

  Widget _postsTab(TrendingBundle? bundle) {
    final posts = bundle?.posts ?? const <CommunityPost>[];
    if (posts.isEmpty) {
      return const CommunityEmptyState(
        icon: Icons.article_outlined,
        title: 'No trending posts',
        message: 'Be the first to post something in your fandom!',
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: posts.map((post) => _postCard(post)).toList(),
    );
  }

  Widget _fandomsTab(TrendingBundle? bundle) {
    final fandoms = bundle?.fandoms ?? const <FandomCategory>[];
    if (fandoms.isEmpty) {
      return const CommunityEmptyState(
        icon: Icons.auto_awesome_outlined,
        title: 'No fandoms yet',
        message: 'Fandom categories will appear here once posts are added.',
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: fandoms
          .map(
            (fandom) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DiscussionsScreen(initialFandom: fandom.name),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${fandom.hashtag}  ${fandom.name}',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                fandom.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: AppTheme.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${fandom.postsCount} posts',
                          style: GoogleFonts.inter(
                            color: AppTheme.accentCyan,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _deepDiveTab(TrendingBundle? bundle) {
    final deepDives = bundle?.deepDives ?? const <CommunityPost>[];
    if (deepDives.isEmpty) {
      return const CommunityEmptyState(
        icon: Icons.auto_awesome_rounded,
        title: 'No Deep Dives yet',
        message: 'Expert fans share hidden trivia and advanced lore here.',
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: deepDives.map((post) => _postCard(post)).toList(),
    );
  }

  Widget _postCard(CommunityPost post) {
    return CommunityPostCard(
      post: post,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PostDetailsScreen(postId: post.id, post: post),
        ),
      ),
      onAuthorTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => UserProfileScreen(userId: post.userId)),
      ),
      onLike: () => context.read<CommunityProvider>().toggleLike(post),
      onBookmark: () => context.read<CommunityProvider>().toggleBookmark(post),
      onComment: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PostDetailsScreen(postId: post.id, post: post),
        ),
      ),
    );
  }
}

class _HashtagChip extends StatelessWidget {
  final TrendingHashtag tag;

  const _HashtagChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SearchResultsScreen(
            query: tag.tag.replaceFirst('#', ''),
            type: 'all',
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.25),
              AppTheme.secondaryColor.withValues(alpha: 0.25),
            ],
          ),
          border: Border.all(
            color: AppTheme.secondaryColor.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tag.tag,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${tag.postsCount}',
                style: GoogleFonts.inter(
                  color: AppTheme.accentCyan,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
