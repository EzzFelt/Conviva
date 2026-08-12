import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';
import 'goto_button_widget.dart';

class BorderCardWidget extends StatelessWidget {
  const BorderCardWidget({
    super.key,
    required this.leading,
    required this.title,
    required this.description,
    this.onTap,
  });

  final Widget leading;
  final String title;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final borderRadius = BorderRadius.circular(sizes.radiusLg);

    return Material(
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: colorScheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(sizes.md),
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leading,
                  SizedBox(width: sizes.md),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: sizes.buttonSmall + sizes.sm,
                      ),
                      child: Column(
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
              const Positioned(
                right: 0,
                bottom: 0,
                child: GotoButtonWidget(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
