import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';
import 'goto_button_widget.dart';

class BorderCardWidget extends StatelessWidget {
  const BorderCardWidget({
    super.key,
    required this.title,
    required this.description,
    this.leading,
    this.onTap,
    this.minimumHeight,
  });

  final Widget? leading;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final double? minimumHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final borderRadius = BorderRadius.circular(
      sizes.radiusMd + sizes.xs,
    );

    return Material(
      color: colorScheme.surface,
      elevation: 2,
      shadowColor: colorScheme.shadow.withValues(alpha: .25),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: colorScheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minimumHeight ?? 0),
          child: Padding(
            padding: EdgeInsets.all(sizes.md),
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (leading != null) ...[
                      leading!,
                      SizedBox(width: sizes.md),
                    ],
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: sizes.buttonSmall + sizes.sm,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: theme.textTheme.titleMedium,
                            ),
                            SizedBox(height: sizes.sm),
                            Text(
                              description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GotoButtonWidget(
                    onPressed: onTap,
                    size: GotoButtonSize.small,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
