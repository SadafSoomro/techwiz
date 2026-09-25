import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/community_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_alert.dart';
import '../widgets/community_chips.dart';
import '../widgets/community_scaffold.dart';

/// MEMBER 3 - Search & Community
/// Create Post screen - used for normal community posts and for
/// "Deep Dive" discussions (deepDive = true).
class CreatePostScreen extends StatefulWidget {
  final bool deepDive;
  final String initialFandom;

  const CreatePostScreen({
    super.key,
    this.deepDive = false,
    this.initialFandom = '',
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _hashtagController = TextEditingController();

  late bool _deepDive;
  String _fandom = 'Anime';
  double _rating = 4;

  @override
  void initState() {
    super.initState();
    _deepDive = widget.deepDive;
    if (widget.initialFandom.isNotEmpty) _fandom = widget.initialFandom;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CommunityProvider>();
      if (provider.fandoms.isEmpty) provider.loadFilters();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _hashtagController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final hashtags = _hashtagController.text
        .split(RegExp(r'[,\s]+'))
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final result = await context.read<CommunityProvider>().createPost(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          fandom: _fandom,
          hashtags: hashtags,
          deepDive: _deepDive,
          rating: _deepDive ? _rating.round() : 0,
        );

    if (!mounted) return;

    if (result.success) {
      await showSuccessAlert(context, result.message, title: 'Published');
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } else {
      await showErrorAlert(context, result.message, title: 'Could Not Publish');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CommunityProvider>();
    final isLoading = provider.loading;

    return CommunityScaffold(
      title: _deepDive ? 'New Deep Dive' : 'Create Post',
      subtitle: _deepDive
          ? 'Share advanced lore, trivia or behind the scenes'
          : 'Share something with your fandom',
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // ------------------------ type switch ------------------------
            const CommunitySectionTitle('Post type'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _TypeCard(
                    icon: Icons.article_rounded,
                    title: 'Community Post',
                    subtitle: 'News, thoughts, fan art',
                    selected: !_deepDive,
                    onTap: () => setState(() => _deepDive = false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TypeCard(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Deep Dive',
                    subtitle: 'Lore, trivia, analysis',
                    selected: _deepDive,
                    onTap: () => setState(() => _deepDive = true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // --------------------------- title ---------------------------
            const CommunitySectionTitle('Title'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _titleController,
              maxLength: 120,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Give your post a clear title',
                counterStyle: GoogleFonts.inter(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                ),
              ),
              validator: (value) =>
                  (value == null || value.trim().isEmpty)
                      ? 'Title is required'
                      : null,
            ),
            const SizedBox(height: 8),

            // -------------------------- content --------------------------
            const CommunitySectionTitle('Content'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _contentController,
              maxLines: 7,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Write your thoughts...',
                alignLabelWithHint: true,
              ),
              validator: (value) =>
                  (value == null || value.trim().length < 10)
                      ? 'Please write at least 10 characters'
                      : null,
            ),
            const SizedBox(height: 18),

            // --------------------------- fandom ---------------------------
            const CommunitySectionTitle('Fandom'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (provider.fandoms.isEmpty
                      ? const [
                          {'name': 'Anime'},
                          {'name': 'Gaming'},
                          {'name': 'Movies & TV'},
                          {'name': 'Comics'},
                          {'name': 'Music'},
                          {'name': 'Sports'},
                          {'name': 'Sci-Fi'},
                        ]
                      : provider.fandoms
                          .map((f) => {'name': f.name})
                          .toList())
                  .map(
                    (f) => CommunityFilterChip(
                      label: f['name']!,
                      selected: _fandom == f['name'],
                      accentColor: AppTheme.secondaryColor,
                      onTap: () => setState(() => _fandom = f['name']!),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 18),

            // -------------------------- hashtags --------------------------
            const CommunitySectionTitle('Hashtags'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _hashtagController,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'e.g. Anime, OnePiece, Lore',
                prefixIcon: Icon(Icons.tag_rounded),
              ),
            ),
            const SizedBox(height: 18),

            // ----------------------- rating (deep dive) ------------------
            if (_deepDive) ...[
              CommunitySectionTitle(
                'Depth rating',
                trailing: Text(
                  '${_rating.round()} / 5',
                  style: GoogleFonts.outfit(
                    color: AppTheme.secondaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Slider(
                value: _rating,
                min: 1,
                max: 5,
                divisions: 4,
                activeColor: AppTheme.secondaryColor,
                inactiveColor: AppTheme.cardColorLight,
                label: '${_rating.round()}',
                onChanged: (value) => setState(() => _rating = value),
              ),
              const SizedBox(height: 10),
            ],

            // --------------------------- submit ---------------------------
            FilledButton.icon(
              onPressed: isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 20),
              label: Text(
                isLoading
                    ? 'Posting...'
                    : (_deepDive ? 'Publish Deep Dive' : 'Publish Post'),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.secondaryColor.withValues(alpha: 0.15)
              : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppTheme.secondaryColor
                : Colors.white.withValues(alpha: 0.08),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: selected ? AppTheme.secondaryColor : AppTheme.textMuted,
              size: 22,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                color: AppTheme.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
