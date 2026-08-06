import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class GotoButtonWidget extends StatelessWidget {
  final VoidCallback? onPressed;

  const GotoButtonWidget({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.white,
        ),
      ),
    );
  }
}