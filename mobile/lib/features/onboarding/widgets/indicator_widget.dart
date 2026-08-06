import 'package:flutter/material.dart';

class OnboardingIndicator extends StatelessWidget {
  final int currentIndex;

  const OnboardingIndicator({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (index) {
          final isSelected = index == currentIndex;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: isSelected ? 10 : 8,
            height: isSelected ? 10 : 8,
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white
                  : Colors.white.withOpacity(.5),
              shape: BoxShape.circle,
            ),
          );
        },
      ),
    );
  }
}