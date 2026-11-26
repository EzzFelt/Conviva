import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';

class OnboardingIndicator extends StatelessWidget {
  const OnboardingIndicator({
    super.key,
    required this.currentIndex,
    required this.itemCount,
  });

  final int currentIndex;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sizes = context.appSizes;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        itemCount,
        (index) {
          final isSelected = index == currentIndex;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: EdgeInsets.symmetric(
              horizontal: sizes.xs * .75,
            ),
            width: isSelected ? sizes.sm + sizes.xs / 2 : sizes.sm,
            height: isSelected ? sizes.sm + sizes.xs / 2 : sizes.sm,
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onPrimary.withValues(alpha: .5),
              shape: BoxShape.circle,
            ),
          );
        },
      ),
    );
  }
}
