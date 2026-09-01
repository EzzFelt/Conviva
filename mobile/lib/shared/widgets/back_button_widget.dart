import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';

enum BackButtonVariant {
  circular,
  plain,
}

class BackButtonWidget extends StatelessWidget {
  const BackButtonWidget({
    super.key,
    required this.onPressed,
    this.variant = BackButtonVariant.circular,
    this.color,
  });

  final VoidCallback onPressed;
  final BackButtonVariant variant;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sizes = context.appSizes;

    final iconColor = color ??
        (variant == BackButtonVariant.plain
            ? colorScheme.onPrimary
            : colorScheme.onSurface);
    final buttonContent = SizedBox.square(
      dimension: sizes.buttonSmall,
      child: Icon(
        Icons.arrow_back_ios_new_rounded,
        size: sizes.md,
        color: iconColor,
      ),
    );

    return Tooltip(
      message: 'Voltar',
      child: Semantics(
        button: true,
        label: 'Voltar',
        child: variant == BackButtonVariant.circular
            ? Material(
                color: colorScheme.surface,
                shape: CircleBorder(
                  side: BorderSide(color: colorScheme.outline),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onPressed,
                  child: buttonContent,
                ),
              )
            : Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onPressed,
                  child: buttonContent,
                ),
              ),
      ),
    );
  }
}
