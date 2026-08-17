import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';

/// Botão principal com gradiente, no padrão visual do app (ex: "Vincular Parente").
///
/// Local sugerido: lib/shared/widgets/primary_gradient_button.dart
class PrimaryGradientButton extends StatelessWidget {
  const PrimaryGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    return Container(
      width: double.infinity,
      height: sizes.xxl + sizes.md,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: .75),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(sizes.xxl),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: .35),
            blurRadius: sizes.md,
            offset: Offset(0, sizes.xs),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(sizes.xxl),
          onTap: onPressed,
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}