import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'goto_button_widget.dart';

class BorderCardWidget extends StatelessWidget {
  final Widget leading;
  final String title;
  final String description;
  final VoidCallback? onTap;

  const BorderCardWidget({
    super.key,
    required this.leading,
    required this.title,
    required this.description,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leading,

                const SizedBox(width: 16),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 52),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textHint,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            Positioned(
              right: 0,
              bottom: 0,
              child: GotoButtonWidget(
                onPressed: onTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}