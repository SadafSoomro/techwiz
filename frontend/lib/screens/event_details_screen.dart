import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/event_models.dart';
import '../models/json_utils.dart';
import '../providers/event_provider.dart';
import '../services/event_service.dart';
import '../theme/app_theme.dart';
import '../theme/event_theme.dart';
import '../widgets/event_banner_image.dart';
import '../widgets/event_scaffold.dart';
import '../widgets/event_widgets.dart';
import 'event_map_screen.dart';
import 'event_ticket_screen.dart';

/// MEMBER 4 - Events & Maps
/// Event Details: banner, schedule, venue, organizer, description,
/// ticket booking and a link to the dedicated map view.
class EventDetailsScreen extends StatefulWidget {
  final int eventId;
  final EventItem? event;

  const EventDetailsScreen({super.key, required this.eventId, this.event});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  EventItem? _event;
  EventTicket? _myTicket;
  List<EventItem> _nearby = [];

  bool _loading = true;
  bool _booking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await EventService.details(widget.eventId);

    if (!mounted) return;

    final data = result.data;
    final rawEvent = parseMap(data?['event']);

    if (result.success && rawEvent != null) {
      setState(() {
        _event = EventItem.fromJson(rawEvent);
        _myTicket = data?['myTicket'] == null
            ? null
            : EventTicket.fromJson(parseMap(data!['myTicket'])!);
        _nearby = parseList(data?['nearby'], EventItem.fromJson);
        _loading = false;
      });
    } else {
      setState(() {
        _error = result.message;
        _loading = false;
      });
    }
  }

  Future<void> _toggleSave() async {
    final event = _event;
    if (event == null) return;

    final result = await context.read<EventProvider>().toggleSave(event);
    if (!mounted) return;

    if (result.success && result.data != null) {
      setState(() => _event = event.copyWith(isSaved: result.data![0] == 1));
      _snack(result.message);
    } else {
      _snack(result.message, error: true);
    }
  }

  Future<void> _bookTicket() async {
    final event = _event;
    if (event == null) return;

    final quantity = await _askQuantity(event);
    if (quantity == null) return;

    setState(() => _booking = true);

    final result = await context.read<EventProvider>().bookTicket(
          eventId: event.id,
          quantity: quantity,
        );

    if (!mounted) return;
    setState(() => _booking = false);

    if (result.success && result.data != null) {
      setState(() => _myTicket = result.data);

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EventTicketScreen(ticket: result.data),
        ),
      );
      if (mounted) _load();
    } else {
      _snack(result.message, error: true);
    }
  }

  Future<int?> _askQuantity(EventItem event) async {
    int quantity = 1;

    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: EventTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How many tickets?',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.title,
                  style: GoogleFonts.inter(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _StepButton(
                      icon: Icons.remove_rounded,
                      onTap: quantity > 1
                          ? () => setSheetState(() => quantity--)
                          : null,
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '$quantity',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    _StepButton(
                      icon: Icons.add_rounded,
                      onTap: quantity < 10
                          ? () => setSheetState(() => quantity++)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      EventTheme.prettyPrice(
                        event.ticketPrice * quantity,
                        currency: event.currency,
                      ),
                      style: GoogleFonts.outfit(
                        color: EventTheme.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Simulated booking - no real payment is taken.',
                  style: GoogleFonts.inter(
                    color: AppTheme.textMuted,
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(quantity),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EventTheme.primary,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Confirm Booking',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error ? AppTheme.errorColor : EventTheme.surfaceLight,
        content: Text(message, style: GoogleFonts.inter(color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;
    final soldOut = event != null && event.capacity > 0 && event.seatsLeft <= 0;

    return EventScaffold(
      title: 'Event Details',
      subtitle: event?.category,
      showHeaderGlow: false,
      actions: [
        if (event != null)
          IconButton(
            tooltip: 'Interested',
            icon: Icon(
              event.isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: event.isSaved ? EventTheme.secondary : Colors.white,
            ),
            onPressed: _toggleSave,
          ),
        IconButton(
          tooltip: 'View on map',
          icon: const Icon(Icons.map_rounded, color: EventTheme.teal),
          onPressed: event == null
              ? null
              : () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EventMapScreen(focusEventId: event.id),
                    ),
                  ),
        ),
      ],
      bottomBar: event == null
          ? null
          : _TicketBar(
              event: event,
              myTicket: _myTicket,
              booking: _booking,
              soldOut: soldOut,
              onBook: _bookTicket,
              onViewTicket: (ticket) => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EventTicketScreen(ticket: ticket),
                ),
              ),
            ),
      child: _loading && event == null
          ? const Center(
              child: CircularProgressIndicator(color: EventTheme.primary),
            )
          : event == null
              ? EventEmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Could not load event',
                  message: _error ?? 'This event is not available.',
                  actionLabel: 'Retry',
                  onAction: _load,
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    // --------------------------- banner ---------------------------
                    _Banner(event: event),

                    const SizedBox(height: 18),

                    // ---------------------------- title ----------------------------
                    Text(
                      event.title,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Pill(
                          icon: EventTheme.categoryIcon(event.category),
                          label: event.category,
                          color: EventTheme.categoryColor(event.category),
                        ),
                        _Pill(
                          icon: Icons.timer_outlined,
                          label: EventTheme.countdown(event.daysUntil),
                          color: EventTheme.amber,
                        ),
                        _Pill(
                          icon: event.isFree
                              ? Icons.money_off_rounded
                              : Icons.local_activity_rounded,
                          label: EventTheme.prettyPrice(
                            event.ticketPrice,
                            currency: event.currency,
                          ),
                          color: event.isFree ? EventTheme.green : EventTheme.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ------------------------ info cards ------------------------
                    Row(
                      children: [
                        Expanded(
                          child: _InfoCard(
                            icon: Icons.calendar_month_rounded,
                            color: EventTheme.amber,
                            label: 'Date',
                            value: EventTheme.prettyDate(event.eventDate),
                            sub: event.isMultiDay
                                ? 'Until ${EventTheme.prettyDate(event.endDate)}'
                                : '${event.daysUntil} day(s) to go',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InfoCard(
                            icon: Icons.schedule_rounded,
                            color: EventTheme.primary,
                            label: 'Time',
                            value: EventTheme.prettyTime(event.startTime),
                            sub: 'Ends ${EventTheme.prettyTime(event.endTime)}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _VenueCard(event: event),

                    if (event.organizer.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _SimpleCard(
                        icon: Icons.groups_rounded,
                        color: EventTheme.teal,
                        title: 'Organizer',
                        value: event.organizer,
                      ),
                    ],

                    // ------------------------ description ------------------------
                    const SizedBox(height: 22),
                    const EventSectionTitle('About this event'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: EventTheme.card(),
                      child: Text(
                        event.description.isEmpty
                            ? 'No description provided for this event yet.'
                            : event.description,
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 13.5,
                          height: 1.65,
                        ),
                      ),
                    ),

                    // --------------------------- ticket ---------------------------
                    if (event.capacity > 0) ...[
                      const SizedBox(height: 22),
                      const EventSectionTitle('Ticket availability'),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: EventTheme.card(),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${event.attendeesCount} attending',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  soldOut
                                      ? 'Sold out'
                                      : '${event.seatsLeft} seats left',
                                  style: GoogleFonts.inter(
                                    color: soldOut
                                        ? EventTheme.secondary
                                        : EventTheme.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                minHeight: 7,
                                value: (event.attendeesCount / event.capacity)
                                    .clamp(0.0, 1.0),
                                backgroundColor: Colors.white.withValues(alpha: 0.08),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  soldOut ? EventTheme.secondary : EventTheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.people_alt_rounded,
                                    size: 14, color: AppTheme.textMuted),
                                const SizedBox(width: 6),
                                Text(
                                  'Capacity ${event.capacity}',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${event.savesCount} interested',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    // ------------------------ map preview ------------------------
                    const SizedBox(height: 22),
                    EventSectionTitle(
                      'Location',
                      trailing: TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EventMapScreen(focusEventId: event.id),
                          ),
                        ),
                        child: Text(
                          'Open map view',
                          style: GoogleFonts.inter(
                            color: EventTheme.teal,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _MapPreview(event: event),

                    // ------------------------ nearby events ------------------------
                    if (_nearby.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      EventSectionTitle(
                        'More in ${event.city}',
                        trailing: Text(
                          '${_nearby.length} events',
                          style: GoogleFonts.inter(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._nearby.map(
                        (item) => _NearbyTile(
                          event: item,
                          onTap: () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => EventDetailsScreen(
                                eventId: item.id,
                                event: item,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }
}

// ---------------------------------------------------------------------------
// Banner
// ---------------------------------------------------------------------------
class _Banner extends StatelessWidget {
  final EventItem event;

  const _Banner({required this.event});

  @override
  Widget build(BuildContext context) {
    final color = EventTheme.categoryColor(event.category);

    return Container(
      height: 210,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: EventBannerImage(
        imageUrl: event.imageUrl,
        category: event.category,
        height: 210,
        borderRadius: BorderRadius.circular(22),
        overlay: Stack(
          children: [
            Positioned(
              left: 18,
              top: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(EventTheme.categoryIcon(event.category),
                        color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      event.category.toUpperCase(),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 18,
              bottom: 18,
              right: 18,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  EventDateBadge(isoDate: event.eventDate, size: 62),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          event.city,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            shadows: const [
                              Shadow(color: Colors.black54, blurRadius: 8),
                            ],
                          ),
                        ),
                        Text(
                          event.venue,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 12,
                            shadows: const [
                              Shadow(color: Colors.black54, blurRadius: 8),
                            ],
                          ),
                        ),
                      ],
                    ),
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
// Small building blocks
// ---------------------------------------------------------------------------
class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Pill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String sub;

  const _InfoCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: EventTheme.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: GoogleFonts.inter(
                  color: AppTheme.textMuted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

class _VenueCard extends StatelessWidget {
  final EventItem event;

  const _VenueCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: EventTheme.card(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: EventTheme.secondary.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.place_rounded,
                color: EventTheme.secondary, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Venue',
                  style: GoogleFonts.inter(
                    color: AppTheme.textMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  event.venue,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (event.address != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    event.address!,
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 3),
                Text(
                  event.city,
                  style: GoogleFonts.inter(
                    color: EventTheme.teal,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;

  const _SimpleCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: EventTheme.card(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: AppTheme.textMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPreview extends StatelessWidget {
  final EventItem event;

  const _MapPreview({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: EventTheme.mapBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.place_rounded,
                    color: EventTheme.secondary, size: 34),
                const SizedBox(height: 4),
                Text(
                  event.city,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                if (event.latitude != null)
                  Text(
                    '${event.latitude}, ${event.longitude}',
                    style: GoogleFonts.inter(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            right: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: EventTheme.surfaceLight.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Preview',
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NearbyTile extends StatelessWidget {
  final EventItem event;
  final VoidCallback onTap;

  const _NearbyTile({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = EventTheme.categoryColor(event.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: EventTheme.card(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(EventTheme.categoryIcon(event.category),
                      color: color, size: 17),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${EventTheme.prettyDate(event.eventDate)} · ${EventTheme.prettyTime(event.startTime)}',
                        style: GoogleFonts.inter(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom ticket bar
// ---------------------------------------------------------------------------
class _TicketBar extends StatelessWidget {
  final EventItem event;
  final EventTicket? myTicket;
  final bool booking;
  final bool soldOut;
  final VoidCallback onBook;
  final void Function(EventTicket ticket) onViewTicket;

  const _TicketBar({
    required this.event,
    required this.myTicket,
    required this.booking,
    required this.soldOut,
    required this.onBook,
    required this.onViewTicket,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: EventTheme.surface,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  event.isFree ? 'Free entry' : 'From',
                  style: GoogleFonts.inter(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                  ),
                ),
                Text(
                  EventTheme.prettyPrice(
                    event.ticketPrice,
                    currency: event.currency,
                  ),
                  style: GoogleFonts.outfit(
                    color: event.isFree ? EventTheme.green : EventTheme.primary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: booking
                      ? null
                      : myTicket != null
                          ? () => onViewTicket(myTicket!)
                          : soldOut
                              ? null
                              : onBook,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: myTicket != null
                        ? EventTheme.teal
                        : EventTheme.primary,
                    disabledBackgroundColor:
                        Colors.white.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: booking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          myTicket != null
                              ? Icons.confirmation_number_rounded
                              : Icons.local_activity_rounded,
                          size: 19,
                        ),
                  label: Text(
                    booking
                        ? 'Booking...'
                        : myTicket != null
                            ? 'View My Ticket'
                            : soldOut
                                ? 'Sold Out'
                                : 'Get Ticket',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
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

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: onTap == null
              ? Colors.white.withValues(alpha: 0.04)
              : EventTheme.surfaceLight,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Icon(
          icon,
          color: onTap == null ? AppTheme.textMuted : Colors.white,
        ),
      ),
    );
  }
}
