import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/content_models.dart';
import '../providers/content_provider.dart';
import '../providers/profile_provider.dart';
import '../services/content_service.dart';
import '../theme/content_theme.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/app_alert.dart';
import '../widgets/app_image.dart';
import '../widgets/content_widgets.dart';
import 'fandom_hub_screen.dart';

/// MEMBER 2 - News Details (also used for articles and Deep Dive stories).
class NewsDetailsScreen extends StatefulWidget {
  final ContentItem item;

  const NewsDetailsScreen({super.key, required this.item});

  @override
  State<NewsDetailsScreen> createState() => _NewsDetailsScreenState();
}

class _NewsDetailsScreenState extends State<NewsDetailsScreen> {
  late ContentItem _item;
  ContentDetails? _details;
  bool _loading = true;
  bool _liking = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _load();
    _trackView();
  }

  Future<void> _load() async {
    final result = await ContentService.details(_item.id);
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (result.success && result.data != null) {
        _details = result.data;
        _item = result.data!.item;
      } else {
        _error = result.message;
      }
    });
  }

  Future<void> _trackView() async {
    final content = context.read<ContentProvider>();
    final profile = context.read<ProfileProvider>();

    await content.recordView(_item.id, progress: 0.35);
    profile.noteContentViewed(_item);
  }

  Future<void> _toggleLike() async {
    setState(() => _liking = true);
    final provider = context.read<ContentProvider>();
    final liked = await provider.toggleLike(_item);
    if (!mounted) return;
    setState(() {
      _item = _item.copyWith(
        isLiked: liked,
        likesCount: liked ? _item.likesCount + 1 : _item.likesCount - 1,
      );
      _liking = false;
    });
  }

  Future<void> _toggleOffline() async {
    setState(() => _saving = true);
    final provider = context.read<ContentProvider>();
    final offline = await provider.toggleOffline(_item);
    if (!mounted) return;
    setState(() {
      _item = _item.copyWith(isOffline: offline);
      _saving = false;
    });

    if (offline) {
      await showSuccessAlert(
        context,
        'Saved for offline reading',
        title: 'Offline',
        accent: ContentTheme.primary,
      );
    } else {
      await showInfoAlert(
        context,
        'Removed from offline content',
        title: 'Offline',
        accent: ContentTheme.primary,
      );
    }
  }

  Future<void> _share() async {
    final text = '${_item.title}\n\n${_item.summary}\n\n— via FANDOM VERSE';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;

    await showInfoAlert(
      context,
      'Story details copied to clipboard',
      title: 'Link Copied',
      accent: ContentTheme.primary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = ContentTheme.fandomColor(_item.fandom);
    final paragraphs = _details?.paragraphs ?? const <String>[];
    final related = _details?.related ?? const <ContentItem>[];

    return Scaffold(
      backgroundColor: ContentTheme.background,
      bottomNavigationBar: _buildBottomBar(),
      body: Container(
        decoration: const BoxDecoration(gradient: ContentTheme.backgroundGradient),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 264,
              backgroundColor: ContentTheme.background,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                  onPressed: _share,
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Hero(
                  tag: 'content-hero-${_item.id}',
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppImage(
                        path: _item.artwork,
                        fallbackColors: [color, ContentTheme.primaryDark],
                        fallbackIcon: ContentTheme.fandomIcon(_item.fandom),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.3),
                              Colors.black.withValues(alpha: 0.92),
                            ],
                            stops: const [0.2, 1],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeSlideIn(
                      child: Row(
                        children: [
                          TypeBadge(type: _item.contentType),
                          const SizedBox(width: 9),
                          FandomChip(fandom: _item.fandom),
                          const Spacer(),
                          if (_item.publishedAgo.isNotEmpty)
                            MetaItem(
                              icon: Icons.schedule_rounded,
                              label: _item.publishedAgo,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 60),
                      child: Text(
                        _item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                        ),
                      ),
                    ),
                    if (_item.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 90),
                        child: Text(
                          _item.subtitle,
                          style: TextStyle(
                            color: color,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 110),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              gradient: ContentTheme.headerGradient,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_rounded,
                                size: 13, color: Colors.white),
                          ),
                          const SizedBox(width: 9),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _item.author.isEmpty ? 'Fandom Verse Desk' : _item.author,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (_item.source.isNotEmpty)
                                Text(
                                  _item.source,
                                  style: const TextStyle(
                                    color: ContentTheme.textMuted,
                                    fontSize: 10.5,
                                  ),
                                ),
                            ],
                          ),
                          const Spacer(),
                          MetaItem(
                            icon: Icons.visibility_rounded,
                            label: '${ContentTheme.compactCount(_item.viewsCount)} reads',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.07),
                    ),
                    const SizedBox(height: 18),
                    if (_item.summary.isNotEmpty)
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 130),
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.09),
                            borderRadius: BorderRadius.circular(16),
                            border: Border(left: BorderSide(color: color, width: 3)),
                          ),
                          child: Text(
                            _item.summary,
                            style: const TextStyle(
                              color: ContentTheme.textPrimary,
                              fontSize: 13.5,
                              height: 1.55,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (_loading)
              const SliverPadding(
                padding: EdgeInsets.all(20),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Shimmer(height: 13),
                      SizedBox(height: 10),
                      Shimmer(height: 13),
                      SizedBox(height: 10),
                      Shimmer(height: 13, width: 220),
                    ],
                  ),
                ),
              )
            else if (_error != null && paragraphs.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: ContentTheme.textSecondary),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: FadeSlideIn(
                        delay: Duration(milliseconds: 60 * (index % 6)),
                        child: Text(
                          paragraphs[index],
                          style: const TextStyle(
                            color: ContentTheme.textSecondary,
                            fontSize: 14.5,
                            height: 1.75,
                          ),
                        ),
                      ),
                    ),
                    childCount: paragraphs.length,
                  ),
                ),
              ),
            if (_item.tagsList.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _item.tagsList
                        .map(
                          (tag) => Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                            decoration: BoxDecoration(
                              color: ContentTheme.card,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.07),
                              ),
                            ),
                            child: Text(
                              '#$tag',
                              style: const TextStyle(
                                color: ContentTheme.textSecondary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            if (related.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        title: 'Read more',
                        subtitle: 'More from this fandom',
                        accent: ContentTheme.primary,
                      ),
                      const SizedBox(height: 12),
                      ...related.map(
                        (item) => FadeSlideIn(
                          delay: const Duration(milliseconds: 50),
                          child: ContentRowTile(
                            item: item,
                            onTap: () => openContentItem(context, item),
                            trailing: const Icon(Icons.chevron_right_rounded,
                                color: ContentTheme.textMuted, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: ContentTheme.card,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _BottomAction(
              icon: _item.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              label: ContentTheme.compactCount(_item.likesCount),
              active: _item.isLiked,
              busy: _liking,
              color: ContentTheme.rose,
              onTap: _toggleLike,
            ),
            const SizedBox(width: 10),
            _BottomAction(
              icon: _item.isOffline
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              label: _item.isOffline ? 'Offline' : 'Save',
              active: _item.isOffline,
              busy: _saving,
              color: ContentTheme.primary,
              onTap: _toggleOffline,
            ),
            const SizedBox(width: 10),
            _BottomAction(
              icon: Icons.share_rounded,
              label: 'Share',
              active: false,
              color: ContentTheme.secondary,
              onTap: _share,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PressScale(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FandomHubScreen(
                      embedded: false,
                    ),
                  ),
                ),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: ContentTheme.headerGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      'Fandom Hub',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
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

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool busy;
  final Color color;
  final VoidCallback onTap;

  const _BottomAction({
    required this.icon,
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: busy ? null : onTap,
      pressedScale: 0.92,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: active ? color.withValues(alpha: 0.55) : Colors.transparent,
          ),
        ),
        child: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Column(
                children: [
                  Icon(icon, size: 19, color: active ? color : ContentTheme.textSecondary),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      color: active ? color : ContentTheme.textSecondary,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
