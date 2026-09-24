import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/community_models.dart';
import '../theme/app_theme.dart';
import 'community_banner_image.dart';

/// MEMBER 3 - Search & Community
/// Reusable post card used by Search results, Trending, Discussions,
/// Bookmarks and the user profile screen.
class CommunityPostCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback? onTap;
  final VoidCallback? onAuthorTap;
  final VoidCallback? onLike;
  final VoidCallback? onBookmark;
  final VoidCallback? onComment;
  final bool showBookmarkAction;
  final bool compact;

  const CommunityPostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onAuthorTap,
    this.onLike,
    this.onBookmark,
    this.onComment,
    this.showBookmarkAction = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: post.isDeepDive
              ? AppTheme.secondaryColor.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ------------------------ header ------------------------
                Row(
                  children: [
                    GestureDetector(
                      onTap: onAuthorTap,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTheme.primaryColor,
                        child: Text(
                          post.authorInitial,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: onAuthorTap,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.authorName,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${post.fandom}  ·  ${post.createdAgo}',
                              style: GoogleFonts.inter(
                                color: AppTheme.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (post.isDeepDive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.secondaryColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              size: 12,
                              color: AppTheme.secondaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'DEEP DIVE',
                              style: GoogleFonts.inter(
                                color: AppTheme.secondaryColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // --------------------- banner artwork ---------------------
                CommunityBannerImage(
                  imageUrl: post.imageUrl,
                  fandom: post.fandom,
                  height: compact ? 92 : 138,
                ),
                const SizedBox(height: 14),

                // ------------------------- body --------------------------
                Text(
                  post.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  post.content,
                  maxLines: compact ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),

                if (post.hashtagList.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: post.hashtagList
                        .take(4)
                        .map(
                          (tag) => Text(
                            tag,
                            style: GoogleFonts.inter(
                              color: AppTheme.accentCyan,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],

                const SizedBox(height: 12),
                Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
                const SizedBox(height: 6),

                // ------------------------ actions ------------------------
                Row(
                  children: [
                    _ActionButton(
                      icon: post.isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      label: '${post.likesCount}',
                      color: post.isLiked
                          ? AppTheme.secondaryColor
                          : AppTheme.textMuted,
                      onTap: onLike,
                    ),
                    _ActionButton(
                      icon: Icons.mode_comment_outlined,
                      label: '${post.commentsCount}',
                      color: AppTheme.textMuted,
                      onTap: onComment ?? onTap,
                    ),
                    _ActionButton(
                      icon: Icons.visibility_outlined,
                      label: '${post.viewsCount}',
                      color: AppTheme.textMuted,
                      onTap: null,
                    ),
                    const Spacer(),
                    if (showBookmarkAction)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          post.isBookmarked
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_outline_rounded,
                          color: post.isBookmarked
                              ? AppTheme.accentCyan
                              : AppTheme.textMuted,
                        ),
                        onPressed: onBookmark,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
