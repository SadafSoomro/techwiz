import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/community_models.dart';
import '../providers/community_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_alert.dart';
import '../widgets/community_chips.dart';
import '../widgets/community_post_card.dart';
import '../widgets/community_scaffold.dart';
import 'post_details_screen.dart';
import 'user_profile_screen.dart';

/// MEMBER 3 - Search & Community
/// Bookmarks screen - "Saved Posts". Works both as a standalone screen
/// and as a tab inside the Home screen (embedded = true).
class BookmarksScreen extends StatefulWidget {
  final bool embedded;

  const BookmarksScreen({super.key, this.embedded = false});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  bool _grid = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityProvider>().loadBookmarks();
    });
  }

  Future<void> _clearAll() async {
    final provider = context.read<CommunityProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Clear all saved posts?',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Your bookmarks will be removed. You can always save them again.',
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: Text('Clear',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await provider.clearBookmarks();
    if (!mounted) return;

    if (result.success) {
      await showSuccessAlert(context, result.message, title: 'Bookmarks Cleared');
    } else {
      await showErrorAlert(context, result.message, title: 'Could Not Clear');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CommunityProvider>();
    final bookmarks = provider.bookmarks;

    return CommunityScaffold(
      title: 'Bookmarks',
      subtitle: '${bookmarks.length} saved post${bookmarks.length == 1 ? '' : 's'}',
      showBackButton: !widget.embedded,
      actions: [
        IconButton(
          tooltip: _grid ? 'List view' : 'Grid view',
          icon: Icon(
            _grid ? Icons.view_list_rounded : Icons.grid_view_rounded,
            color: Colors.white,
          ),
          onPressed: () => setState(() => _grid = !_grid),
        ),
        if (bookmarks.isNotEmpty)
          IconButton(
            tooltip: 'Clear all',
            icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.errorColor),
            onPressed: _clearAll,
          ),
      ],
      child: provider.loading && bookmarks.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.secondaryColor),
            )
          : bookmarks.isEmpty
              ? const CommunityEmptyState(
                  icon: Icons.bookmark_outline_rounded,
                  title: 'No saved posts yet',
                  message:
                      'Tap the bookmark icon on any post to save it here for\noffline reading and viewing.',
                )
              : RefreshIndicator(
                  color: AppTheme.secondaryColor,
                  onRefresh: () =>
                      context.read<CommunityProvider>().loadBookmarks(),
                  child: _grid ? _buildGrid(bookmarks) : _buildList(bookmarks),
                ),
    );
  }

  Widget _buildList(List<CommunityPost> bookmarks) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final post = bookmarks[index];
        return CommunityPostCard(
          post: post,
          onTap: () => _open(post),
          onAuthorTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => UserProfileScreen(userId: post.userId),
            ),
          ),
          onLike: () => context.read<CommunityProvider>().toggleLike(post),
          onBookmark: () => context.read<CommunityProvider>().toggleBookmark(post),
          onComment: () => _open(post),
        );
      },
    );
  }

  Widget _buildGrid(List<CommunityPost> bookmarks) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final post = bookmarks[index];
        return GestureDetector(
          onTap: () => _open(post),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: post.isDeepDive
                    ? AppTheme.secondaryColor.withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppTheme.primaryColor,
                      child: Text(
                        post.authorInitial,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.bookmark_rounded,
                      size: 16,
                      color: post.isBookmarked
                          ? AppTheme.accentCyan
                          : AppTheme.textMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Text(
                    post.title,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  post.fandom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppTheme.accentCyan,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      post.isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 13,
                      color: post.isLiked
                          ? AppTheme.secondaryColor
                          : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.likesCount}',
                      style: GoogleFonts.inter(
                        color: AppTheme.textMuted,
                        fontSize: 10.5,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.mode_comment_outlined,
                        size: 13, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${post.commentsCount}',
                      style: GoogleFonts.inter(
                        color: AppTheme.textMuted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _open(CommunityPost post) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PostDetailsScreen(postId: post.id, post: post),
      ),
    );
  }
}
