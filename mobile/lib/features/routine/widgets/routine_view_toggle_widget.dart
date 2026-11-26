import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/button_widget.dart';

enum RoutineViewMode {
  day,
  allDays,
}

class RoutineViewToggleWidget extends StatelessWidget {
  const RoutineViewToggleWidget({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final RoutineViewMode value;
  final ValueChanged<RoutineViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final sizes = context.appSizes;

    return Row(
      children: [
        Expanded(
          child: ButtonWidget(
            label: 'Hoje',
            size: ButtonSize.small,
            variant: value == RoutineViewMode.day
                ? ButtonVariant.primary
                : ButtonVariant.outlined,
            onPressed: () => onChanged(RoutineViewMode.day),
          ),
        ),
        SizedBox(width: sizes.md),
        Expanded(
          child: ButtonWidget(
            label: 'Todos os dias',
            size: ButtonSize.small,
            variant: value == RoutineViewMode.allDays
                ? ButtonVariant.primary
                : ButtonVariant.outlined,
            onPressed: () => onChanged(RoutineViewMode.allDays),
          ),
        ),
      ],
    );
  }
}
