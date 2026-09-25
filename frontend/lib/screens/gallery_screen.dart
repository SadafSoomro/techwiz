import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/content_models.dart';
import '../providers/content_provider.dart';
import '../services/content_service.dart';
import '../theme/content_theme.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/app_image.dart';
import '../widgets/content_widgets.dart';
import 'fandom_hub_screen.dart';

/// MEMBER 2 - Gallery list.
class GalleryScreen extends StatefulWidget {
  final String fandom;

  const GalleryScreen({super.key, this.fandom = 'all'});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContentProvider>().loadList(
            type: 'gallery',
            fandom: widget.fandom,
            sort: 'latest',
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContentProvider>();
    final items = provider.items;

    return ContentScaffold(
      title: 'Gallery',
      subtitle: 'Fan art, cosplay & convention shots',
      child: RefreshIndicator(
        onRefresh: () => provider.loadList(type: 'gallery', fandom: widget.fandom),
        color: ContentTheme.primary,
        backgroundColor: ContentTheme.card,
        child: items.isEmpty && provider.loadingList
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: ContentLoadingList(count: 3, imageHeight: 150),
              )
            : items.isEmpty
                ? ListView(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.18),
                      EmptyContentState(
                        title: 'No galleries yet',
                        message: provider.errorMessage ??
                            'Pull down to refresh, or run the content seeder.',
                        icon: Icons.photo_library_rounded,
                        actionLabel: 'Retry',
                        onAction: () =>
                            provider.loadList(type: 'gallery', fandom: widget.fandom),
                      ),
                    ],
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 13,
                      mainAxisSpacing: 13,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return FadeSlideIn(
                        delay: Duration(milliseconds: 55 * (index % 8)),
                        child: PressScale(
                          onTap: () => openContentItem(context, item),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Hero(
                                  tag: 'content-hero-${item.id}',
                                  child: AppImage(
                                    path: item.artwork,
                                    fallbackIcon: Icons.photo_library_rounded,
                                  ),
                                ),
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.85),
                                      ],
                                      stops: const [0.4, 1],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 10,
                                  left: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.photo_library_rounded,
                                            size: 11, color: Colors.white),
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
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          FandomChip(fandom: item.fandom, compact: true),
                                          const Spacer(),
                                          MetaItem(
                                            icon: Icons.photo_rounded,
                                            label: ContentTheme.compactCount(
                                                item.viewsCount),
                                            color: Colors.white60,
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
                      );
                    },
                  ),
      ),
    );
  }
}

/// MEMBER 2 - full screen Gallery viewer (swipe between shots).
class GalleryViewerScreen extends StatefulWidget {
  final ContentItem item;

  const GalleryViewerScreen({super.key, required this.item});

  @override
  State<GalleryViewerScreen> createState() => _GalleryViewerScreenState();
}

class _GalleryViewerScreenState extends State<GalleryViewerScreen> {
  final PageController _controller = PageController();
  List<ContentMedia> _media = [];
  int _index = 0;
  bool _loading = true;
  bool _liked = false;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _liked = widget.item.isLiked;
    _offline = widget.item.isOffline;
    _load();
    context.read<ContentProvider>().recordView(widget.item.id, progress: 0.5);
  }

  Future<void> _load() async {
    final result = await ContentService.details(widget.item.id);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _media = result.data?.media ?? [];
      _liked = result.data?.item.isLiked ?? _liked;
      _offline = result.data?.item.isOffline ?? _offline;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = ContentTheme.fandomColor(widget.item.fandom);
    final current = _media.isNotEmpty && _index < _media.length ? _media[_index] : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ------------------------------------------------ images
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: ContentTheme.primary),
            )
          else if (_media.isEmpty)
            Center(
              child: EmptyContentState(
                title: 'Gallery is empty',
                message: 'No images were found for this collection.',
                icon: Icons.image_not_supported_rounded,
              ),
            )
          else
            PageView.builder(
              controller: _controller,
              itemCount: _media.length,
              onPageChanged: (index) => setState(() => _index = index),
              itemBuilder: (context, index) => AnimatedScale(
                duration: const Duration(milliseconds: 320),
                scale: _index == index ? 1 : 0.92,
                child: Center(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 3,
                    child: Hero(
                      tag: index == 0
                          ? 'content-hero-${widget.item.id}'
                          : 'gallery-${widget.item.id}-$index',
                      child: AppImage(
                        path: _media[index].url,
                        fit: BoxFit.contain,
                        fallbackColors: [color, ContentTheme.primaryDark],
                        fallbackIcon: Icons.photo_rounded,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ------------------------------------------------ top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _media.isEmpty
                              ? 'Gallery'
                              : '${_index + 1} of ${_media.length}',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _offline ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      color: _offline ? ContentTheme.primary : Colors.white,
                    ),
                    onPressed: () async {
                      final provider = context.read<ContentProvider>();
                      final next = await provider.toggleOffline(widget.item);
                      if (mounted) setState(() => _offline = next);
                    },
                  ),
                ],
              ),
            ),
          ),

          // ------------------------------------------------ caption +
          // thumbnail strip
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 30, 18, 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.92),
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (current != null && current.caption.isNotEmpty)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        child: Text(
                          current.caption,
                          key: ValueKey(current.id),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        PressScale(
                          onTap: () async {
                            final provider = context.read<ContentProvider>();
                            final liked = await provider.toggleLike(widget.item);
                            if (mounted) setState(() => _liked = liked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: _liked
                                  ? ContentTheme.rose.withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: _liked
                                    ? ContentTheme.rose.withValues(alpha: 0.6)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _liked
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  size: 17,
                                  color: _liked ? ContentTheme.rose : Colors.white,
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  ContentTheme.compactCount(widget.item.likesCount),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${ContentTheme.compactCount(widget.item.viewsCount)} views',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Icon(Icons.swipe_rounded, size: 16, color: Colors.white54),
                        const SizedBox(width: 6),
                        const Text(
                          'Swipe',
                          style: TextStyle(color: Colors.white54, fontSize: 11.5),
                        ),
                      ],
                    ),
                    if (_media.length > 1) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 52,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _media.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) => PressScale(
                            pressedScale: 0.9,
                            onTap: () => _controller.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 320),
                              curve: Curves.easeOutCubic,
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 240),
                              width: 58,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(11),
                                border: Border.all(
                                  color: _index == index
                                      ? ContentTheme.primary
                                      : Colors.white24,
                                  width: _index == index ? 2 : 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: AppImage(
                                  path: _media[index].url,
                                  showFade: false,
                                  fallbackColors: [color, ContentTheme.primaryDark],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
