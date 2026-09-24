import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/event_models.dart';
import '../theme/app_theme.dart';
import '../theme/event_theme.dart';
import 'event_banner_image.dart';
import 'event_widgets.dart';

/// MEMBER 4 - Events & Maps
/// Event card used by the Events list, Categories, Saved Events and the
/// Calendar day list.
class EventCard extends StatelessWidget {
  final EventItem event;
  final VoidCallback? onTap;
  final VoidCallback? onSave;
  final VoidCallback? onMap;

  /// Shows the horizontally scrolling layout with the date badge on the left.
  final bool compact;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onSave,
    this.onMap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = EventTheme.categoryColor(event.category);
    final soldOut = event.capacity > 0 && event.seatsLeft <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: EventTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: event.isFeatured
              ? EventTheme.primary.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ------------------------- banner image -------------------------
                EventBannerImage(
                  imageUrl: event.imageUrl,
                  category: event.category,
                  height: compact ? 76 : 112,
                  borderRadius: BorderRadius.circular(14),
                  overlay: _BannerBadges(
                    event: event,
                    categoryColor: categoryColor,
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EventDateBadge(isoDate: event.eventDate, size: 58),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ---------------------- badges ----------------------
                          Row(
                            children: [
                              _CategoryPill(
                                label: event.category,
                                color: categoryColor,
                                icon: EventTheme.categoryIcon(event.category),
                              ),
                              if (event.isFeatured) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: EventTheme.amber.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: EventTheme.amber.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: Text(
                                    'FEATURED',
                                    style: GoogleFonts.inter(
                                      color: EventTheme.amber,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),

                          // ----------------------- title -----------------------
                          Text(
                            event.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // --------------------- venue / time ------------------
                          _InfoLine(
                            icon: Icons.location_on_outlined,
                            text: event.city.isNotEmpty
                                ? '${event.venue}, ${event.city}'.trim()
                                : event.venue,
                          ),
                          const SizedBox(height: 3),
                          _InfoLine(
                            icon: Icons.schedule_rounded,
                            text:
                                '${EventTheme.prettyTime(event.startTime)} – ${EventTheme.prettyTime(event.endTime)}',
                          ),

                          if (event.distanceKm != null) ...[
                            const SizedBox(height: 3),
                            _InfoLine(
                              icon: Icons.near_me_rounded,
                              text: '${event.distanceKm} km away',
                              highlight: true,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (onSave != null)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: onSave,
                        icon: Icon(
                          event.isSaved
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: event.isSaved
                              ? EventTheme.secondary
                              : AppTheme.textMuted,
                        ),
                      ),
                  ],
                ),

                if (!compact) ...[
                  const SizedBox(height: 12),
                  Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
                  const SizedBox(height: 10),

                  // --------------------------- footer ---------------------------
                  Row(
                    children: [
                      // price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.isFree ? 'Free Entry' : 'Ticket price',
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
                              color: event.isFree
                                  ? EventTheme.green
                                  : EventTheme.primary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.capacity > 0
                                  ? '${event.attendeesCount} attending'
                                  : 'Open entry',
                              style: GoogleFonts.inter(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (soldOut)
                              Text(
                                'Sold out',
                                style: GoogleFonts.inter(
                                  color: EventTheme.secondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            else if (event.capacity > 0)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  minHeight: 4,
                                  value: (event.attendeesCount / event.capacity)
                                      .clamp(0.0, 1.0),
                                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    EventTheme.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (onMap != null)
                        IconButton(
                          tooltip: 'View on map',
                          onPressed: onMap,
                          icon: const Icon(
                            Icons.map_outlined,
                            color: EventTheme.teal,
                          ),
                        ),
                      SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EventTheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: Text(
                            'Details',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _CategoryPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _CategoryPill({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 5),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool highlight;

  const _InfoLine({required this.icon, required this.text, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 13,
          color: highlight ? EventTheme.teal : AppTheme.textMuted,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: highlight ? EventTheme.teal : AppTheme.textSecondary,
              fontSize: 11.5,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

/// Small chips drawn on top of the event banner image.
class _BannerBadges extends StatelessWidget {
  final EventItem event;
  final Color categoryColor;

  const _BannerBadges({required this.event, required this.categoryColor});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ---------------------- days-until chip (top left) ----------------------
        Positioned(
          top: 10,
          left: 10,
          child: _GlassChip(
            icon: Icons.timer_outlined,
            label: EventTheme.countdown(event.daysUntil),
            color: EventTheme.amber,
          ),
        ),

        // ------------------------ featured (top right) ------------------------
        if (event.isFeatured)
          Positioned(
            top: 10,
            right: 10,
            child: _GlassChip(
              icon: Icons.star_rounded,
              label: 'FEATURED',
              color: EventTheme.amber,
            ),
          ),

        // ---------------------- venue chip (bottom left) ----------------------
        Positioned(
          left: 10,
          bottom: 10,
          right: 10,
          child: Row(
            children: [
              Icon(
                EventTheme.categoryIcon(event.category),
                size: 14,
                color: categoryColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  event.city.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 6),
                    ],
                  ),
                ),
              ),
              if (event.distanceKm != null)
                _GlassChip(
                  icon: Icons.near_me_rounded,
                  label: '${event.distanceKm} km',
                  color: EventTheme.teal,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GlassChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _GlassChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
