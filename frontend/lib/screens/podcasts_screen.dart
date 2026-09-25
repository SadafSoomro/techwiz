import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/content_models.dart';
import '../providers/content_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/content_theme.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/app_image.dart';
import '../widgets/content_widgets.dart';

/// MEMBER 2 - Podcasts ("Latest Episodes").
///
/// Lists podcast episodes and plays them in an animated mini player docked to
/// the bottom of the screen (waveform, scrubber, speed and queue controls).
class PodcastsScreen extends StatefulWidget {
  final String fandom;
  final ContentItem? initialItem;

  const PodcastsScreen({super.key, this.fandom = 'all', this.initialItem});

  @override
  State<PodcastsScreen> createState() => _PodcastsScreenState();
}

class _PodcastsScreenState extends State<PodcastsScreen> {
  ContentItem? _current;
  Timer? _ticker;
  double _position = 0;
  bool _playing = false;
  double _speed = 1;

  int get _duration => _current?.durationSeconds == 0 || _current == null
      ? 600
      : _current!.durationSeconds;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContentProvider>().loadList(
            type: 'podcast',
            fandom: widget.fandom,
            sort: 'latest',
          );
      if (widget.initialItem != null) _play(widget.initialItem!);
    });
  }

  Future<void> _play(ContentItem item) async {
    setState(() {
      _current = item;
      _position = item.durationSeconds * item.progress.clamp(0.0, 1.0);
      _playing = true;
    });

    final content = context.read<ContentProvider>();
    final profile = context.read<ProfileProvider>();
    await content.recordView(item.id, progress: _duration == 0 ? 0 : _position / _duration);
    profile.noteContentViewed(item);

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      setState(() {
        _position += 0.5 * _speed;
        if (_position >= _duration) {
          _position = 0;
          _playing = false;
          _ticker?.cancel();
        }
      });
    });
  }

  void _toggle() {
    if (_current == null) return;
    if (_playing) {
      _ticker?.cancel();
      setState(() => _playing = false);
      context.read<ContentProvider>().recordView(
            _current!.id,
            progress: (_position / _duration).clamp(0.0, 1.0),
          );
    } else {
      setState(() => _playing = true);
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (!mounted) return;
        setState(() {
          _position += 0.5 * _speed;
          if (_position >= _duration) {
            _position = 0;
            _playing = false;
            _ticker?.cancel();
          }
        });
      });
    }
  }

  void _skip(double seconds) {
    setState(() =>
        _position = (_position + seconds).clamp(0.0, _duration.toDouble()));
  }

  void _cycleSpeed() {
    final options = <double>[0.75, 1, 1.25, 1.5, 2];
    final index = options.indexOf(_speed);
    setState(() => _speed = options[(index + 1) % options.length]);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContentProvider>();
    final items = provider.items;

    return ContentScaffold(
      title: 'Podcasts',
      subtitle: 'Latest Episodes',
      bottomBar: _current == null ? null : _buildMiniPlayer(),
      child: RefreshIndicator(
        onRefresh: () => provider.loadList(type: 'podcast', fandom: widget.fandom),
        color: ContentTheme.primary,
        backgroundColor: ContentTheme.card,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
                child: FadeSlideIn(child: _buildHero()),
              ),
            ),
            if (provider.loadingList && items.isEmpty)
              const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                sliver: SliverToBoxAdapter(child: ContentLoadingList(count: 3, imageHeight: 96)),
              )
            else if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyContentState(
                  title: 'No episodes yet',
                  message: provider.errorMessage ?? 'Pull down to refresh.',
                  icon: Icons.podcasts_rounded,
                  actionLabel: 'Retry',
                  onAction: () =>
                      provider.loadList(type: 'podcast', fandom: widget.fandom),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 30),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = items[index];
                      return FadeSlideIn(
                        delay: Duration(milliseconds: 55 * (index % 8)),
                        child: PodcastTile(
                          item: item,
                          playing: _current?.id == item.id && _playing,
                          onTap: () => _play(item),
                          onPlay: () =>
                              _current?.id == item.id ? _toggle() : _play(item),
                        ),
                      );
                    },
                    childCount: items.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: ContentTheme.podcastGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ContentTheme.violet.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.podcasts_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FANDOM VERSE PODCAST',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.3,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Deep dives, lore and\nfandom culture every week.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const AnimatedWaveform(playing: true, bars: 9, height: 40, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildMiniPlayer() {
    final item = _current!;
    final progress = _duration == 0 ? 0.0 : (_position / _duration).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: ContentTheme.cardAlt,
        border: Border(top: BorderSide(color: ContentTheme.primary.withValues(alpha: 0.3))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedProgressBar(
              value: progress,
              height: 4,
              colors: const [ContentTheme.primary, ContentTheme.secondary],
              duration: const Duration(milliseconds: 320),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                AppImage(
                  path: item.artwork,
                  height: 44,
                  width: 44,
                  borderRadius: BorderRadius.circular(11),
                  fallbackColors: const [ContentTheme.violet, ContentTheme.secondary],
                  fallbackIcon: Icons.podcasts_rounded,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${_format(_position.toInt())} / ${_format(_duration)}'
                        '${item.episodeLabel.isEmpty ? '' : ' · ${item.episodeLabel}'}',
                        style: const TextStyle(
                          color: ContentTheme.textMuted,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                PressScale(
                  onTap: _cycleSpeed,
                  pressedScale: 0.9,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: ContentTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      '${_speed}x',
                      style: const TextStyle(
                        color: ContentTheme.primary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.replay_10_rounded,
                      color: Colors.white70, size: 22),
                  onPressed: () => _skip(-10),
                ),
                const SizedBox(width: 8),
                PressScale(
                  onTap: _toggle,
                  pressedScale: 0.88,
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: const BoxDecoration(
                      gradient: ContentTheme.headerGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.forward_10_rounded,
                      color: Colors.white70, size: 22),
                  onPressed: () => _skip(10),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close_rounded,
                      color: ContentTheme.textMuted, size: 20),
                  onPressed: () {
                    _ticker?.cancel();
                    setState(() {
                      _playing = false;
                      _current = null;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _format(int seconds) {
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    return '$minutes:${rest.toString().padLeft(2, '0')}';
  }
}
