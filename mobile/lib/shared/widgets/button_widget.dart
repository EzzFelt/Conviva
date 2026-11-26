import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

enum ButtonVariant {
  primary,
  secondary,
  surface,
  outlined,
}

enum ButtonSize {
  small,
  medium,
  large,
}

class ButtonWidget extends StatelessWidget {
  const ButtonWidget({
    super.key,
    this.label = 'Continuar',
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
  });

  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;

  double _height(AppSizesTheme sizes) {
    switch (size) {
      case ButtonSize.small:
        return sizes.buttonSmall;
      case ButtonSize.medium:
        return sizes.buttonMedium;
      case ButtonSize.large:
        return sizes.buttonLarge;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final (backgroundColor, foregroundColor, borderSide) = switch (variant) {
      ButtonVariant.primary => (
          colorScheme.primary,
          colorScheme.onPrimary,
          BorderSide.none,
        ),
      ButtonVariant.secondary => (
          context.appGradientColors.bottom,
          colorScheme.onPrimary,
          BorderSide.none,
        ),
      ButtonVariant.surface => (
          colorScheme.surface,
          colorScheme.primary,
          BorderSide.none,
        ),
      ButtonVariant.outlined => (
          colorScheme.surface,
          colorScheme.primary,
          BorderSide(color: colorScheme.primary),
        ),
    };

    // Altura mínima (e não fixa): com fonte grande o texto quebra em duas
    // linhas e o botão cresce em vez de cortar o rótulo.
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity, _height(sizes)),
          elevation: variant == ButtonVariant.outlined ? 0 : 1,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor:
              colorScheme.onSurface.withValues(alpha: .12),
          disabledForegroundColor:
              colorScheme.onSurface.withValues(alpha: .38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(sizes.radiusFull),
            side: borderSide,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge?.copyWith(
            color: onPressed == null ? null : foregroundColor,
          ),
        ),
      ),
    );
  }
}
