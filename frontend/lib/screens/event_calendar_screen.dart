import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/event_models.dart';
import '../providers/event_provider.dart';
import '../theme/app_theme.dart';
import '../theme/event_theme.dart';
import '../widgets/event_calendar.dart';
import '../widgets/event_card.dart';
import '../widgets/event_scaffold.dart';
import '../widgets/event_widgets.dart';
import 'event_details_screen.dart';

/// MEMBER 4 - Events & Maps
/// Event Calendar screen: month grid with event dots, city / category
/// filters and the list of events for the selected day.
class EventCalendarScreen extends StatefulWidget {
  const EventCalendarScreen({super.key});

  @override
  State<EventCalendarScreen> createState() => _EventCalendarScreenState();
}

class _EventCalendarScreenState extends State<EventCalendarScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<EventProvider>();
      provider.loadCalendar();
      if (provider.categories.isEmpty) provider.loadFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventProvider>();
    final dayEvents = provider.selectedDayEvents;

    final today = DateTime.now();
    final monthLabel =
        '${EventTheme.monthNames[provider.calendarMonth.month - 1]} ${provider.calendarMonth.year}';

    return EventScaffold(
      title: 'Calendar',
      subtitle: 'Conventions, meetups & screenings by date',
      actions: [
        TextButton(
          onPressed: () => context.read<EventProvider>().goToMonth(today),
          child: Text(
            'Today',
            style: GoogleFonts.inter(
              color: EventTheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
      child: RefreshIndicator(
        color: EventTheme.primary,
        onRefresh: () => context.read<EventProvider>().loadCalendar(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 26),
          children: [
            // --------------------------- summary ---------------------------
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: EventTheme.headerGradient,
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
                    child: const Icon(Icons.calendar_month_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          monthLabel,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${provider.calendarDays.length} event days this month',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // --------------------------- filters ---------------------------
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  EventFilterChip(
                    label: 'All cities',
                    icon: Icons.public_rounded,
                    selected: provider.city == 'All',
                    onTap: () => context
                        .read<EventProvider>()
                        .loadCalendar(city: 'All'),
                  ),
                  ...provider.cities.map(
                    (city) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: EventFilterChip(
                        label: city.city,
                        selected: provider.city == city.city,
                        onTap: () => context
                            .read<EventProvider>()
                            .loadCalendar(city: city.city),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  EventFilterChip(
                    label: 'All types',
                    selected: provider.category == 'All',
                    accentColor: EventTheme.secondary,
                    onTap: () => context
                        .read<EventProvider>()
                        .loadCalendar(category: 'All'),
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
                            .loadCalendar(category: category.name),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // -------------------------- the month --------------------------
            EventMonthCalendar(
              month: provider.calendarMonth,
              days: provider.calendarDays,
              selectedDay: provider.selectedDay,
              onSelectDay: (day) => context.read<EventProvider>().selectDay(day),
              onPreviousMonth: () =>
                  context.read<EventProvider>().changeMonth(-1),
              onNextMonth: () => context.read<EventProvider>().changeMonth(1),
            ),
            const SizedBox(height: 22),

            // ------------------------ selected day ------------------------
            EventSectionTitle(
              EventTheme.prettyDate(
                '${provider.selectedDay.year}-'
                '${provider.selectedDay.month.toString().padLeft(2, '0')}-'
                '${provider.selectedDay.day.toString().padLeft(2, '0')}',
              ),
              trailing: Text(
                '${dayEvents.length} event${dayEvents.length == 1 ? '' : 's'}',
                style: GoogleFonts.inter(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (provider.loading && provider.calendarDays.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 50),
                child: Center(
                  child: CircularProgressIndicator(color: EventTheme.primary),
                ),
              )
            else if (dayEvents.isEmpty)
              const EventEmptyState(
                icon: Icons.event_note_rounded,
                title: 'No events on this date',
                message:
                    'Pick another highlighted day on the calendar to see\nwhat is happening.',
              )
            else
              ...dayEvents.map(
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
                  onSave: () =>
                      context.read<EventProvider>().toggleSave(event),
                ),
              ),

            // --------------------- upcoming in this month ---------------------
            if (provider.calendarDays.isNotEmpty) ...[
              const SizedBox(height: 14),
              const EventSectionTitle('All events this month'),
              const SizedBox(height: 12),
              ..._monthDays(provider),
            ],
          ],
        ),
      ),
    );
  }

  /// Flattens the grouped calendar days into a single ordered list.
  List<Widget> _monthDays(EventProvider provider) {
    final widgets = <Widget>[];

    for (final day in provider.calendarDays) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(left: 2, top: 4, bottom: 8),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: EventTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                EventTheme.prettyDate(day.date),
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '· ${day.count} event${day.count == 1 ? '' : 's'}',
                style: GoogleFonts.inter(
                  color: AppTheme.textMuted,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      );

      for (final EventItem event in day.events) {
        widgets.add(
          EventCard(
            event: event,
            compact: true,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EventDetailsScreen(
                  eventId: event.id,
                  event: event,
                ),
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }
}
