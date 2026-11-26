import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';

class ReportYesNoGroup extends StatelessWidget {
  const ReportYesNoGroup({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final sizes = context.appSizes;

    return Row(
      children: [
        _ReportRadioOption(
          label: 'Sim',
          selected: value,
          onTap: () => onChanged(true),
        ),
        SizedBox(width: sizes.xl),
        _ReportRadioOption(
          label: 'Não',
          selected: !value,
          onTap: () => onChanged(false),
        ),
      ],
    );
  }
}

class _ReportRadioOption extends StatelessWidget {
  const _ReportRadioOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(sizes.radiusMd),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: sizes.sm,
            horizontal: sizes.xs,
          ),
          child: Row(
            children: [
              Container(
                width: sizes.lg,
                height: sizes.lg,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? colorScheme.primary : colorScheme.outline,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: selected
                    ? Container(
                        width: sizes.sm + sizes.xs,
                        height: sizes.sm + sizes.xs,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
              SizedBox(width: sizes.sm),
              Text(label, style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }
}
