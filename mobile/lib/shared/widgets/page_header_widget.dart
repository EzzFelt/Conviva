import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';
import 'back_button_widget.dart';

class PageHeaderWidget extends StatelessWidget {
  const PageHeaderWidget({
    super.key,
    required this.title,
    required this.onBackPressed,
    this.trailing,
    this.titleLeading,
  });

  final String title;
  final VoidCallback onBackPressed;
  final Widget? trailing;
  final Widget? titleLeading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        sizes.lg,
        sizes.md,
        sizes.lg,
        sizes.md,
      ),
      child: SizedBox(
        height: sizes.buttonMedium,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: sizes.xxl),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (titleLeading != null) ...[
                      SizedBox.square(
                        dimension: sizes.buttonSmall,
                        child: titleLeading,
                      ),
                      SizedBox(width: sizes.sm),
                    ],
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: BackButtonWidget(
                onPressed: onBackPressed,
                variant: BackButtonVariant.plain,
              ),
            ),
            if (trailing != null)
              Align(
                alignment: Alignment.centerRight,
                child: trailing,
              ),
          ],
        ),
      ),
    );
  }
}
