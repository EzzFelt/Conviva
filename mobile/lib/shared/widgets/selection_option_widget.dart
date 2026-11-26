import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';

class SelectionOptionWidget extends StatelessWidget {
  const SelectionOptionWidget({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.semanticLabel,
    this.size,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final String? semanticLabel;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final backgroundColor = selected
        ? colorScheme.primary
        : colorScheme.primary.withValues(alpha: .22);
    final foregroundColor = selected
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: Material(
        color: backgroundColor,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onSelected(!selected),
          child: SizedBox.square(
            dimension: size ?? sizes.buttonSmall,
            child: Center(
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: foregroundColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
