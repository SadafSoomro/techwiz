import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/event_models.dart';
import '../providers/event_provider.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../theme/event_theme.dart';
import '../widgets/event_map_view.dart';
import '../widgets/event_scaffold.dart';
import '../widgets/event_widgets.dart';
import 'event_details_screen.dart';

/// MEMBER 4 - Events & Maps
/// Map screen: stylised map with a pin for every upcoming event, GPS style
/// "nearby" discovery and a card for the selected event.
/// [focusEventId] opens the map centred on one specific event
/// ("Event Details - Map View").
class EventMapScreen extends StatefulWidget {
  final int? focusEventId;

  const EventMapScreen({super.key, this.focusEventId});

  @override
  State<EventMapScreen> createState() => _EventMapScreenState();
}

class _EventMapScreenState extends State<EventMapScreen> {
  int? _selectedPinId;
  int _locateTrigger = 0;

  @override
  void initState() {
    super.initState();
    _selectedPinId = widget.focusEventId;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<EventProvider>();
      final savedLoc = await LocationService.getSavedLocation();

      if (savedLoc != null) {
        provider.useDeviceLocation(
          lat: savedLoc.latitude,
          lng: savedLoc.longitude,
          city: savedLoc.city,
          area: savedLoc.area,
        );
        provider.loadMapPins(city: savedLoc.city);
        provider.loadNearby(radiusKm: 200);
      } else {
        try {
          final live = await LocationService.detectCurrentLocation();
          await LocationService.saveLocation(live);
          if (mounted) {
            provider.useDeviceLocation(
              lat: live.latitude,
              lng: live.longitude,
              city: live.city,
              area: live.area,
            );
            provider.loadMapPins(city: live.city);
            provider.loadNearby(radiusKm: 200);
            setState(() => _locateTrigger++);
          }
        } catch (_) {
          provider.loadMapPins();
          provider.loadNearby(radiusKm: 2000);
        }
      }
      if (provider.categories.isEmpty) provider.loadFilters();
    });
  }

  EventItem? _eventFor(int? pinId, EventProvider provider) {
    if (pinId == null) return null;
    for (final event in provider.nearbyEvents) {
      if (event.id == pinId) return event;
    }
    for (final event in provider.events) {
      if (event.id == pinId) return event;
    }
    return provider.savedEvents.where((e) => e.id == pinId).firstOrNull;
  }

  /// "My location": re-acquires the device fix, recentres the map and
  /// zooms directly into that exact location.
  Future<void> _locateMe() async {
    final provider = context.read<EventProvider>();

    final displayLoc = await provider.recenterOnDeviceLocation();
    if (!mounted) return;

    setState(() {
      _selectedPinId = null;
      _locateTrigger++;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '📍 Location traced: $displayLoc • ${provider.mapPins.length} nearby events (Cosplay, Meetups, Screenings) loaded!',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          backgroundColor: EventTheme.teal,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventProvider>();
    final selectedEvent = _eventFor(_selectedPinId, provider);

    return EventScaffold(
      title: 'Nearby Events',
      subtitle: '${provider.mapPins.length} events on the map',
      showHeaderGlow: false,
      actions: [
        IconButton(
          tooltip: 'My location',
          icon: const Icon(Icons.my_location_rounded, color: EventTheme.teal),
          onPressed: _locateMe,
        ),
      ],
      child: Stack(
        children: [
          // ----------------------------- the map -----------------------------
          Positioned.fill(
            child: provider.mapPins.isEmpty && provider.loading
                ? const Center(
                    child: CircularProgressIndicator(color: EventTheme.primary),
                  )
                : EventMapView(
                    pins: provider.mapPins,
                    selectedPinId: _selectedPinId,
                    currentLatitude: provider.latitude,
                    currentLongitude: provider.longitude,
                    currentLabel: provider.currentArea.isNotEmpty ? provider.currentArea : provider.currentCity,
                    locateTrigger: _locateTrigger,
                    // Keep the compass / "you are here" chip clear of the
                    // filter bar and the scale bar clear of the bottom card.
                    overlayPadding: EdgeInsets.only(
                      top: provider.currentArea.isNotEmpty ? 116 : 88,
                      bottom: selectedEvent != null ? 158 : 138,
                    ),
                    onPinTap: (pin) => setState(() => _selectedPinId = pin.id),
                  ),
          ),

          // --------------------------- top filters ---------------------------
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _MapFilterBar(
              provider: provider,
              onChanged: (city, category) {
                final p = context.read<EventProvider>();
                p.loadMapPins(
                  city: city,
                  category: category,
                );
                p.loadNearby(radiusKm: city == 'All' ? 2000 : 80);
                setState(() => _selectedPinId = null);
              },
            ),
          ),

          // ------------------------- selected event card -------------------------
          if (selectedEvent != null)
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: _SelectedEventCard(
                event: selectedEvent,
                onClose: () => setState(() => _selectedPinId = null),
                onDetails: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EventDetailsScreen(
                      eventId: selectedEvent.id,
                      event: selectedEvent,
                    ),
                  ),
                ),
                onSave: () =>
                    context.read<EventProvider>().toggleSave(selectedEvent),
              ),
            )
          else
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _NearbyCarousel(
                events: provider.nearbyEvents,
                onTap: (event) {
                  setState(() => _selectedPinId = event.id);
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top filter bar
// ---------------------------------------------------------------------------
class _MapFilterBar extends StatelessWidget {
  final EventProvider provider;
  final void Function(String city, String category) onChanged;

  const _MapFilterBar({required this.provider, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.backgroundColor.withValues(alpha: 0.95),
            AppTheme.backgroundColor.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (provider.currentArea.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 2),
              child: Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: EventTheme.teal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: EventTheme.teal.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.near_me_rounded, size: 12, color: EventTheme.teal),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Your Area: ${provider.displayLocation}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: EventTheme.teal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                EventFilterChip(
                  label: 'All cities',
                  icon: Icons.public_rounded,
                  selected: provider.city == 'All',
                  onTap: () => onChanged('All', provider.category),
                ),
                ...provider.cities.map(
                  (city) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: EventFilterChip(
                      label: city.city,
                      selected: provider.city == city.city,
                      onTap: () => onChanged(city.city, provider.category),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                EventFilterChip(
                  label: 'All types',
                  selected: provider.category == 'All',
                  accentColor: EventTheme.secondary,
                  onTap: () => onChanged(provider.city, 'All'),
                ),
                ...provider.categories.map(
                  (category) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: EventFilterChip(
                      label: category.name,
                      icon: EventTheme.iconFor(category.icon),
                      accentColor: EventTheme.fromHex(category.color),
                      selected: provider.category == category.name,
                      onTap: () => onChanged(provider.city, category.name),
                    ),
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

// ---------------------------------------------------------------------------
// Card for the tapped pin
// ---------------------------------------------------------------------------
class _SelectedEventCard extends StatelessWidget {
  final EventItem event;
  final VoidCallback onClose;
  final VoidCallback onDetails;
  final VoidCallback onSave;

  const _SelectedEventCard({
    required this.event,
    required this.onClose,
    required this.onDetails,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final color = EventTheme.categoryColor(event.category);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EventTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EventDateBadge(isoDate: event.eventDate, size: 50),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(EventTheme.categoryIcon(event.category),
                            size: 12, color: color),
                        const SizedBox(width: 5),
                        Text(
                          event.category.toUpperCase(),
                          style: GoogleFonts.inter(
                            color: color,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close_rounded,
                    color: AppTheme.textMuted, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 13, color: AppTheme.textMuted),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '${event.venue}, ${event.city}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              if (event.distanceKm != null)
                Text(
                  '${event.distanceKm} km',
                  style: GoogleFonts.inter(
                    color: EventTheme.teal,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSave,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: event.isSaved
                          ? EventTheme.secondary
                          : Colors.white.withValues(alpha: 0.15),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    event.isSaved
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 17,
                    color: event.isSaved
                        ? EventTheme.secondary
                        : AppTheme.textSecondary,
                  ),
                  label: Text(
                    event.isSaved ? 'Interested' : 'Interested?',
                    style: GoogleFonts.inter(
                      color: event.isSaved
                          ? EventTheme.secondary
                          : AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EventTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                  label: Text(
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Horizontal carousel shown when nothing is selected
// ---------------------------------------------------------------------------
class _NearbyCarousel extends StatelessWidget {
  final List<EventItem> events;
  final void Function(EventItem event) onTap;

  const _NearbyCarousel({required this.events, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            AppTheme.backgroundColor.withValues(alpha: 0.96),
            AppTheme.backgroundColor.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Tap a pin or pick from ${events.length} nearby events',
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
                fontSize: 11.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 92,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                final color = EventTheme.categoryColor(event.category);

                return GestureDetector(
                  onTap: () => onTap(event),
                  child: Container(
                    width: 220,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: EventTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(EventTheme.categoryIcon(event.category),
                                size: 12, color: color),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                event.category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (event.distanceKm != null)
                              Text(
                                '${event.distanceKm} km',
                                style: GoogleFonts.inter(
                                  color: EventTheme.teal,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Text(
                            event.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              height: 1.25,
                            ),
                          ),
                        ),
                        Text(
                          '${event.city} · ${EventTheme.prettyDate(event.eventDate)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: AppTheme.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
