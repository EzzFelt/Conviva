import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

enum NextTaskType {
  breakfast,
  medication,
  lunch,
  walk,
}

class NextTaskCard extends StatelessWidget {
  const NextTaskCard({
    super.key,
    required this.taskType,
    this.sectionTitle = 'Sua próxima tarefa:',
    this.onPressed,
  });

  final NextTaskType taskType;
  final String sectionTitle;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final taskContent = switch (taskType) {
      NextTaskType.breakfast => (
          icon: Icons.breakfast_dining_rounded,
          title: 'Café da manhã',
          time: '7:00 - 7:40',
        ),
      NextTaskType.medication => (
          icon: Icons.medication_rounded,
          title: 'Tomar remédio',
          time: '9:00 - 9:10',
        ),
      NextTaskType.lunch => (
          icon: Icons.lunch_dining_rounded,
          title: 'Almoço',
          time: '12:00 - 12:40',
        ),
      NextTaskType.walk => (
          icon: Icons.directions_walk_rounded,
          title: 'Caminhada',
          time: '16:00 - 16:30',
        ),
    };

    final cardRadius = BorderRadius.circular(
      sizes.radiusMd + sizes.xs,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: sizes.sm),
          child: Text(
            sectionTitle,
            style: theme.textTheme.titleLarge,
          ),
        ),
        SizedBox(height: sizes.lg),
        Padding(
          padding: EdgeInsets.only(bottom: sizes.md),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: context.appGradientColors.bottom,
                elevation: sizes.xs / 2,
                shadowColor: colorScheme.shadow.withValues(alpha: .24),
                shape: RoundedRectangleBorder(
                  borderRadius: cardRadius,
                  side: BorderSide(
                    color: colorScheme.primary.withValues(alpha: .32),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onPressed,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: sizes.xxl * 2 + sizes.md,
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: sizes.xl,
                        right: sizes.xl,
                        top: sizes.lg,
                        bottom: sizes.lg,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            taskContent.icon,
                            size: sizes.xxl + sizes.md,
                            color: colorScheme.onPrimary,
                          ),
                          Container(
                            width: sizes.xs,
                            margin: EdgeInsets.only(left: sizes.xl),
                            ),
                          Expanded( 
                              child: Text(
                                taskContent.title,
                                textAlign: TextAlign.left,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: sizes.sm,
                bottom: -sizes.md,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(sizes.radiusFull),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: .24),
                        blurRadius: sizes.xs,
                        offset: Offset(0, sizes.xs / 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: sizes.md,
                      vertical: sizes.sm,
                    ),
                    child: Text(
                      taskContent.time,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
