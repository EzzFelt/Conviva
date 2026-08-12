import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import 'button_widget.dart';

enum ActionCardLayout {
  illustrationFirst,
  textFirst,
}

class ActionCardWidget extends StatelessWidget {
  const ActionCardWidget({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.onPressed,
    this.illustration,
    this.imageAsset,
    this.imageSemanticLabel,
    this.imageFit = BoxFit.contain,
    this.description,
    this.backgroundColor,
    this.illustrationBackgroundColor,
    this.showIllustrationBackground = true,
    this.illustrationSize,
    this.layout = ActionCardLayout.illustrationFirst,
  }) : assert(
          (illustration == null) != (imageAsset == null),
          'Informe illustration ou imageAsset, mas não os dois.',
        );

  final String title;
  final String? description;
  final Widget? illustration;
  final String? imageAsset;
  final String? imageSemanticLabel;
  final BoxFit imageFit;
  final String actionLabel;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? illustrationBackgroundColor;
  final bool showIllustrationBackground;
  final double? illustrationSize;
  final ActionCardLayout layout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final cardColor = backgroundColor ?? context.appGradientColors.bottom;
    final illustrationDimension = illustrationSize ?? sizes.xxl + sizes.xl;
    final illustrationContent = imageAsset != null
        ? Image.asset(
            imageAsset!,
            fit: imageFit,
            semanticLabel: imageSemanticLabel,
          )
        : illustration!;
    final framedIllustration = Container(
      width: illustrationDimension,
      height: illustrationDimension,
      padding: showIllustrationBackground
          ? EdgeInsets.all(sizes.sm)
          : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: showIllustrationBackground
            ? illustrationBackgroundColor ??
                colorScheme.primary.withValues(alpha: .82)
            : Colors.transparent,
        shape: BoxShape.circle,
      ),
      clipBehavior:
          showIllustrationBackground ? Clip.antiAlias : Clip.none,
      alignment: Alignment.center,
      child: illustrationContent,
    );
    final textContent = SizedBox(
      width: double.infinity,
      height: sizes.xxl + sizes.lg,
      child: Center(
        child: FractionallySizedBox(
          widthFactor: .86,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onPrimary,
                ),
              ),
              if (description != null) ...[
                SizedBox(height: sizes.sm),
                Text(
                  description!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onPrimary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(sizes.radiusLg),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: .18),
              blurRadius: sizes.sm,
              offset: Offset(0, sizes.xs),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: sizes.lg,
            vertical: sizes.xl + sizes.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (layout == ActionCardLayout.illustrationFirst) ...[
                framedIllustration,
                SizedBox(height: sizes.lg),
              ],
              textContent,
              if (layout == ActionCardLayout.textFirst) ...[
                SizedBox(height: sizes.lg),
                framedIllustration,
              ],
              SizedBox(height: sizes.lg),
              FractionallySizedBox(
                widthFactor: .72,
                child: ButtonWidget(
                  label: actionLabel,
                  size: ButtonSize.medium,
                  variant: ButtonVariant.primary,
                  onPressed: onPressed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
