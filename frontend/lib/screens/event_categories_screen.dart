import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/event_models.dart';
import '../providers/event_provider.dart';
import '../theme/app_theme.dart';
import '../theme/event_theme.dart';
import '../widgets/event_banner_image.dart';
import '../widgets/event_card.dart';
import '../widgets/event_scaffold.dart';
import '../widgets/event_widgets.dart';
import 'event_details_screen.dart';

/// MEMBER 4 - Events & Maps
/// Event Categories screen: a grid of every fandom event category
/// (conventions, cosplay meetups, screenings, tournaments, concerts ...).
class EventCategoriesScreen extends StatefulWidget {
  const EventCategoriesScreen({super.key});

  @override
  State<EventCategoriesScreen> createState() => _EventCategoriesScreenState();
}

class _EventCategoriesScreenState extends State<EventCategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<EventProvider>();
      if (provider.categories.isEmpty) provider.loadFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventProvider>();
    final categories = provider.categories;

    return EventScaffold(
      title: 'Event Categories',
      subtitle: '${categories.length} categories available',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: () => context.read<EventProvider>().loadFilters(),
        ),
      ],
      child: provider.loading && categories.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: EventTheme.primary),
            )
          : categories.isEmpty
              ? const EventEmptyState(
                  icon: Icons.category_outlined,
                  title: 'No categories yet',
                  message: 'Event categories will appear here once added.',
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) =>
                      _CategoryCard(category: categories[index]),
                ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final EventCategory category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final color = EventTheme.fromHex(category.color);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CategoryEventsScreen(category: category),
        ),
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: EventTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------------ banner artwork ------------------------
            EventBannerImage(
              imageUrl: null,
              category: category.name,
              height: 86,
              borderRadius: BorderRadius.zero,
              showFallbackIcon: false,
              overlay: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Icon(
                        EventTheme.iconFor(category.icon),
                        color: color,
                        size: 18,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        '${category.eventsCount}',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --------------------------- content ---------------------------
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Expanded(
                      child: Text(
                        category.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: AppTheme.textMuted,
                          fontSize: 10.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Explore',
                          style: GoogleFonts.inter(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(Icons.arrow_forward_rounded, color: color, size: 13),
                      ],
                    ),
                  ],
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
// Events of one category
// ---------------------------------------------------------------------------
class CategoryEventsScreen extends StatefulWidget {
  final EventCategory category;

  const CategoryEventsScreen({super.key, required this.category});

  @override
  State<CategoryEventsScreen> createState() => _CategoryEventsScreenState();
}

class _CategoryEventsScreenState extends State<CategoryEventsScreen> {
  late final EventProvider _provider;
  List<EventItem> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _provider = context.read<EventProvider>();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await _provider.loadEvents(category: widget.category.name);
    if (!mounted) return;
    setState(() {
      _events = _provider.events;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = EventTheme.fromHex(widget.category.color);

    return EventScaffold(
      title: widget.category.name,
      subtitle: '${_events.length} upcoming event(s)',
      showHeaderGlow: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _load,
        ),
      ],
      child: RefreshIndicator(
        color: color,
        onRefresh: _load,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: EventTheme.primary),
              )
            : _events.isEmpty
                ? EventEmptyState(
                    icon: EventTheme.iconFor(widget.category.icon),
                    title: 'Nothing scheduled yet',
                    message:
                        'There are no upcoming ${widget.category.name.toLowerCase()} events.\nCheck back soon!',
                    actionLabel: 'Back',
                    onAction: () => Navigator.of(context).maybePop(),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: color.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              EventTheme.iconFor(widget.category.icon),
                              color: color,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.category.description,
                                style: GoogleFonts.inter(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      ..._events.map(
                        (event) => EventCard(
                          event: event,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => EventDetailsScreen(
                                eventId: event.id,
                                event: event,
                              ),
                            ),
                          ),
                          onSave: () => _provider.toggleSave(event),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
