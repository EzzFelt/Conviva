import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';

/// Dropdown com label acima, no padrão visual do app.
///
/// Local sugerido: lib/shared/widgets/labeled_dropdown_field.dart
class LabeledDropdownField extends StatelessWidget {
  const LabeledDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

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
        Container(
          padding: EdgeInsets.symmetric(horizontal: sizes.md),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(sizes.md),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
              items: items
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(item),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}