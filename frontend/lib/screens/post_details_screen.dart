import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/community_models.dart';
import '../providers/auth_provider.dart';
import '../providers/community_provider.dart';
import '../services/community_service.dart';
import '../theme/app_theme.dart';
import '../widgets/community_banner_image.dart';
import '../widgets/app_alert.dart';
import '../widgets/community_chips.dart';
import '../widgets/community_scaffold.dart';
import 'user_profile_screen.dart';

/// MEMBER 3 - Search & Community
/// Post Details screen: full post body, like / bookmark actions and the
/// comment thread (add + list).
class PostDetailsScreen extends StatefulWidget {
  final int postId;
  final CommunityPost? post;

  const PostDetailsScreen({super.key, required this.postId, this.post});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  CommunityPost? _post;
  List<PostComment> _comments = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await CommunityService.postDetails(widget.postId);

    if (!mounted) return;

    if (result.success && result.data != null) {
      final data = result.data!;
      final rawPost = data['post'];
      final rawComments = data['comments'];

      setState(() {
        _post = rawPost is Map
            ? CommunityPost.fromJson(Map<String, dynamic>.from(rawPost))
            : _post;
        _comments = rawComments is List
            ? rawComments
                .whereType<Map>()
                .map((e) => PostComment.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : [];
        _loading = false;
      });
    } else {
      setState(() {
        _error = result.message;
        _loading = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    final post = _post;
    if (post == null) return;

    final result = await context.read<CommunityProvider>().toggleLike(post);
    if (result.success && result.data != null && mounted) {
      setState(() {
        _post = post.copyWith(
          isLiked: result.data![0] == 1,
          likesCount: result.data![1],
        );
      });
    }
  }

  Future<void> _toggleBookmark() async {
    final post = _post;
    if (post == null) return;

    final result = await context.read<CommunityProvider>().toggleBookmark(post);
    if (result.success && result.data != null && mounted) {
      setState(() => _post = post.copyWith(isBookmarked: result.data![0] == 1));
      await showInfoAlert(context, result.message, title: 'Community');
    }
  }

  Future<void> _addComment() async {
    final body = _commentController.text.trim();
    if (body.isEmpty) return;

    setState(() => _sending = true);

    final result = await CommunityService.addComment(widget.postId, body);

    if (!mounted) return;

    setState(() => _sending = false);

    if (result.success && result.data != null) {
      _commentController.clear();
      setState(() {
        _comments = [result.data!, ..._comments];
        final post = _post;
        if (post != null) {
          _post = post.copyWith(commentsCount: post.commentsCount + 1);
        }
      });
      FocusScope.of(context).unfocus();
    } else {
      await showErrorAlert(context, result.message, title: 'Comment Failed');
    }
  }

  Future<void> _deletePost() async {
    final provider = context.read<CommunityProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete post?',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will permanently remove the post and all of its comments.',
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
            child: Text('Delete',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await provider.deletePost(widget.postId);
    if (!mounted) return;

    if (result.success) {
      Navigator.of(context).pop(true);
    } else {
      await showErrorAlert(context, result.message, title: 'Could Not Delete');
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = _post;
    final currentUserId = context.watch<AuthProvider>().user?['id'];
    final isOwner = post != null && currentUserId != null && post.userId == currentUserId;

    return CommunityScaffold(
      title: 'Post',
      subtitle: post?.fandom,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _load,
        ),
        if (isOwner)
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor),
            onPressed: _deletePost,
          ),
      ],
      bottomBar: _buildCommentBar(),
      child: _loading && post == null
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.secondaryColor),
            )
          : _error != null && post == null
              ? CommunityEmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Could not load post',
                  message: _error!,
                  actionLabel: 'Retry',
                  onAction: _load,
                )
              : ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    if (post != null) ...[
                      // ----------------------- author row -----------------------
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    UserProfileScreen(userId: post.userId),
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: AppTheme.primaryColor,
                              child: Text(
                                post.authorInitial,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.authorName,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  post.createdAgo,
                                  style: GoogleFonts.inter(
                                    color: AppTheme.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (post.isDeepDive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.secondaryColor.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppTheme.secondaryColor
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                'DEEP DIVE',
                                style: GoogleFonts.inter(
                                  color: AppTheme.secondaryColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // --------------------- banner artwork ---------------------
                      CommunityBannerImage(
                        imageUrl: post.imageUrl,
                        fandom: post.fandom,
                        height: 180,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      const SizedBox(height: 18),

                      // -------------------------- title --------------------------
                      Text(
                        post.title,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ------------------------- content -------------------------
                      Text(
                        post.content,
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 14.5,
                          height: 1.65,
                        ),
                      ),

                      if (post.hashtagList.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: post.hashtagList
                              .map(
                                (tag) => Text(
                                  tag,
                                  style: GoogleFonts.inter(
                                    color: AppTheme.accentCyan,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // ------------------------ metrics ------------------------
                      Row(
                        children: [
                          _MetricChip(
                            icon: Icons.visibility_outlined,
                            label: '${post.viewsCount} views',
                          ),
                          const SizedBox(width: 10),
                          _MetricChip(
                            icon: Icons.mode_comment_outlined,
                            label: '${_comments.length} comments',
                          ),
                          if (post.rating > 0) ...[
                            const SizedBox(width: 10),
                            _MetricChip(
                              icon: Icons.star_rounded,
                              label: 'Depth ${post.rating}/5',
                              color: Colors.amber,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ------------------------- actions -------------------------
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _toggleLike,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: post.isLiked
                                      ? AppTheme.secondaryColor
                                      : Colors.white.withValues(alpha: 0.15),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                              ),
                              icon: Icon(
                                post.isLiked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 19,
                                color: post.isLiked
                                    ? AppTheme.secondaryColor
                                    : AppTheme.textSecondary,
                              ),
                              label: Text(
                                '${post.likesCount}',
                                style: GoogleFonts.inter(
                                  color: post.isLiked
                                      ? AppTheme.secondaryColor
                                      : AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _toggleBookmark,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: post.isBookmarked
                                      ? AppTheme.accentCyan
                                      : Colors.white.withValues(alpha: 0.15),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                              ),
                              icon: Icon(
                                post.isBookmarked
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_outline_rounded,
                                size: 19,
                                color: post.isBookmarked
                                    ? AppTheme.accentCyan
                                    : AppTheme.textSecondary,
                              ),
                              label: Text(
                                post.isBookmarked ? 'Saved' : 'Save',
                                style: GoogleFonts.inter(
                                  color: post.isBookmarked
                                      ? AppTheme.accentCyan
                                      : AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                    ],

                    // ------------------------- comments -------------------------
                    CommunitySectionTitle('Comments (${_comments.length})'),
                    const SizedBox(height: 12),
                    if (_comments.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Center(
                          child: Text(
                            'No comments yet. Be the first to reply!',
                            style: GoogleFonts.inter(
                              color: AppTheme.textMuted,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      )
                    else
                      ..._comments.map((comment) => _CommentTile(comment: comment)),
                  ],
                ),
    );
  }

  Widget _buildCommentBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _addComment(),
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  hintStyle: GoogleFonts.inter(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 46,
              width: 46,
              child: ElevatedButton(
                onPressed: _sending ? null : _addComment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _CommentTile extends StatelessWidget {
  final PostComment comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryDark,
            child: Text(
              comment.authorInitial,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.authorName,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      comment.createdAgo,
                      style: GoogleFonts.inter(
                        color: AppTheme.textMuted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  comment.body,
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetricChip({
    required this.icon,
    required this.label,
    this.color = AppTheme.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(color: color, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
