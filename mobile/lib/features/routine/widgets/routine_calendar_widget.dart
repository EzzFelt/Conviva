import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_colors.dart';
import '../models/routine_task.dart';

class RoutineCalendarWidget extends StatelessWidget {
  const RoutineCalendarWidget({
    super.key,
    required this.month,
    required this.selectedDay,
    required this.eventLoader,
    required this.onDaySelected,
  });

  final DateTime month;
  final DateTime selectedDay;
  final List<RoutineTask> Function(DateTime day) eventLoader;
  final ValueChanged<DateTime> onDaySelected;

  static const _monthNames = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  static const _weekdayLabels = [
    'Seg',
    'Ter',
    'Qua',
    'Qui',
    'Sex',
    'Sáb',
    'Dom',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final firstDay = DateTime(month.year, month.month);
    final lastDay = DateTime(month.year, month.month + 1, 0);

    return Column(
      children: [
        Text(
          _monthNames[month.month - 1],
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineLarge?.copyWith(
            color: context.appGradientColors.bottom,
          ),
        ),
        SizedBox(height: sizes.md),
        Material(
          color: colorScheme.surface,
          elevation: sizes.xs / 2,
          shadowColor: colorScheme.shadow.withValues(alpha: .22),
          borderRadius: BorderRadius.circular(sizes.radiusMd),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: sizes.xs,
              vertical: sizes.sm,
            ),
            child: TableCalendar<RoutineTask>(
              firstDay: firstDay,
              lastDay: lastDay,
              focusedDay: firstDay,
              currentDay: DateTime.now(),
              headerVisible: false,
              calendarFormat: CalendarFormat.month,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Mês',
              },
              availableGestures: AvailableGestures.none,
              startingDayOfWeek: StartingDayOfWeek.sunday,
              rowHeight: sizes.buttonSmall,
              daysOfWeekHeight: sizes.xl,
              selectedDayPredicate: (day) => isSameDay(selectedDay, day),
              eventLoader: eventLoader,
              onDaySelected: (selected, _) => onDaySelected(selected),
              calendarBuilders: CalendarBuilders<RoutineTask>(
                dowBuilder: (context, day) {
                  return Center(
                    child: Text(
                      _weekdayLabels[day.weekday - 1],
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                markerSize: sizes.xs,
                markersMaxCount: 1,
                markerDecoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: .20),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: theme.textTheme.bodyMedium!.copyWith(
                  color: colorScheme.onPrimary,
                ),
                todayTextStyle: theme.textTheme.bodyMedium!.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
                defaultTextStyle: theme.textTheme.bodyMedium!,
                weekendTextStyle: theme.textTheme.bodyMedium!,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
