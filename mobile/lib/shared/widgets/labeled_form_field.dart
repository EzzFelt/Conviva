import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';

/// Campo de texto com label acima, no padrão visual do app.
///
/// Local sugerido: lib/shared/widgets/labeled_form_field.dart
class LabeledFormField extends StatelessWidget {
  const LabeledFormField({
    super.key,
    required this.label,
    required this.hintText,
    this.controller,
    this.keyboardType,
  });

  final String label;
  final String hintText;
  final TextEditingController? controller;
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
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
            contentPadding: EdgeInsets.symmetric(
              horizontal: sizes.md,
              vertical: sizes.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(sizes.md),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}