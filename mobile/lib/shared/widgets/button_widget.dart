import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

enum ButtonVariant {
  orange,
  white,
}

enum ButtonSize {
  small,
  medium,
  big,
}

class ButtonWidget extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;

  const ButtonWidget({
    super.key,
    this.label = 'Continuar',
    required this.onPressed,
    this.variant = ButtonVariant.orange,
    this.size = ButtonSize.medium,
  });

  double get _height {
    switch (size) {
      case ButtonSize.small:
        return 42;
      case ButtonSize.medium:
        return 50;
      case ButtonSize.big:
        return 56;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOrange = variant == ButtonVariant.orange;

    return SizedBox(
      width: double.infinity,
      height: _height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor:
              isOrange ? AppColors.primary : AppColors.white,
          foregroundColor:
              isOrange ? AppColors.white : AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(
              color: AppColors.primary,
            ),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}