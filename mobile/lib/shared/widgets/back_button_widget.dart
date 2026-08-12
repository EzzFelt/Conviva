import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';

class BackButtonWidget extends StatelessWidget {
  const BackButtonWidget({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sizes = context.appSizes;

    return Tooltip(
      message: 'Voltar',
      child: Semantics(
        button: true,
        label: 'Voltar',
        child: Material(
          color: colorScheme.surface,
          shape: CircleBorder(
            side: BorderSide(color: colorScheme.outline),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox.square(
              dimension: sizes.buttonSmall,
              child: Icon(
                Icons.arrow_back_ios_new,
                size: sizes.md,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
