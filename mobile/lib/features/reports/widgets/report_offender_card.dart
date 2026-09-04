import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';

class ReportOffenderCard extends StatelessWidget {
  const ReportOffenderCard({
    super.key,
    required this.label,
    required this.illustration,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Widget illustration;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final borderRadius = BorderRadius.circular(sizes.radiusLg);
    final borderColor = selected ? colorScheme.primary : colorScheme.outline;

    return Material(
      color: colorScheme.surface,
      elevation: sizes.xs / 2,
      shadowColor: colorScheme.shadow.withValues(alpha: .18),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(
          color: borderColor,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: sizes.xxl * 2),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: sizes.lg,
              vertical: sizes.md,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: sizes.xxl * 1.6,
                  height: sizes.xxl * 1.4,
                  child: illustration,
                ),
                SizedBox(width: sizes.lg),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: selected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
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
