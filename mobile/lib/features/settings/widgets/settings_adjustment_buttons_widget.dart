import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/button_widget.dart';

class SettingsAdjustmentButtonsWidget extends StatelessWidget {
  const SettingsAdjustmentButtonsWidget({
    super.key,
    required this.onIncrease,
    required this.onDecrease,
  });

  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    return Row(
      children: [
        Expanded(
          child: ButtonWidget(
            label: 'Aumentar',
            size: ButtonSize.small,
            variant: ButtonVariant.secondary,
            onPressed: onIncrease,
          ),
        ),
        SizedBox(width: sizes.sm),
        Expanded(
          child: Theme(
            data: theme.copyWith(
              colorScheme: colorScheme.copyWith(
                primary: colorScheme.onSurfaceVariant,
              ),
            ),
            child: ButtonWidget(
              label: 'Diminuir',
              size: ButtonSize.small,
              variant: ButtonVariant.outlined,
              onPressed: onDecrease,
            ),
          ),
        ),
      ],
    );
  }
}
