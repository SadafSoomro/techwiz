import 'package:flutter/material.dart';

import '../models/content_models.dart';
import '../theme/content_theme.dart';
import 'animated_widgets.dart';
import 'app_image.dart';

/// MEMBER 2 - Fandom Content
/// Reusable cards and tiles used by the hub / news / gallery / video /
/// podcast / discover screens.

// ---------------------------------------------------------------------------
// scaffold
// ---------------------------------------------------------------------------
class ContentScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;
  final Widget? floatingActionButton;
  final Widget? bottomBar;
  final bool showBackButton;
  final Widget? header;

  const ContentScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.floatingActionButton,
    this.bottomBar,
    this.showBackButton = true,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ContentTheme.background,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomBar,
      body: Container(
        decoration: const BoxDecoration(gradient: ContentTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
                child: Row(
                  children: [
                    if (showBackButton)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        onPressed: () => Navigator.of(context).maybePop(),
                      )
                    else
                      const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              style: const TextStyle(
                                color: ContentTheme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    ...actions,
                  ],
                ),
              ),
              ?header,
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// small pieces
// ---------------------------------------------------------------------------

/// "NEWS" / "VIDEO" / "PODCAST" style badge.
class TypeBadge extends StatelessWidget {
  final String type;
  final bool solid;
  final double fontSize;

  const TypeBadge({super.key, required this.type, this.solid = true, this.fontSize = 9.5});

  @override
  Widget build(BuildContext context) {
    final color = ContentTheme.contentTypeColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: solid ? color : Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(9),
        border: solid ? null : Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ContentTheme.contentTypeIcon(type),
            size: fontSize + 3,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            ContentTheme.contentTypeLabel(type),
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fandom chip (#Anime) coloured by its fandom.
class FandomChip extends StatelessWidget {
  final String fandom;
  final bool compact;

  const FandomChip({super.key, required this.fandom, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (fandom.isEmpty) return const SizedBox.shrink();
    final color = ContentTheme.fandomColor(fandom);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 9, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '#$fandom',
        style: TextStyle(
          color: color,
          fontSize: compact ? 9.5 : 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Small icon + label meta item ("18.4K views").
class MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const MetaItem({
    super.key,
    required this.icon,
    required this.label,
    this.color = ContentTheme.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12.5, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 11)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// news / article card (full width)
// ---------------------------------------------------------------------------
class ContentCard extends StatelessWidget {
  final ContentItem item;
  final VoidCallback? onTap;
  final VoidCallback? onBookmark;
  final bool showSummary;
  final double imageHeight;

  const ContentCard({
    super.key,
    required this.item,
    this.onTap,
    this.onBookmark,
    this.showSummary = true,
    this.imageHeight = 158,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: ContentTheme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AppImage(
                  path: item.artwork,
                  height: imageHeight,
                  width: double.infinity,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  fallbackColors: [
                    ContentTheme.fandomColor(item.fandom),
                    ContentTheme.primaryDark,
                  ],
                  fallbackIcon: ContentTheme.fandomIcon(item.fandom),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: TypeBadge(type: item.contentType, solid: false),
                ),
                if (item.durationLabel.isNotEmpty)
                  Positioned(
                    bottom: 10,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.durationLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 10,
                  right: 8,
                  child: PressScale(
                    onTap: onBookmark,
                    pressedScale: 0.85,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.isOffline
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 17,
                        color: item.isOffline
                            ? ContentTheme.primary
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 13, 15, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ContentTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  if (showSummary && item.summary.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ContentTheme.textSecondary,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FandomChip(fandom: item.fandom, compact: true),
                      const SizedBox(width: 8),
                      if (item.publishedAgo.isNotEmpty)
                        MetaItem(icon: Icons.schedule_rounded, label: item.publishedAgo),
                      const Spacer(),
                      MetaItem(
                        icon: Icons.visibility_rounded,
                        label: ContentTheme.compactCount(item.viewsCount),
                      ),
                      const SizedBox(width: 10),
                      MetaItem(
                        icon: item.isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        label: ContentTheme.compactCount(item.likesCount),
                        color: item.isLiked ? ContentTheme.rose : ContentTheme.textMuted,
                      ),
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

// ---------------------------------------------------------------------------
// compact row tile (news list / recent / offline)
// ---------------------------------------------------------------------------
class ContentRowTile extends StatelessWidget {
  final ContentItem item;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ContentRowTile({super.key, required this.item, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: ContentTheme.card,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                AppImage(
                  path: item.artwork,
                  height: 76,
                  width: 76,
                  borderRadius: BorderRadius.circular(13),
                  fallbackColors: [
                    ContentTheme.fandomColor(item.fandom),
                    ContentTheme.primaryDark,
                  ],
                  fallbackIcon: ContentTheme.fandomIcon(item.fandom),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(13),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        ContentTheme.contentTypeIcon(item.contentType),
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ContentTheme.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      FandomChip(fandom: item.fandom, compact: true),
                      const SizedBox(width: 6),
                      if (item.publishedAgo.isNotEmpty)
                        Text(
                          item.publishedAgo,
                          style: const TextStyle(
                            color: ContentTheme.textMuted,
                            fontSize: 10.5,
                          ),
                        ),
                    ],
                  ),
                  if (item.durationLabel.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.play_circle_outline_rounded,
                            size: 13, color: ContentTheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          item.episodeLabel.isEmpty
                              ? item.durationLabel
                              : '${item.episodeLabel} · ${item.durationLabel}',
                          style: const TextStyle(
                            color: ContentTheme.primary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// video still (16:9)
// ---------------------------------------------------------------------------
class VideoStillCard extends StatelessWidget {
  final ContentItem item;
  final VoidCallback? onTap;
  final double width;

  const VideoStillCard({super.key, required this.item, this.onTap, this.width = 232});

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                AppImage(
                  path: item.artwork,
                  height: width * 0.56,
                  width: width,
                  borderRadius: BorderRadius.circular(16),
                  fallbackColors: [
                    ContentTheme.fandomColor(item.fandom),
                    ContentTheme.violet,
                  ],
                  fallbackIcon: Icons.play_circle_rounded,
                ),
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.6),
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                ),
                if (item.durationLabel.isNotEmpty)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        item.durationLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                if (item.progress > 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                      child: AnimatedProgressBar(
                        value: item.progress,
                        height: 3,
                        colors: const [ContentTheme.primary, ContentTheme.secondary],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ContentTheme.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                FandomChip(fandom: item.fandom, compact: true),
                const SizedBox(width: 7),
                Text(
                  ContentTheme.compactCount(item.viewsCount),
                  style: const TextStyle(color: ContentTheme.textMuted, fontSize: 10.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// podcast tile
// ---------------------------------------------------------------------------
class PodcastTile extends StatelessWidget {
  final ContentItem item;
  final bool playing;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;

  const PodcastTile({
    super.key,
    required this.item,
    this.playing = false,
    this.onTap,
    this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: playing ? ContentTheme.cardAlt : ContentTheme.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: playing
                ? ContentTheme.primary.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.06),
            width: playing ? 1.4 : 1,
          ),
          boxShadow: playing
              ? [
                  BoxShadow(
                    color: ContentTheme.primary.withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            AppImage(
              path: item.artwork,
              height: 74,
              width: 74,
              borderRadius: BorderRadius.circular(15),
              fallbackColors: const [ContentTheme.violet, ContentTheme.secondary],
              fallbackIcon: Icons.podcasts_rounded,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.episodeLabel.isNotEmpty)
                    Text(
                      item.episodeLabel.toUpperCase(),
                      style: const TextStyle(
                        color: ContentTheme.primary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  const SizedBox(height: 3),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ContentTheme.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 7),
                  if (playing)
                    AnimatedWaveform(playing: true, bars: 18, height: 20)
                  else
                    Row(
                      children: [
                        FandomChip(fandom: item.fandom, compact: true),
                        const SizedBox(width: 7),
                        if (item.durationLabel.isNotEmpty)
                          Text(
                            item.durationLabel,
                            style: const TextStyle(
                              color: ContentTheme.textMuted,
                              fontSize: 10.5,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PressScale(
              onTap: onPlay,
              pressedScale: 0.88,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: playing ? ContentTheme.podcastGradient : null,
                  color: playing ? null : Colors.white.withValues(alpha: 0.07),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// gallery tile
// ---------------------------------------------------------------------------
class GalleryTile extends StatelessWidget {
  final String imageUrl;
  final String caption;
  final VoidCallback? onTap;
  final double height;
  final int? index;

  const GalleryTile({
    super.key,
    required this.imageUrl,
    this.caption = '',
    this.onTap,
    this.height = 150,
    this.index,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      pressedScale: 0.95,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AppImage(path: imageUrl, fallbackIcon: Icons.photo_rounded),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                    stops: const [0.45, 1],
                  ),
                ),
              ),
              if (index != null)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      '${index! + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              if (caption.isNotEmpty)
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 9,
                  child: Text(
                    caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
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
// fandom hub card (Explore Fandoms / trending carousel)
// ---------------------------------------------------------------------------
class FandomHubCard extends StatelessWidget {
  final FandomHub hub;
  final VoidCallback? onTap;
  final double height;
  final double width;

  const FandomHubCard({
    super.key,
    required this.hub,
    this.onTap,
    this.height = 162,
    this.width = 250,
  });

  @override
  Widget build(BuildContext context) {
    final color = ContentTheme.fandomColor(hub.name);

    return PressScale(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AppImage(
                path: hub.imageUrl,
                fallbackColors: [color, ContentTheme.primaryDark],
                fallbackIcon: ContentTheme.fandomIcon(hub.name),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.82),
                    ],
                    stops: const [0.35, 1],
                  ),
                ),
              ),
              if (hub.isTrending)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ContentTheme.rose,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Row(
                      children: [
                        PulseDot(color: Colors.white, size: 6),
                        SizedBox(width: 5),
                        Text(
                          'TRENDING',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 13,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hub.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (hub.tagline.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          hub.tagline,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        MetaItem(
                          icon: Icons.article_rounded,
                          label: '${hub.itemsCount} items',
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 12),
                        MetaItem(
                          icon: Icons.visibility_rounded,
                          label: ContentTheme.compactCount(hub.totalViews),
                          color: Colors.white70,
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
  }
}

// ---------------------------------------------------------------------------
// section skeleton + empty states
// ---------------------------------------------------------------------------
class ContentLoadingList extends StatelessWidget {
  final int count;
  final double imageHeight;

  const ContentLoadingList({super.key, this.count = 3, this.imageHeight = 130});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: ShimmerCard(imageHeight: imageHeight),
        ),
      ),
    );
  }
}

class EmptyContentState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyContentState({
    super.key,
    required this.title,
    this.message = '',
    this.icon = Icons.explore_off_rounded,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: ContentTheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 42, color: ContentTheme.primary),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: ContentTheme.textSecondary, fontSize: 13),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ContentTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
