import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/event_models.dart';
import '../providers/event_provider.dart';
import '../theme/app_theme.dart';
import '../theme/event_theme.dart';
import '../widgets/app_alert.dart';
import '../widgets/event_scaffold.dart';
import '../widgets/event_widgets.dart';
import 'event_details_screen.dart';
import 'event_map_screen.dart';

/// MEMBER 4 - Events & Maps
/// Event Ticket screen.
///  - opened from the Events hub -> "My Tickets" list
///  - opened right after booking, or from the list -> single ticket view
class EventTicketScreen extends StatefulWidget {
  final EventTicket? ticket;

  const EventTicketScreen({super.key, this.ticket});

  @override
  State<EventTicketScreen> createState() => _EventTicketScreenState();
}

class _EventTicketScreenState extends State<EventTicketScreen> {
  EventTicket? _ticket;

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticket;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<EventProvider>();
      if (_ticket == null) provider.loadMyTickets();
    });
  }

  Future<void> _cancel(EventTicket ticket) async {
    final provider = context.read<EventProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EventTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Cancel this ticket?',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Your booking for "${ticket.title}" will be cancelled. '
          'No real payment was taken for this simulated booking.',
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Keep it',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: Text(
              'Cancel ticket',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await provider.cancelTicket(ticket.id);
    if (!mounted) return;

    if (result.success) {
      await showSuccessAlert(context, result.message, title: 'Ticket Cancelled');
    } else {
      await showErrorAlert(context, result.message, title: 'Could Not Cancel');
    }

    if (result.success && mounted) {
      if (widget.ticket != null) {
        Navigator.of(context).maybePop();
      } else {
        setState(() => _ticket = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventProvider>();
    final single = _ticket;

    return EventScaffold(
      title: single != null ? 'Event Ticket' : 'My Tickets',
      subtitle: single != null
          ? single.ticketCode
          : '${provider.myTickets.length} confirmed booking(s)',
      showHeaderGlow: false,
      actions: [
        if (single != null)
          IconButton(
            tooltip: 'Back to list',
            icon: const Icon(Icons.list_alt_rounded, color: Colors.white),
            onPressed: () => setState(() => _ticket = null),
          ),
      ],
      child: single != null
          ? _TicketView(
              ticket: single,
              onCancel: () => _cancel(single),
              onEvent: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EventDetailsScreen(eventId: single.eventId),
                ),
              ),
              onMap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EventMapScreen(focusEventId: single.eventId),
                ),
              ),
            )
          : _MyTicketsList(
              loading: provider.loading,
              tickets: provider.myTickets,
              onOpen: (ticket) => setState(() => _ticket = ticket),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// My tickets list
// ---------------------------------------------------------------------------
class _MyTicketsList extends StatelessWidget {
  final bool loading;
  final List<EventTicket> tickets;
  final void Function(EventTicket ticket) onOpen;

  const _MyTicketsList({
    required this.loading,
    required this.tickets,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (loading && tickets.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: EventTheme.primary),
      );
    }

    if (tickets.isEmpty) {
      return const EventEmptyState(
        icon: Icons.confirmation_number_outlined,
        title: 'No tickets yet',
        message:
            'Book a ticket from any event and it will appear here with your\nticket code and seat details.',
      );
    }

    return RefreshIndicator(
      color: EventTheme.primary,
      onRefresh: () => context.read<EventProvider>().loadMyTickets(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        children: [
          // ---------------------------- summary ----------------------------
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: EventTheme.ticketGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_activity_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${tickets.length} confirmed ticket(s)',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Simulated bookings - no real payment is taken',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const EventSectionTitle('Your bookings'),
          const SizedBox(height: 12),

          ...tickets.map(
            (ticket) => _TicketListTile(
              ticket: ticket,
              onTap: () => onOpen(ticket),
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketListTile extends StatelessWidget {
  final EventTicket ticket;
  final VoidCallback onTap;

  const _TicketListTile({required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = EventTheme.categoryColor(ticket.category);
    final cancelled = !ticket.isConfirmed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: EventTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: cancelled
              ? Colors.white.withValues(alpha: 0.08)
              : color.withValues(alpha: 0.35),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    EventDateBadge(isoDate: ticket.eventDate, size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${ticket.city} · ${EventTheme.prettyTime(ticket.startTime)}',
                            style: GoogleFonts.inter(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: (cancelled
                                          ? AppTheme.errorColor
                                          : EventTheme.green)
                                      .withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Text(
                                  cancelled ? 'CANCELLED' : 'CONFIRMED',
                                  style: GoogleFonts.inter(
                                    color: cancelled
                                        ? AppTheme.errorColor
                                        : EventTheme.green,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'x${ticket.quantity}',
                                style: GoogleFonts.inter(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppTheme.textMuted),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.qr_code_2_rounded,
                        size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      ticket.ticketCode,
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      EventTheme.prettyPrice(
                        ticket.totalPrice,
                        currency: ticket.currency,
                      ),
                      style: GoogleFonts.outfit(
                        color: EventTheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single ticket view
// ---------------------------------------------------------------------------
class _TicketView extends StatelessWidget {
  final EventTicket ticket;
  final VoidCallback onCancel;
  final VoidCallback onEvent;
  final VoidCallback onMap;

  const _TicketView({
    required this.ticket,
    required this.onCancel,
    required this.onEvent,
    required this.onMap,
  });

  @override
  Widget build(BuildContext context) {
    final color = EventTheme.categoryColor(ticket.category);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
      children: [
        // ---------------------------- the ticket ----------------------------
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: EventTheme.primary.withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // ------------------------- ticket head -------------------------
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: EventTheme.ticketGradient,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'FANDOM VERSE · E-TICKET',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          ticket.isConfirmed
                              ? Icons.verified_rounded
                              : Icons.cancel_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      ticket.title,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            color: Colors.white70, size: 14),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            '${ticket.venue}, ${ticket.city}',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ------------------------ perforated edge ------------------------
              Container(
                color: EventTheme.surface,
                child: Row(
                  children: [
                    _Notch(color: AppTheme.backgroundColor, alignLeft: true),
                    Expanded(
                      child: CustomPaint(
                        painter: _DashedLinePainter(),
                        child: const SizedBox(height: 34, width: double.infinity),
                      ),
                    ),
                    _Notch(color: AppTheme.backgroundColor, alignLeft: false),
                  ],
                ),
              ),

              // ------------------------ ticket body ------------------------
              Container(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                decoration: const BoxDecoration(
                  color: EventTheme.surface,
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _TicketField(
                          label: 'DATE',
                          value: EventTheme.prettyDate(ticket.eventDate),
                          icon: Icons.calendar_month_rounded,
                        ),
                        _TicketField(
                          label: 'TIME',
                          value: EventTheme.prettyTime(ticket.startTime),
                          icon: Icons.schedule_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _TicketField(
                          label: 'SEAT',
                          value: ticket.seatNumber.isEmpty
                              ? 'General'
                              : ticket.seatNumber,
                          icon: Icons.event_seat_rounded,
                        ),
                        _TicketField(
                          label: 'QUANTITY',
                          value: '${ticket.quantity} ticket(s)',
                          icon: Icons.confirmation_number_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // --------------------------- QR block ---------------------------
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: CustomPaint(
                            size: const Size(96, 96),
                            painter: _TicketCodePainter(ticket.ticketCode),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TICKET CODE',
                                style: GoogleFonts.inter(
                                  color: AppTheme.textMuted,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                ticket.ticketCode,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Show this code at the entrance gate.',
                                style: GoogleFonts.inter(
                                  color: AppTheme.textMuted,
                                  fontSize: 10.5,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  ticket.category.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    color: color,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Divider(color: Colors.white.withValues(alpha: 0.07), height: 1),
                    const SizedBox(height: 14),

                    // --------------------------- payment ---------------------------
                    Row(
                      children: [
                        Text(
                          'Total paid',
                          style: GoogleFonts.inter(
                            color: AppTheme.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          EventTheme.prettyPrice(
                            ticket.totalPrice,
                            currency: ticket.currency,
                          ),
                          style: GoogleFonts.outfit(
                            color: ticket.isFree
                                ? EventTheme.green
                                : EventTheme.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'Booked',
                          style: GoogleFonts.inter(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          ticket.bookedAgo.isEmpty
                              ? EventTheme.prettyDate(ticket.bookedAt)
                              : ticket.bookedAgo,
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
          ),
        ),

        const SizedBox(height: 20),

        // ---------------------------- countdown ----------------------------
        if (ticket.isConfirmed)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: EventTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: EventTheme.primary.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_rounded,
                    color: EventTheme.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ticket.daysUntil > 0
                        ? 'Starts in ${ticket.daysUntil} day(s) · ${EventTheme.prettyDate(ticket.eventDate)}'
                        : 'This event is starting today!',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 18),

        // ----------------------------- actions -----------------------------
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onEvent,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                icon: const Icon(Icons.info_outline_rounded,
                    size: 17, color: AppTheme.textSecondary),
                label: Text(
                  'Event details',
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onMap,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: EventTheme.teal.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                icon: const Icon(Icons.map_rounded,
                    size: 17, color: EventTheme.teal),
                label: Text(
                  'Venue map',
                  style: GoogleFonts.inter(
                    color: EventTheme.teal,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),

        if (ticket.isConfirmed) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: onCancel,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              icon: const Icon(Icons.cancel_outlined,
                  size: 17, color: AppTheme.errorColor),
              label: Text(
                'Cancel this ticket',
                style: GoogleFonts.inter(
                  color: AppTheme.errorColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Ticket pieces
// ---------------------------------------------------------------------------
class _TicketField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _TicketField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 15, color: EventTheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: AppTheme.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12.5,
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

/// Half-circle notch on the perforated edge of the ticket.
class _Notch extends StatelessWidget {
  final Color color;
  final bool alignLeft;

  const _Notch({required this.color, required this.alignLeft});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 34,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.horizontal(
          right: alignLeft ? const Radius.circular(30) : Radius.zero,
          left: alignLeft ? Radius.zero : const Radius.circular(30),
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1.6;

    const dash = 6.0;
    const gap = 5.0;
    double x = 0;

    while (x < size.width) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(math.min(x + dash, size.width), size.height / 2),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => false;
}

/// Deterministic QR-like pattern generated from the ticket code, so every
/// ticket gets a unique looking code block (no external package needed).
class _TicketCodePainter extends CustomPainter {
  final String code;

  _TicketCodePainter(this.code);

  @override
  void paint(Canvas canvas, Size size) {
    const modules = 21;
    final cell = size.width / modules;
    final random = math.Random(code.hashCode);
    final paint = Paint()..color = const Color(0xFF0E131B);

    // random data modules
    for (int row = 0; row < modules; row++) {
      for (int col = 0; col < modules; col++) {
        if (_isReserved(row, col, modules)) continue;
        if (random.nextDouble() < 0.48) {
          canvas.drawRect(
            Rect.fromLTWH(col * cell, row * cell, cell * 0.92, cell * 0.92),
            paint,
          );
        }
      }
    }

    // three position markers
    _drawFinder(canvas, paint, 0, 0, cell);
    _drawFinder(canvas, paint, modules - 7, 0, cell);
    _drawFinder(canvas, paint, 0, modules - 7, cell);

    // timing patterns
    for (int i = 8; i < modules - 8; i++) {
      if (i % 2 == 0) {
        canvas.drawRect(Rect.fromLTWH(i * cell, 6 * cell, cell, cell), paint);
        canvas.drawRect(Rect.fromLTWH(6 * cell, i * cell, cell, cell), paint);
      }
    }
  }

  bool _isReserved(int row, int col, int modules) {
    final inTopLeft = row < 8 && col < 8;
    final inTopRight = row < 8 && col >= modules - 8;
    final inBottomLeft = row >= modules - 8 && col < 8;
    return inTopLeft || inTopRight || inBottomLeft;
  }

  void _drawFinder(Canvas canvas, Paint paint, int row, int col, double cell) {
    canvas.drawRect(
      Rect.fromLTWH(col * cell, row * cell, cell * 7, cell * 7),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH((col + 1) * cell, (row + 1) * cell, cell * 5, cell * 5),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      Rect.fromLTWH((col + 2) * cell, (row + 2) * cell, cell * 3, cell * 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _TicketCodePainter oldDelegate) =>
      oldDelegate.code != code;
}
