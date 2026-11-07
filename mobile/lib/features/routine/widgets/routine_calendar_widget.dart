
import 'package:flutter/material.dart';

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

  // Domingo como primeiro dia da semana.
  static const _weekdayLabels = [
    'Dom',
    'Seg',
    'Ter',
    'Qua',
    'Qui',
    'Sex',
    'Sáb',
  ];

  Widget _weekdayHeader(
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final sizes = context.appSizes;

    return Row(
      children: [
        for (final label in _weekdayLabels)
          Expanded(
            child: SizedBox(
              height: sizes.xl,
              child: Center(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _dayCell(
    BuildContext context,
    DateTime day,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    final isSelected = DateUtils.isSameDay(
      selectedDay,
      day,
    );

    final isToday = DateUtils.isSameDay(
      DateTime.now(),
      day,
    );

    // O eventLoader do RoutinePage já utiliza o índice
    // de eventos por mês, evitando filtrar todas as tarefas.
    final hasEvents = eventLoader(day).isNotEmpty;

    final backgroundColor = isSelected
        ? colorScheme.primary
        : isToday
            ? colorScheme.primary.withValues(alpha: .20)
            : Colors.transparent;

    final textColor = isSelected
        ? colorScheme.onPrimary
        : isToday
            ? colorScheme.primary
            : colorScheme.onSurface;

    return Expanded(
      child: SizedBox(
        height: sizes.buttonSmall,
        child: Center(
          child: SizedBox(
            width: sizes.buttonSmall,
            height: sizes.buttonSmall,
            child: Material(
              color: backgroundColor,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => onDaySelected(day),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      day.day.toString(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textColor,
                        fontWeight: isSelected || isToday
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    SizedBox(height: sizes.xs / 2),
                    Container(
                      width: sizes.xs,
                      height: sizes.xs,
                      decoration: BoxDecoration(
                        color: hasEvents
                            ? isSelected
                                ? colorScheme.onPrimary
                                : colorScheme.primary
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyCell(
    BuildContext context,
  ) {
    return Expanded(
      child: SizedBox(
        height: context.appSizes.buttonSmall,
      ),
    );
  }

  Widget _calendarGrid(
    BuildContext context,
    DateTime firstDay,
    int daysInMonth,
  ) {
    // DateTime.weekday: segunda = 1 ... domingo = 7.
    // O módulo 7 faz o domingo ocupar a primeira coluna.
    final leadingEmptyCells = firstDay.weekday % 7;

    final totalCells = leadingEmptyCells + daysInMonth;

    final weekCount = (totalCells + 6) ~/ 7;

    return Column(
      children: [
        _weekdayHeader(context),
        SizedBox(height: context.appSizes.xs),
        for (var week = 0; week < weekCount; week++)
          Row(
            children: [
              for (var weekday = 0; weekday < 7; weekday++)
                _buildCell(
                  context,
                  week * 7 + weekday,
                  leadingEmptyCells,
                  daysInMonth,
                  firstDay,
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildCell(
    BuildContext context,
    int index,
    int leadingEmptyCells,
    int daysInMonth,
    DateTime firstDay,
  ) {
    final dayNumber = index - leadingEmptyCells + 1;

    if (dayNumber < 1 || dayNumber > daysInMonth) {
      return _emptyCell(context);
    }

    final day = DateTime(
      firstDay.year,
      firstDay.month,
      dayNumber,
    );

    return _dayCell(context, day);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    final firstDay = DateTime(
      month.year,
      month.month,
    );

    final lastDay = DateTime(
      month.year,
      month.month + 1,
      0,
    );

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
          shadowColor: colorScheme.shadow.withValues(
            alpha: .22,
          ),
          borderRadius: BorderRadius.circular(
            sizes.radiusMd,
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: sizes.xs,
              vertical: sizes.sm,
            ),
            child: _calendarGrid(
              context,
              firstDay,
              lastDay.day,
            ),
          ),
        ),
      ],
    );
  }
}
