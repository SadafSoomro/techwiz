import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/event_models.dart';
import '../providers/event_provider.dart';
import '../theme/app_theme.dart';
import '../theme/event_theme.dart';
import '../widgets/event_card.dart';
import '../widgets/event_scaffold.dart';
import '../widgets/event_widgets.dart';
import 'event_calendar_screen.dart';
import 'event_categories_screen.dart';
import 'event_details_screen.dart';
import 'event_map_screen.dart';
import 'event_ticket_screen.dart';

/// MEMBER 4 - Events & Maps
/// Events home: next event hero, quick access to Map / Calendar /
/// Categories / Tickets, city + category filters and the events list.
class EventsScreen extends StatefulWidget {
  final bool embedded;

  const EventsScreen({super.key, this.embedded = false});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final TextEditingController _searchController = TextEditingController();

  static const List<Map<String, String>> _sortOptions = [
    {'key': 'date', 'label': 'Date'},
    {'key': 'distance', 'label': 'Nearest'},
    {'key': 'popular', 'label': 'Popular'},
    {'key': 'price_low', 'label': 'Price ↑'},
    {'key': 'price_high', 'label': 'Price ↓'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<EventProvider>();
      if (provider.events.isEmpty) provider.loadEvents();
      if (provider.categories.isEmpty) provider.loadFilters();
      provider.loadOverview();
      provider.loadMyTickets();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final provider = context.read<EventProvider>();
    await provider.loadEvents();
    await provider.loadOverview();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventProvider>();

    return EventScaffold(
      title: 'Events',
      subtitle: 'Nearby conventions, meetups & screenings',
      showBackButton: !widget.embedded,
      actions: [
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _refresh,
        ),
      ],
      child: RefreshIndicator(
        color: EventTheme.primary,
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          children: [
            // ----------------------- next event hero -----------------------
            if (provider.nextEvent != null) _NextEventHero(event: provider.nextEvent!),
            const SizedBox(height: 16),

            // ------------------------ quick actions ------------------------
            Row(
              children: [
                _QuickAction(
                  icon: Icons.map_rounded,
                  label: 'Map',
                  color: EventTheme.teal,
                  onTap: () => _open(const EventMapScreen()),
                ),
                const SizedBox(width: 10),
                _QuickAction(
                  icon: Icons.calendar_month_rounded,
                  label: 'Calendar',
                  color: EventTheme.amber,
                  onTap: () => _open(const EventCalendarScreen()),
                ),
                const SizedBox(width: 10),
                _QuickAction(
                  icon: Icons.category_rounded,
                  label: 'Categories',
                  color: EventTheme.primary,
                  onTap: () => _open(const EventCategoriesScreen()),
                ),
                const SizedBox(width: 10),
                _QuickAction(
                  icon: Icons.confirmation_number_rounded,
                  label: 'Tickets',
                  color: EventTheme.secondary,
                  badge: provider.myTickets.length,
                  onTap: () => _open(const EventTicketScreen()),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ------------------------- search field -------------------------
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: EventTheme.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search events, venues, organizers...',
                        hintStyle: GoogleFonts.inter(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onSubmitted: (value) => context
                          .read<EventProvider>()
                          .loadEvents(query: value.trim()),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        context.read<EventProvider>().loadEvents(query: '');
                      },
                      child: const Icon(Icons.close_rounded,
                          color: AppTheme.textMuted, size: 18),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // --------------------------- location ---------------------------
            Row(
              children: [
                const Icon(Icons.my_location_rounded,
                    color: EventTheme.teal, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    provider.usingDeviceLocation
                        ? 'Using your location · nearest city ${provider.currentCity}'
                        : 'Location: ${provider.currentCity}',
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _pickCity(provider),
                  child: Text(
                    'Change',
                    style: GoogleFonts.inter(
                      color: EventTheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            // -------------------------- categories --------------------------
            if (provider.categories.isNotEmpty) ...[
              const SizedBox(height: 6),
              EventSectionTitle(
                'Event Categories',
                trailing: TextButton(
                  onPressed: () => _open(const EventCategoriesScreen()),
                  child: Text(
                    'View all',
                    style: GoogleFonts.inter(
                      color: EventTheme.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    EventFilterChip(
                      label: 'All',
                      selected: provider.category == 'All',
                      onTap: () => context
                          .read<EventProvider>()
                          .loadEvents(category: 'All'),
                    ),
                    ...provider.categories.map(
                      (category) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: EventFilterChip(
                          label: category.name,
                          icon: EventTheme.iconFor(category.icon),
                          accentColor: EventTheme.fromHex(category.color),
                          selected: provider.category == category.name,
                          onTap: () => context
                              .read<EventProvider>()
                              .loadEvents(category: category.name),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ----------------------------- cities -----------------------------
            const SizedBox(height: 18),
            EventSectionTitle(
              'City',
              trailing: Text(
                '${provider.cities.length} cities',
                style: GoogleFonts.inter(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  EventFilterChip(
                    label: 'All',
                    icon: Icons.public_rounded,
                    selected: provider.city == 'All',
                    onTap: () =>
                        context.read<EventProvider>().loadEvents(city: 'All'),
                  ),
                  ...provider.cities.map(
                    (city) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: EventFilterChip(
                        label: '${city.city} (${city.eventsCount})',
                        selected: provider.city == city.city,
                        onTap: () => context
                            .read<EventProvider>()
                            .loadEvents(city: city.city),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ----------------------------- sorting -----------------------------
            const SizedBox(height: 18),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sort_rounded,
                          size: 16, color: AppTheme.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        'Sort',
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
                  ..._sortOptions.map(
                    (option) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: EventFilterChip(
                        label: option['label']!,
                        selected: provider.sort == option['key'],
                        accentColor: EventTheme.secondary,
                        onTap: () => context
                            .read<EventProvider>()
                            .loadEvents(sort: option['key']),
                      ),
                    ),
                  ),
                  EventFilterChip(
                    label: 'Free only',
                    icon: Icons.money_off_rounded,
                    selected: provider.freeOnly,
                    accentColor: EventTheme.green,
                    onTap: () => context
                        .read<EventProvider>()
                        .loadEvents(freeOnly: !provider.freeOnly),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --------------------------- events list ---------------------------
            EventSectionTitle(
              provider.sort == 'distance' ? 'Nearest Events' : 'Upcoming Events',
              trailing: Text(
                '${provider.events.length} found',
                style: GoogleFonts.inter(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (provider.loading && provider.events.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: CircularProgressIndicator(color: EventTheme.primary),
                ),
              )
            else if (provider.events.isEmpty)
              const EventEmptyState(
                icon: Icons.event_busy_rounded,
                title: 'No events found',
                message:
                    'Try another city, category or clear the search to see\nall upcoming fandom events.',
              )
            else
              ...provider.events.map(
                (event) => EventCard(
                  event: event,
                  onTap: () => _openEvent(event),
                  onSave: () =>
                      context.read<EventProvider>().toggleSave(event),
                  onMap: () => _open(
                    EventMapScreen(focusEventId: event.id),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ------------------------------ actions ------------------------------
  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _openEvent(EventItem event) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EventDetailsScreen(eventId: event.id, event: event)),
    );
  }

  Future<void> _pickCity(EventProvider provider) async {
    final cities = EventProvider.cityCoordinates.keys.toList();

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: EventTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select your location',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.my_location_rounded, color: EventTheme.teal),
              title: Text(
                'Use my current location',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              ),
              subtitle: Text(
                'Finds the nearest supported city',
                style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 11),
              ),
              onTap: () {
                provider.useDeviceLocation(
                  lat: provider.latitude,
                  lng: provider.longitude,
                );
                Navigator.of(context).pop();
              },
            ),
            const Divider(height: 1, color: Colors.white12),
            ...cities.map(
              (city) => ListTile(
                leading: Icon(
                  city == provider.currentCity
                      ? Icons.radio_button_checked_rounded
                      : Icons.location_city_rounded,
                  color: city == provider.currentCity
                      ? EventTheme.primary
                      : AppTheme.textMuted,
                ),
                title: Text(
                  city,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                ),
                onTap: () {
                  provider.setCityLocation(city);
                  Navigator.of(context).pop(city);
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (selected != null && mounted) {
      final provider = context.read<EventProvider>();
      provider.loadEvents(sort: provider.sort == 'distance' ? 'distance' : 'date');
      provider.loadNearby();
    }
  }
}

// ---------------------------------------------------------------------------
// Hero card for the next upcoming event
// ---------------------------------------------------------------------------
class _NextEventHero extends StatelessWidget {
  final EventItem event;

  const _NextEventHero({required this.event});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EventDetailsScreen(eventId: event.id, event: event),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: EventTheme.featuredGradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: EventTheme.primary.withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -26,
              bottom: -30,
              child: Icon(
                EventTheme.categoryIcon(event.category),
                size: 150,
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'NEXT UP · ${EventTheme.countdown(event.daysUntil).toUpperCase()}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${event.venue}, ${event.city}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: Colors.white70, size: 13),
                    const SizedBox(width: 5),
                    Text(
                      '${EventTheme.prettyDate(event.eventDate)} · ${EventTheme.prettyTime(event.startTime)}',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        EventTheme.prettyPrice(
                          event.ticketPrice,
                          currency: event.currency,
                        ),
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          'View details',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 16),
                      ],
                    ),
                  ],
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
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int badge;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: EventTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  if (badge > 0)
                    Positioned(
                      right: -3,
                      top: -3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: EventTheme.secondary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$badge',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
