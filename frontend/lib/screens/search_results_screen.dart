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
import 'user_profile_screen.dart';

/// MEMBER 3 - Search & Community
/// Search results grouped into Users / Posts / Fandoms with counts.
class SearchResultsScreen extends StatefulWidget {
  final String query;
  final String type;
  final String fandom;
  final String sort;

  const SearchResultsScreen({
    super.key,
    required this.query,
    this.type = 'all',
    this.fandom = 'All',
    this.sort = 'popular',
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late String _type;
  late String _sort;

  @override
  void initState() {
    super.initState();
    _type = widget.type;
    _sort = widget.sort;

    WidgetsBinding.instance.addPostFrameCallback((_) => _runSearch());
  }

  Future<void> _runSearch() async {
    await context.read<CommunityProvider>().runSearch(
          query: widget.query,
          type: _type,
          fandom: widget.fandom,
          sort: _sort,
        );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CommunityProvider>();

    return CommunityScaffold(
      title: 'Results',
      subtitle: '"${widget.query}"',
      actions: [
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _runSearch,
        ),
      ],
      child: Column(
        children: [
          // -------------------- result type switcher --------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  CommunityFilterChip(
                    label: 'All',
                    selected: _type == 'all',
                    onTap: () {
                      setState(() => _type = 'all');
                      _runSearch();
                    },
                  ),
                  const SizedBox(width: 8),
                  CommunityFilterChip(
                    label: 'Users',
                    icon: Icons.people_alt_rounded,
                    selected: _type == 'users',
                    onTap: () {
                      setState(() => _type = 'users');
                      _runSearch();
                    },
                  ),
                  const SizedBox(width: 8),
                  CommunityFilterChip(
                    label: 'Posts',
                    icon: Icons.article_rounded,
                    selected: _type == 'posts',
                    onTap: () {
                      setState(() => _type = 'posts');
                      _runSearch();
                    },
                  ),
                  const SizedBox(width: 8),
                  CommunityFilterChip(
                    label: 'Fandoms',
                    icon: Icons.auto_awesome_rounded,
                    selected: _type == 'fandoms',
                    onTap: () {
                      setState(() => _type = 'fandoms');
                      _runSearch();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ------------------------- sort chips -------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.sort_rounded,
                    size: 16, color: AppTheme.textMuted),
                const SizedBox(width: 8),
                Text(
                  'Sort:',
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        {'key': 'popular', 'label': 'Popular'},
                        {'key': 'newest', 'label': 'Newest'},
                        {'key': 'top', 'label': 'Top'},
                        {'key': 'trending', 'label': 'Trending'},
                      ].map((option) {
                        final selected = _sort == option['key'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _sort = option['key']!);
                              _runSearch();
                            },
                            child: Text(
                              option['label']!,
                              style: GoogleFonts.inter(
                                color: selected
                                    ? AppTheme.secondaryColor
                                    : AppTheme.textMuted,
                                fontSize: 12,
                                fontWeight:
                                    selected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // --------------------------- results ---------------------------
          Expanded(
            child: provider.loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.secondaryColor,
                    ),
                  )
                : _buildResults(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(CommunityProvider provider) {
    final results = provider.searchResults;

    if (results == null || results.isEmpty) {
      return CommunityEmptyState(
        icon: Icons.search_off_rounded,
        title: 'No results found',
        message:
            'We could not find anything for "${widget.query}".\nTry another keyword or change the filters.',
        actionLabel: 'Go back',
        onAction: () => Navigator.of(context).maybePop(),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // ---------------------------- users ----------------------------
        if (results.users.isNotEmpty) ...[
          CommunitySectionTitle('Users (${results.users.length})'),
          const SizedBox(height: 10),
          ...results.users.map(
            (user) => CommunityUserTile(
              user: user,
              onTap: () => _openUser(user),
              onFollowTap: () => context.read<CommunityProvider>().toggleFollow(user),
            ),
          ),
          const SizedBox(height: 18),
        ],

        // ---------------------------- posts ----------------------------
        if (results.posts.isNotEmpty) ...[
          CommunitySectionTitle('Posts (${results.posts.length})'),
          const SizedBox(height: 10),
          ...results.posts.map(
            (post) => CommunityPostCard(
              post: post,
              onTap: () => _openPost(post),
              onAuthorTap: () => _openUserById(post.userId, post.authorName),
              onLike: () => context.read<CommunityProvider>().toggleLike(post),
              onBookmark: () =>
                  context.read<CommunityProvider>().toggleBookmark(post),
              onComment: () => _openPost(post),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // --------------------------- fandoms ---------------------------
        if (results.fandoms.isNotEmpty) ...[
          CommunitySectionTitle('Fandoms (${results.fandoms.length})'),
          const SizedBox(height: 10),
          ...results.fandoms.map((fandom) => _FandomResultTile(fandom: fandom)),
        ],
      ],
    );
  }

  // ---------------------------- navigation ----------------------------
  void _openPost(CommunityPost post) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PostDetailsScreen(postId: post.id, post: post)),
    );
  }

  void _openUser(CommunityUser user) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => UserProfileScreen(userId: user.id)),
    );
  }

  void _openUserById(int userId, String name) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(userId: userId, userName: name),
      ),
    );
  }
}

class _FandomResultTile extends StatelessWidget {
  final FandomCategory fandom;

  const _FandomResultTile({required this.fandom});

  Color get _color {
    final value = fandom.color.replaceFirst('#', '');
    final parsed = int.tryParse('FF$value', radix: 16);
    return parsed == null ? AppTheme.primaryColor : Color(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.auto_awesome_rounded, color: _color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fandom.name,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fandom.description.isNotEmpty
                            ? fandom.description
                            : '${fandom.postsCount} posts',
                        maxLines: 1,
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
                  '${fandom.postsCount}',
                  style: GoogleFonts.outfit(
                    color: _color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
