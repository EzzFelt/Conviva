import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';

class ReportPillField extends StatelessWidget {
  const ReportPillField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    this.keyboardType,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.titleMedium),
        SizedBox(height: sizes.sm),
        Material(
          color: colorScheme.surface,
          elevation: sizes.xs / 2,
          shadowColor: colorScheme.shadow.withValues(alpha: .20),
          borderRadius: BorderRadius.circular(sizes.radiusFull),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              filled: true,
              fillColor: colorScheme.surface,
              contentPadding: EdgeInsets.symmetric(
                horizontal: sizes.lg,
                vertical: sizes.md,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(sizes.radiusFull),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
