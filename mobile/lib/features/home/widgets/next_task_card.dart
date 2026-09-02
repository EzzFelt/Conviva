import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../routine/models/routine_task.dart';

class NextTaskCard extends StatelessWidget {
  const NextTaskCard({
    super.key,
    required this.task,
    this.sectionTitle = 'Sua próxima tarefa:',
    this.emptyMessage = 'Nenhuma tarefa no momento',
    this.isLoading = false,
    this.onPressed,
  });

  final RoutineTask? task;
  final String sectionTitle;
  final String emptyMessage;
  final bool isLoading;
  final VoidCallback? onPressed;

  IconData _taskIcon() {
    return switch (task?.type) {
      RoutineTaskType.breakfast => Icons.breakfast_dining_rounded,
      RoutineTaskType.medication => Icons.medication_rounded,
      RoutineTaskType.meal => Icons.restaurant_rounded,
      RoutineTaskType.exercise => Icons.directions_walk_rounded,
      RoutineTaskType.leisure => Icons.interests_rounded,
      RoutineTaskType.appointment => Icons.medical_services_rounded,
      RoutineTaskType.hygiene => Icons.shower_rounded,
      RoutineTaskType.sleep => Icons.bed_rounded,
      RoutineTaskType.other => Icons.event_available_rounded,
      null => Icons.event_available_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final cardRadius = BorderRadius.circular(
      sizes.radiusMd + sizes.xs,
    );
    final taskTitle = task?.title ?? emptyMessage;

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
          padding: EdgeInsets.only(
            bottom: task == null ? 0 : sizes.md,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                width: double.infinity,
                child: Material(
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
                        padding: EdgeInsets.symmetric(
                          horizontal: sizes.lg,
                          vertical: sizes.lg,
                        ),
                        child: isLoading
                            ? Center(
                                child: SizedBox.square(
                                  dimension: sizes.xl,
                                  child: CircularProgressIndicator(
                                    strokeWidth: sizes.xs / 2,
                                    color: colorScheme.onPrimary,
                                  ),
                                ),
                              )
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  return Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _taskIcon(),
                                          size: sizes.xxl + sizes.md,
                                          color: colorScheme.onPrimary,
                                        ),
                                        SizedBox(width: sizes.lg),
                                        SizedBox(
                                          width: constraints.maxWidth * .48,
                                          child: Text(
                                            taskTitle,
                                            textAlign: TextAlign.center,
                                            style: theme
                                                .textTheme.headlineSmall
                                                ?.copyWith(
                                              color: colorScheme.onPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              if (task != null)
                Positioned(
                  right: sizes.sm,
                  bottom: -sizes.md,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(
                        sizes.radiusFull,
                      ),
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
                        task!.timeLabel,
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
