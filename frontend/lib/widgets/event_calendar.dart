import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/event_models.dart';
import '../theme/app_theme.dart';
import '../theme/event_theme.dart';

/// MEMBER 4 - Events & Maps
/// Month grid used by the Calendar screen. Days that have events show a
/// coloured dot (and a small count badge when there is more than one).
class EventMonthCalendar extends StatelessWidget {
  final DateTime month;
  final List<CalendarDay> days;
  final DateTime selectedDay;
  final void Function(DateTime day) onSelectDay;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const EventMonthCalendar({
    super.key,
    required this.month,
    required this.days,
    required this.selectedDay,
    required this.onSelectDay,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  /// "YYYY-MM-DD" -> day data
  Map<String, CalendarDay> get _byDate => {
        for (final day in days) day.date: day,
      };

  String _key(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final lookup = _byDate;

    final firstOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    // Monday = 0 ... Sunday = 6
    final leading = (firstOfMonth.weekday - 1) % 7;
    final totalCells = ((leading + daysInMonth) / 7).ceil() * 7;

    final today = DateTime.now();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: EventTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          // --------------------------- header ---------------------------
          Row(
            children: [
              IconButton(
                onPressed: onPreviousMonth,
                icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${EventTheme.monthNames[month.month - 1]} ${month.year}',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${days.length} day${days.length == 1 ? '' : 's'} with events',
                      style: GoogleFonts.inter(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onNextMonth,
                icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // -------------------------- weekdays --------------------------
          Row(
            children: EventTheme.weekdayShort
                .map(
                  (label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: GoogleFonts.inter(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),

          // ---------------------------- grid ----------------------------
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 0.86,
            ),
            itemBuilder: (context, index) {
              final dayNumber = index - leading + 1;

              // empty leading / trailing cells
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }

              final date = DateTime(month.year, month.month, dayNumber);
              final key = _key(date);
              final entry = lookup[key];

              return _DayCell(
                day: dayNumber,
                eventCount: entry?.count ?? 0,
                isSelected: _key(selectedDay) == key,
                isToday: _key(today) == key,
                isWeekend: date.weekday >= 6,
                onTap: () => onSelectDay(date),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final int eventCount;
  final bool isSelected;
  final bool isToday;
  final bool isWeekend;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.eventCount,
    required this.isSelected,
    required this.isToday,
    required this.isWeekend,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasEvents = eventCount > 0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          gradient: isSelected ? EventTheme.headerGradient : null,
          color: isSelected
              ? null
              : hasEvents
                  ? EventTheme.primary.withValues(alpha: 0.10)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : isToday
                    ? EventTheme.primary.withValues(alpha: 0.7)
                    : hasEvents
                        ? EventTheme.primary.withValues(alpha: 0.28)
                        : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: GoogleFonts.outfit(
                color: isSelected
                    ? Colors.white
                    : hasEvents
                        ? Colors.white
                        : isWeekend
                            ? AppTheme.textMuted
                            : AppTheme.textSecondary,
                fontSize: 13.5,
                fontWeight:
                    isSelected || hasEvents ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 3),
            if (hasEvents)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.28)
                      : EventTheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  eventCount > 1 ? '$eventCount' : '•',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
              )
            else
              const SizedBox(height: 11),
          ],
        ),
      ),
    );
  }
}
