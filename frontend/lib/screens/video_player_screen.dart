import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/content_models.dart';
import '../providers/content_provider.dart';
import '../providers/profile_provider.dart';
import '../services/content_service.dart';
import '../theme/content_theme.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/app_image.dart';
import '../widgets/content_widgets.dart';
import 'fandom_hub_screen.dart';

/// MEMBER 2 - Video Player.
///
/// The SRS only requires fandom video *clips* to be browsable, and no media
/// hosting is in scope, so this screen implements a fully animated playback
/// preview: play / pause, seek, 10s skips, speed control, resume progress and
/// an "Up next" rail. The same screen also shows the description and tags.
class VideoPlayerScreen extends StatefulWidget {
  final ContentItem item;

  const VideoPlayerScreen({super.key, required this.item});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late ContentItem _item;
  ContentDetails? _details;

  Timer? _ticker;
  double _position = 0; // seconds
  bool _playing = false;
  bool _controlsVisible = true;
  double _speed = 1;

  bool _liked = false;
  bool _offline = false;

  int get _duration => _item.durationSeconds == 0 ? 120 : _item.durationSeconds;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _liked = widget.item.isLiked;
    _offline = widget.item.isOffline;
    _position = _duration * widget.item.progress.clamp(0.0, 1.0);
    _load();
    _recordView();
  }

  Future<void> _load() async {
    final result = await ContentService.details(_item.id);
    if (!mounted) return;
    setState(() {
      _details = result.data;
      if (result.data != null) {
        _item = result.data!.item;
        _liked = _item.isLiked;
        _offline = _item.isOffline;
      }
    });
  }

  Future<void> _recordView() async {
    final content = context.read<ContentProvider>();
    final profile = context.read<ProfileProvider>();

    await content.recordView(
      _item.id,
      progress: _duration == 0 ? 0 : _position / _duration,
    );
    profile.noteContentViewed(_item);
  }

  void _togglePlay() {
    setState(() => _playing = !_playing);

    if (_playing) {
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (!mounted) return;
        setState(() {
          _position += 0.5 * _speed;
          if (_position >= _duration) {
            _position = _duration.toDouble();
            _playing = false;
            _ticker?.cancel();
            _onFinished();
          }
        });
      });
      // auto-hide the controls while playing
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _playing) setState(() => _controlsVisible = false);
      });
    } else {
      _ticker?.cancel();
      _controlsVisible = true;
      _saveProgress();
    }
  }

  Future<void> _onFinished() async {
    await context.read<ContentProvider>().recordView(_item.id, progress: 1);
  }

  Future<void> _saveProgress() async {
    await context.read<ContentProvider>().recordView(
          _item.id,
          progress: (_position / _duration).clamp(0.0, 1.0),
        );
  }

  void _seekBy(double seconds) {
    setState(() {
      _position = (_position + seconds).clamp(0, _duration.toDouble());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = ContentTheme.fandomColor(_item.fandom);
    final related = (_details?.related ?? const <ContentItem>[])
        .where((element) => element.contentType == 'video')
        .toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ------------------------------------------------- player
            _buildPlayer(color),

            // ------------------------------------------------- details
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: ContentTheme.backgroundGradient,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
                  children: [
                    FadeSlideIn(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const TypeBadge(type: 'video'),
                              const SizedBox(width: 9),
                              FandomChip(fandom: _item.fandom),
                              const Spacer(),
                              MetaItem(
                                icon: Icons.visibility_rounded,
                                label: ContentTheme.compactCount(_item.viewsCount),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _item.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                _item.author.isEmpty ? 'Community clip' : _item.author,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (_item.publishedAgo.isNotEmpty)
                                Text(
                                  '· ${_item.publishedAgo}',
                                  style: const TextStyle(
                                    color: ContentTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              _ActionChip(
                                icon: _liked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                label: ContentTheme.compactCount(_item.likesCount),
                                active: _liked,
                                color: ContentTheme.rose,
                                onTap: () async {
                                  final liked =
                                      await context.read<ContentProvider>().toggleLike(_item);
                                  if (mounted) setState(() => _liked = liked);
                                },
                              ),
                              const SizedBox(width: 9),
                              _ActionChip(
                                icon: _offline
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                label: _offline ? 'Offline' : 'Save',
                                active: _offline,
                                color: ContentTheme.primary,
                                onTap: () async {
                                  final offline = await context
                                      .read<ContentProvider>()
                                      .toggleOffline(_item);
                                  if (mounted) setState(() => _offline = offline);
                                },
                              ),
                              const SizedBox(width: 9),
                              _ActionChip(
                                icon: Icons.speed_rounded,
                                label: '${_speed}x',
                                active: _speed != 1,
                                color: ContentTheme.secondary,
                                onTap: _cycleSpeed,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if ((_details?.paragraphs ?? const []).isNotEmpty) ...[
                      const SizedBox(height: 22),
                      ...List.generate(
                        _details!.paragraphs.length,
                        (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 13),
                          child: FadeSlideIn(
                            delay: Duration(milliseconds: 50 * (index % 5)),
                            child: Text(
                              _details!.paragraphs[index],
                              style: const TextStyle(
                                color: ContentTheme.textSecondary,
                                fontSize: 13.5,
                                height: 1.7,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (related.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const SectionHeader(
                        title: 'Up next',
                        subtitle: 'More clips from the hub',
                        accent: ContentTheme.violet,
                      ),
                      const SizedBox(height: 14),
                      ...related.map(
                        (item) => FadeSlideIn(
                          delay: const Duration(milliseconds: 50),
                          child: ContentRowTile(
                            item: item,
                            onTap: () => openContentItem(context, item),
                            trailing: const Icon(Icons.play_circle_outline_rounded,
                                color: ContentTheme.violet, size: 22),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _cycleSpeed() {
    final options = <double>[0.5, 1, 1.5, 2];
    final index = options.indexOf(_speed);
    setState(() => _speed = options[(index + 1) % options.length]);
  }

  Widget _buildPlayer(Color color) {
    final progress = _duration == 0 ? 0.0 : (_position / _duration).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => setState(() => _controlsVisible = !_controlsVisible),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AppImage(
              path: _item.artwork,
              fallbackColors: [color, ContentTheme.violet],
              fallbackIcon: Icons.play_circle_rounded,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(
                  alpha: _controlsVisible ? 0.32 : 0.18,
                ),
              ),
            ),

            // big play / pause button
            Center(
              child: AnimatedScale(
                duration: const Duration(milliseconds: 280),
                scale: _controlsVisible ? 1 : 0.75,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 240),
                  opacity: _controlsVisible ? 1 : 0,
                  child: PressScale(
                    onTap: _togglePlay,
                    pressedScale: 0.9,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.42),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.75),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        size: 34,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // top overlay
            Positioned(
              top: 6,
              left: 4,
              right: 8,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: _controlsVisible ? 1 : 0,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: Text(
                        _item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_speed}x',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // bottom controls
            Positioned(
              left: 10,
              right: 10,
              bottom: 6,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: _controlsVisible ? 1 : 0,
                child: Column(
                  children: [
                    Row(
                      children: [
                        _SkipButton(
                          icon: Icons.replay_10_rounded,
                          onTap: () => _seekBy(-10),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _format(_position.toInt()),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3,
                              activeTrackColor: ContentTheme.primary,
                              inactiveTrackColor: Colors.white24,
                              thumbColor: Colors.white,
                              thumbShape:
                                  const RoundSliderThumbShape(enabledThumbRadius: 6),
                              overlayShape:
                                  const RoundSliderOverlayShape(overlayRadius: 13),
                            ),
                            child: Slider(
                              value: _position.clamp(0, _duration.toDouble()),
                              max: _duration.toDouble(),
                              onChanged: (value) => setState(() => _position = value),
                              onChangeEnd: (_) => _saveProgress(),
                            ),
                          ),
                        ),
                        Text(
                          _format(_duration),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _SkipButton(
                          icon: Icons.forward_10_rounded,
                          onTap: () => _seekBy(10),
                        ),
                      ],
                    ),
                    // thin progress strip always visible
                    AnimatedProgressBar(
                      value: progress,
                      height: 3,
                      colors: const [ContentTheme.primary, ContentTheme.secondary],
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),

            // resume badge
            if (!_playing && _position > 0)
              Positioned(
                bottom: 46,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Resume from ${_format(_position.toInt())}',
                    style: const TextStyle(
                      color: ContentTheme.primary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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

class _SkipButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SkipButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      pressedScale: 0.88,
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      pressedScale: 0.93,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: active ? color.withValues(alpha: 0.55) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: active ? color : ContentTheme.textSecondary),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: active ? color : ContentTheme.textSecondary,
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
