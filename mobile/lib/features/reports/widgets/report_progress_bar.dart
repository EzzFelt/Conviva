import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';

class ReportProgressBar extends StatelessWidget {
  const ReportProgressBar({
    super.key,
    required this.step,
    required this.totalSteps,
  });

  final int step;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sizes = context.appSizes;
    final progress = (step / totalSteps).clamp(0.0, 1.0);

    return Semantics(
      label: 'Etapa $step de $totalSteps',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(sizes.radiusFull),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: sizes.xs,
          backgroundColor: colorScheme.outline,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}
