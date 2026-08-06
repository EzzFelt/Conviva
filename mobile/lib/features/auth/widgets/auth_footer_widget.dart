import 'package:flutter/material.dart';

import 'package:conviva/core/constants/app_colors.dart';

class AuthFooterWidget extends StatelessWidget {
  final String text;
  final String actionText;
  final VoidCallback onTap;

  const AuthFooterWidget({
    super.key,
    required this.text,
    required this.actionText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
            children: [
              TextSpan(text: text),
              TextSpan(
                text: ' $actionText',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}