import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/community_models.dart';
import '../providers/community_provider.dart';
import '../services/community_service.dart';
import '../theme/app_theme.dart';
import '../widgets/community_chips.dart';
import '../widgets/community_post_card.dart';
import '../widgets/community_scaffold.dart';
import 'post_details_screen.dart';

/// MEMBER 3 - Search & Community
/// Public user profile: avatar, bio, follower stats, fandoms and posts.
class UserProfileScreen extends StatefulWidget {
  final int userId;
  final String? userName;

  const UserProfileScreen({super.key, required this.userId, this.userName});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  CommunityUser? _user;
  List<FandomCategory> _fandoms = [];
  List<CommunityPost> _posts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await CommunityService.userProfile(widget.userId);

    if (!mounted) return;

    if (result.success && result.data != null) {
      final data = result.data!;
      final rawUser = data['user'];
      final rawFandoms = data['fandoms'];
      final rawPosts = data['posts'];

      setState(() {
        _user = rawUser is Map
            ? CommunityUser.fromJson(Map<String, dynamic>.from(rawUser))
            : null;

        _fandoms = rawFandoms is List
            ? rawFandoms
                .whereType<Map>()
                .map((e) => FandomCategory.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : [];

        _posts = rawPosts is List
            ? rawPosts
                .whereType<Map>()
                .map((e) => CommunityPost.fromJson(Map<String, dynamic>.from(e)))
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

  Future<void> _toggleFollow() async {
    final user = _user;
    if (user == null) return;

    final result = await context.read<CommunityProvider>().toggleFollow(user);
    if (!mounted) return;

    if (result.success && result.data != null) {
      setState(() {
        _user = user.copyWith(
          isFollowing: result.data![0] == 1,
          followersCount: result.data![1],
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 1),
          backgroundColor: AppTheme.cardColorLight,
          content: Text(
            result.message,
            style: GoogleFonts.inter(color: Colors.white),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.errorColor,
          content: Text(result.message,
              style: GoogleFonts.inter(color: Colors.white)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;

    return CommunityScaffold(
      title: widget.userName ?? user?.name ?? 'Profile',
      subtitle: user?.joinedAgo.isNotEmpty == true
          ? 'Joined ${user!.joinedAgo}'
          : 'Community member',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _load,
        ),
      ],
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.secondaryColor),
            )
          : user == null
              ? CommunityEmptyState(
                  icon: Icons.person_off_outlined,
                  title: 'Profile unavailable',
                  message: _error ?? 'This user could not be loaded.',
                  actionLabel: 'Retry',
                  onAction: _load,
                )
              : RefreshIndicator(
                  color: AppTheme.secondaryColor,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      // ------------------------- header -------------------------
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.buttonGradient,
                          ),
                          child: CircleAvatar(
                            radius: 44,
                            backgroundColor: AppTheme.cardColor,
                            child: Text(
                              user.initial,
                              style: GoogleFonts.outfit(
                                fontSize: 38,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: Text(
                          user.name,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (user.bio.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              user.bio,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),

                      // ------------------------- follow -------------------------
                      Center(
                        child: SizedBox(
                          width: 190,
                          height: 44,
                          child: user.isFollowing
                              ? OutlinedButton.icon(
                                  onPressed: _toggleFollow,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: Colors.white.withValues(alpha: 0.2),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.check_rounded,
                                      size: 18, color: AppTheme.textSecondary),
                                  label: Text(
                                    'Following',
                                    style: GoogleFonts.inter(
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              : ElevatedButton.icon(
                                  onPressed: _toggleFollow,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.person_add_alt_1_rounded,
                                      size: 18, color: Colors.white),
                                  label: Text(
                                    'Follow',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // -------------------------- stats -------------------------
                      Row(
                        children: [
                          CommunityStatTile(
                            icon: Icons.people_alt_rounded,
                            label: 'Followers',
                            value: '${user.followersCount}',
                            color: AppTheme.accentCyan,
                          ),
                          const SizedBox(width: 10),
                          CommunityStatTile(
                            icon: Icons.person_pin_circle_rounded,
                            label: 'Following',
                            value: '${user.followingCount}',
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 10),
                          CommunityStatTile(
                            icon: Icons.article_rounded,
                            label: 'Posts',
                            value: '${user.postsCount}',
                            color: AppTheme.secondaryColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          CommunityStatTile(
                            icon: Icons.favorite_rounded,
                            label: 'Likes earned',
                            value: '${user.totalLikes}',
                            color: AppTheme.secondaryColor,
                          ),
                          const SizedBox(width: 10),
                          CommunityStatTile(
                            icon: Icons.auto_awesome_rounded,
                            label: 'Fandoms',
                            value: '${_fandoms.length}',
                            color: Colors.amber,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ------------------------- fandoms -------------------------
                      if (_fandoms.isNotEmpty) ...[
                        const CommunitySectionTitle('Fandoms'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _fandoms
                              .map(
                                (f) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.08),
                                    ),
                                  ),
                                  child: Text(
                                    f.hashtag.isNotEmpty ? f.hashtag : f.name,
                                    style: GoogleFonts.inter(
                                      color: AppTheme.accentCyan,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // --------------------------- posts ---------------------------
                      CommunitySectionTitle('Posts (${_posts.length})'),
                      const SizedBox(height: 10),
                      if (_posts.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'No posts yet.',
                              style: GoogleFonts.inter(
                                color: AppTheme.textMuted,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        )
                      else
                        ..._posts.map(
                          (post) => CommunityPostCard(
                            post: post,
                            compact: true,
                            showBookmarkAction: false,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PostDetailsScreen(
                                  postId: post.id,
                                  post: post,
                                ),
                              ),
                            ),
                            onLike: () => context
                                .read<CommunityProvider>()
                                .toggleLike(post),
                            onComment: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PostDetailsScreen(
                                  postId: post.id,
                                  post: post,
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
