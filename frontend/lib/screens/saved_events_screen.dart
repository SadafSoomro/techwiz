import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../theme/event_theme.dart';
import '../widgets/event_card.dart';
import '../widgets/event_scaffold.dart';
import '../widgets/event_widgets.dart';
import 'event_details_screen.dart';
import 'event_map_screen.dart';

/// MEMBER 4 - Events & Maps
/// "Interested" events the user saved for later.
class SavedEventsScreen extends StatefulWidget {
  const SavedEventsScreen({super.key});

  @override
  State<SavedEventsScreen> createState() => _SavedEventsScreenState();
}

class _SavedEventsScreenState extends State<SavedEventsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().loadSavedEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventProvider>();
    final events = provider.savedEvents;

    return EventScaffold(
      title: 'Interested Events',
      subtitle:
          '${events.length} saved event${events.length == 1 ? '' : 's'}',
      showHeaderGlow: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: () => context.read<EventProvider>().loadSavedEvents(),
        ),
      ],
      child: provider.loading && events.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: EventTheme.primary),
            )
          : events.isEmpty
              ? const EventEmptyState(
                  icon: Icons.favorite_border_rounded,
                  title: 'Nothing saved yet',
                  message:
                      'Tap the heart on any event to keep track of it here and\nget reminders before it starts.',
                )
              : RefreshIndicator(
                  color: EventTheme.primary,
                  onRefresh: () => context.read<EventProvider>().loadSavedEvents(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    children: [
                      // --------------------------- summary ---------------------------
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: EventTheme.secondary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: EventTheme.secondary.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.notifications_active_rounded,
                                color: EventTheme.secondary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'We will remind you before each saved event starts.',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ----------------------------- list -----------------------------
                      ...events.map(
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
                          onSave: () => context
                              .read<EventProvider>()
                              .toggleSave(event),
                          onMap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  EventMapScreen(focusEventId: event.id),
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
