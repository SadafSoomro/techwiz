import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/community_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/community_chips.dart';
import '../widgets/community_scaffold.dart';
import 'search_results_screen.dart';
import 'trending_screen.dart';

/// MEMBER 3 - Search & Community
/// Search screen: keyword input, live suggestions, content type filters
/// (Users / Posts / Fandoms), fandom filter and sort selection.
class SearchScreen extends StatefulWidget {
  final String initialQuery;

  const SearchScreen({super.key, this.initialQuery = ''});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  Timer? _debounce;
  List<String> _suggestions = [];

  String _type = 'all';
  String _fandom = 'All';
  String _sort = 'popular';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CommunityProvider>();
      if (provider.fandoms.isEmpty) provider.loadFilters();
      if (provider.trending == null) provider.loadTrending();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final list = await context.read<CommunityProvider>().suggestions(value);
      if (mounted) setState(() => _suggestions = list);
    });
  }

  void _submit(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    _focusNode.unfocus();
    setState(() => _suggestions = []);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchResultsScreen(
          query: trimmed,
          type: _type,
          fandom: _fandom,
          sort: _sort,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CommunityProvider>();

    return CommunityScaffold(
      title: 'Search',
      subtitle: 'Users · Posts · Fandoms',
      actions: [
        IconButton(
          tooltip: 'Trending',
          icon: const Icon(
            Icons.local_fire_department_rounded,
            color: AppTheme.secondaryColor,
          ),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TrendingScreen()),
          ),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          // ----------------------- search field -----------------------
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.inputFillColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: AppTheme.textMuted),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.search,
                    onChanged: _onChanged,
                    onSubmitted: _submit,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Search fandoms, posts, fans...',
                      hintStyle: GoogleFonts.inter(
                        color: AppTheme.textMuted,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                if (_controller.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _controller.clear();
                      setState(() => _suggestions = []);
                    },
                    child: const Icon(Icons.close_rounded,
                        color: AppTheme.textMuted, size: 20),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          FilledButton.icon(
            onPressed: () => _submit(_controller.text),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              backgroundColor: AppTheme.primaryColor,
            ),
            icon: const Icon(Icons.search_rounded, size: 20),
            label: Text(
              'Search',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),

          // ----------------------- suggestions -----------------------
          if (_suggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            const CommunitySectionTitle('Suggestions'),
            const SizedBox(height: 8),
            ..._suggestions.map(
              (s) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.north_west_rounded,
                  size: 18,
                  color: AppTheme.textMuted,
                ),
                title: Text(
                  s,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                ),
                onTap: () {
                  _controller.text = s;
                  _submit(s);
                },
              ),
            ),
          ],

          // ------------------------- filters -------------------------
          const SizedBox(height: 16),
          const CommunitySectionTitle('Filters'),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.filter_list_rounded,
                size: 16,
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                'Show results for',
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              CommunityFilterChip(
                label: 'All',
                selected: _type == 'all',
                onTap: () => setState(() => _type = 'all'),
              ),
              CommunityFilterChip(
                label: 'Users',
                icon: Icons.people_alt_rounded,
                selected: _type == 'users',
                onTap: () => setState(() => _type = 'users'),
              ),
              CommunityFilterChip(
                label: 'Posts',
                icon: Icons.article_rounded,
                selected: _type == 'posts',
                onTap: () => setState(() => _type = 'posts'),
              ),
              CommunityFilterChip(
                label: 'Fandoms',
                icon: Icons.auto_awesome_rounded,
                selected: _type == 'fandoms',
                onTap: () => setState(() => _type = 'fandoms'),
              ),
            ],
          ),

          // ----------------------- fandom chips -----------------------
          const SizedBox(height: 18),
          const CommunitySectionTitle('Fandom'),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                CommunityFilterChip(
                  label: 'All',
                  selected: _fandom == 'All',
                  onTap: () => setState(() => _fandom = 'All'),
                ),
                ...provider.fandoms.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: CommunityFilterChip(
                      label: f.name,
                      selected: _fandom == f.name,
                      onTap: () => setState(() => _fandom = f.name),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ------------------------- sorting -------------------------
          const SizedBox(height: 18),
          const CommunitySectionTitle('Sort by'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (provider.sortOptions.isEmpty
                    ? const [
                        {'key': 'popular', 'label': 'Popular'},
                        {'key': 'newest', 'label': 'Newest'},
                        {'key': 'top', 'label': 'Top'},
                        {'key': 'trending', 'label': 'Trending'},
                      ]
                    : provider.sortOptions)
                .map(
                  (option) => CommunityFilterChip(
                    label: option['label'] ?? '',
                    selected: _sort == option['key'],
                    onTap: () => setState(() => _sort = option['key'] ?? 'popular'),
                  ),
                )
                .toList(),
          ),

          // --------------------- recent searches ---------------------
          if (provider.recentSearches.isNotEmpty) ...[
            const SizedBox(height: 22),
            const CommunitySectionTitle('Recent searches'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: provider.recentSearches
                  .map(
                    (q) => ActionChip(
                      backgroundColor: AppTheme.cardColor,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      label: Text(
                        q,
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      avatar: const Icon(
                        Icons.history_rounded,
                        size: 15,
                        color: AppTheme.textMuted,
                      ),
                      onPressed: () {
                        _controller.text = q;
                        _submit(q);
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
