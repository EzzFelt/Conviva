import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';
import 'goto_button_widget.dart';

enum InfoCardSize {
  small,
  medium,
  large,
}

class InfoCardWidget extends StatelessWidget {
  const InfoCardWidget({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.size = InfoCardSize.medium,
    this.showGotoButton = false,
    this.onPressed,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final InfoCardSize size;
  final bool showGotoButton;
  final VoidCallback? onPressed;

  double _leadingSize(AppSizesTheme sizes) {
    return switch (size) {
      InfoCardSize.small => sizes.buttonSmall * .75,
      InfoCardSize.medium => sizes.buttonSmall,
      InfoCardSize.large => sizes.buttonMedium,
    };
  }

  EdgeInsets _padding(AppSizesTheme sizes) {
    return switch (size) {
      InfoCardSize.small => EdgeInsets.symmetric(
          horizontal: sizes.sm,
          vertical: sizes.sm * 1.5,
        ),
      InfoCardSize.medium => EdgeInsets.symmetric(
          horizontal: sizes.md,
          vertical: sizes.md * 1.5,
        ),
      InfoCardSize.large => EdgeInsets.all(sizes.lg),
    };
  }

  GotoButtonSize _gotoButtonSize() {
    return switch (size) {
      InfoCardSize.small => GotoButtonSize.small,
      InfoCardSize.medium => GotoButtonSize.medium,
      InfoCardSize.large => GotoButtonSize.large,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final leadingSize = _leadingSize(sizes);

    return Material(
      color: colorScheme.surface,
      elevation: sizes.xs / 2,
      shadowColor: colorScheme.shadow.withValues(alpha: .24),
      borderRadius: BorderRadius.circular(sizes.radiusFull),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: _padding(sizes),
          child: Row(
            children: [
              SizedBox.square(
                dimension: leadingSize,
                child: leading,
              ),
              SizedBox(width: sizes.sm),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      subtitle,
                      maxLines: size == InfoCardSize.large ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (showGotoButton) ...[
                SizedBox(width: sizes.sm),
                GotoButtonWidget(size: _gotoButtonSize()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
