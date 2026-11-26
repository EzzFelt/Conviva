import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';

enum GotoButtonSize {
  small,
  medium,
  large,
}

class GotoButtonWidget extends StatelessWidget {
  const GotoButtonWidget({
    super.key,
    this.onPressed,
    this.semanticLabel = 'Avançar',
    this.size = GotoButtonSize.medium,
  });

  final VoidCallback? onPressed;
  final String semanticLabel;
  final GotoButtonSize size;

  double _visualSize(AppSizesTheme sizes) {
    return switch (size) {
      GotoButtonSize.small => sizes.xl,
      GotoButtonSize.medium => sizes.buttonSmall,
      GotoButtonSize.large => sizes.buttonMedium,
    };
  }

  double _iconSize(AppSizesTheme sizes) {
    return switch (size) {
      GotoButtonSize.small => sizes.sm + sizes.xs / .75,
      GotoButtonSize.medium => sizes.md,
      GotoButtonSize.large => sizes.lg,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sizes = context.appSizes;
    final visualSize = _visualSize(sizes);
    final tapSize = size == GotoButtonSize.small
        ? sizes.buttonSmall
        : visualSize;

    final content = SizedBox.square(
      dimension: tapSize,
      child: Center(
        child: Material(
          color: colorScheme.primary,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox.square(
              dimension: visualSize,
              child: Icon(
                Icons.arrow_forward_ios,
                size: sizes.icon(_iconSize(sizes)),
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );

    if (onPressed == null) {
      return ExcludeSemantics(child: content);
    }

    return Tooltip(
      message: semanticLabel,
      child: Semantics(
        button: true,
        label: semanticLabel,
        child: content,
      ),
    );
  }
}
