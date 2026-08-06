import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class BackButtonWidget extends StatelessWidget {
  final VoidCallback onPressed;

  const BackButtonWidget({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: onPressed,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new,
          size: 18,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}