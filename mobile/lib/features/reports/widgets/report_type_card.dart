import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/goto_button_widget.dart';

class ReportTypeCard extends StatelessWidget {
  const ReportTypeCard({
    super.key,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final String title;
  final String description;
  final VoidCallback onTap;

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
        side: BorderSide(color: colorScheme.primary, width: 1.4),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(sizes.lg),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(right: sizes.buttonSmall),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: sizes.sm),
                    Text(
                      description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
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
