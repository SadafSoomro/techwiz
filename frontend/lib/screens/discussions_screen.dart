import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/community_models.dart';
import '../providers/community_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/community_chips.dart';
import '../widgets/community_post_card.dart';
import '../widgets/community_scaffold.dart';
import 'create_post_screen.dart';
import 'post_details_screen.dart';
import 'user_profile_screen.dart';

/// MEMBER 3 - Search & Community
/// "Deep Dive" discussions list with sorting (Popular / Newest / Top /
/// Trending), fandom filter and a Create Post action.
class DiscussionsScreen extends StatefulWidget {
  final String initialFandom;

  const DiscussionsScreen({super.key, this.initialFandom = ''});

  @override
  State<DiscussionsScreen> createState() => _DiscussionsScreenState();
}

class _DiscussionsScreenState extends State<DiscussionsScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _fandom = 'All';

  static const List<Map<String, String>> _sortOptions = [
    {'key': 'popular', 'label': 'Popular'},
    {'key': 'newest', 'label': 'Newest'},
    {'key': 'top', 'label': 'Top'},
    {'key': 'trending', 'label': 'Trending'},
  ];

  @override
  void initState() {
    super.initState();
    _fandom = widget.initialFandom.isEmpty ? 'All' : widget.initialFandom;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CommunityProvider>();
      if (provider.fandoms.isEmpty) provider.loadFilters();
      provider.loadDiscussions(fandom: _fandom);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openCreatePost() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreatePostScreen(deepDive: true)),
    );

    if (created == true && mounted) {
      context.read<CommunityProvider>().loadDiscussions(
            fandom: _fandom,
            query: _searchController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CommunityProvider>();

    return CommunityScaffold(
      title: 'Deep Dive',
      subtitle: 'Advanced lore, trivia & expert discussions',
      actions: [
        IconButton(
          tooltip: 'Create post',
          icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
          onPressed: _openCreatePost,
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreatePost,
        backgroundColor: AppTheme.secondaryColor,
        icon: const Icon(Icons.edit_rounded, color: Colors.white),
        label: Text(
          'New Discussion',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      child: Column(
        children: [
          // ------------------------- search bar -------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppTheme.inputFillColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded,
                      color: AppTheme.textMuted, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search discussions...',
                        hintStyle: GoogleFonts.inter(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onSubmitted: (value) => context
                          .read<CommunityProvider>()
                          .loadDiscussions(fandom: _fandom, query: value.trim()),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        context
                            .read<CommunityProvider>()
                            .loadDiscussions(fandom: _fandom);
                      },
                      child: const Icon(Icons.close_rounded,
                          color: AppTheme.textMuted, size: 18),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // --------------------------- sorting ---------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.sort_rounded,
                    size: 16, color: AppTheme.textMuted),
                const SizedBox(width: 8),
                Text(
                  'Sort by',
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _sortOptions.map((option) {
                        final selected = provider.discussionSort == option['key'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: CommunityFilterChip(
                            label: option['label']!,
                            selected: selected,
                            accentColor: AppTheme.secondaryColor,
                            onTap: () => context
                                .read<CommunityProvider>()
                                .loadDiscussions(
                                  sort: option['key'],
                                  fandom: _fandom,
                                  query: _searchController.text.trim(),
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
          const SizedBox(height: 12),

          // ------------------------ fandom filter ------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  CommunityFilterChip(
                    label: 'All',
                    selected: _fandom == 'All',
                    accentColor: AppTheme.secondaryColor,
                    onTap: () {
                      setState(() => _fandom = 'All');
                      context.read<CommunityProvider>().loadDiscussions(
                            fandom: 'All',
                            query: _searchController.text.trim(),
                          );
                    },
                  ),
                  ...provider.fandoms.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: CommunityFilterChip(
                        label: f.name,
                        selected: _fandom == f.name,
                        accentColor: AppTheme.secondaryColor,
                        onTap: () {
                          setState(() => _fandom = f.name);
                          context.read<CommunityProvider>().loadDiscussions(
                                fandom: f.name,
                                query: _searchController.text.trim(),
                              );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // --------------------------- the list ---------------------------
          Expanded(
            child: provider.loading && provider.discussions.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.secondaryColor,
                    ),
                  )
                : provider.discussions.isEmpty
                    ? CommunityEmptyState(
                        icon: Icons.auto_awesome_rounded,
                        title: 'No discussions yet',
                        message:
                            'Start a Deep Dive and share hidden trivia, advanced\nlore or behind-the-scenes details.',
                        actionLabel: 'Create Discussion',
                        onAction: _openCreatePost,
                      )
                    : RefreshIndicator(
                        color: AppTheme.secondaryColor,
                        onRefresh: () => context.read<CommunityProvider>().loadDiscussions(
                              fandom: _fandom,
                              query: _searchController.text.trim(),
                            ),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                          itemCount: provider.discussions.length,
                          itemBuilder: (context, index) {
                            final post = provider.discussions[index];
                            return CommunityPostCard(
                              post: post,
                              onTap: () => _openDetails(post),
                              onAuthorTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      UserProfileScreen(userId: post.userId),
                                ),
                              ),
                              onLike: () => context
                                  .read<CommunityProvider>()
                                  .toggleLike(post),
                              onBookmark: () => context
                                  .read<CommunityProvider>()
                                  .toggleBookmark(post),
                              onComment: () => _openDetails(post),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDetails(CommunityPost post) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PostDetailsScreen(postId: post.id, post: post),
      ),
    );
    if (mounted) {
      context.read<CommunityProvider>().loadDiscussions(
            fandom: _fandom,
            query: _searchController.text.trim(),
          );
    }
  }
}
