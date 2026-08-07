import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';

class GotoButtonWidget extends StatelessWidget {
  const GotoButtonWidget({
    super.key,
    this.onPressed,
    this.semanticLabel = 'Avançar',
  });

  final VoidCallback? onPressed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sizes = context.appSizes;

    final content = Material(
      color: colorScheme.primary,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox.square(
          dimension: sizes.buttonSmall,
          child: Icon(
            Icons.arrow_forward_ios,
            size: sizes.md,
            color: colorScheme.onPrimary,
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
