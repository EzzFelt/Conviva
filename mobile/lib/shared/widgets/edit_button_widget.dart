import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';

enum EditButtonSize {
  small,
  medium,
  large,
}

class EditButtonWidget extends StatelessWidget {
  const EditButtonWidget({
    super.key,
    required this.onPressed,
    this.size = EditButtonSize.small,
    this.tooltip = 'Editar',
  });

  final VoidCallback? onPressed;
  final EditButtonSize size;
  final String tooltip;

  double _buttonSize(AppSizesTheme sizes) {
    return switch (size) {
      EditButtonSize.small => sizes.buttonSmall * .75,
      EditButtonSize.medium => sizes.buttonSmall,
      EditButtonSize.large => sizes.buttonMedium,
    };
  }

  double _iconSize(AppSizesTheme sizes) {
    return switch (size) {
      EditButtonSize.small => sizes.icon(sizes.md),
      EditButtonSize.medium => sizes.icon(sizes.lg),
      EditButtonSize.large => sizes.icon(sizes.xl),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sizes = context.appSizes;
    final enabled = onPressed != null;
    final backgroundColor = enabled
        ? colorScheme.primary
        : colorScheme.onSurface.withValues(alpha: .12);
    final foregroundColor = enabled
        ? colorScheme.onPrimary
        : colorScheme.onSurface.withValues(alpha: .38);

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: tooltip,
        excludeSemantics: true,
        child: Material(
          color: backgroundColor,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox.square(
              dimension: _buttonSize(sizes),
              child: Icon(
                Icons.edit_rounded,
                color: foregroundColor,
                size: _iconSize(sizes),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
