import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

enum TextFieldVariant {
  surface,
  tinted,
}

class TextFieldWidget extends StatelessWidget {
  const TextFieldWidget({
    super.key,
    required this.controller,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.enabled = true,
    this.focusNode,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.autofillHints,
    this.inputFormatters,
    this.variant = TextFieldVariant.surface,
    this.readOnly = false,
    this.minLines,
    this.maxLines = 1,
    this.onTap,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final bool enabled;
  final FocusNode? focusNode;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final TextFieldVariant variant;
  final bool readOnly;
  final int? minLines;
  final int? maxLines;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final fillColor = switch (variant) {
      TextFieldVariant.surface => colorScheme.surface,
      TextFieldVariant.tinted => Color.alphaBlend(
          context.appGradientColors.bottom.withValues(alpha: .55),
          colorScheme.surface,
        ),
    };

    OutlineInputBorder border(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(sizes.radiusFull),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      enabled: enabled,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      autofillHints: autofillHints,
      inputFormatters: inputFormatters,
      readOnly: readOnly,
      minLines: minLines,
      maxLines: maxLines,
      onTap: onTap,
      cursorColor: colorScheme.primary,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        filled: true,
        fillColor: fillColor,
        contentPadding: EdgeInsets.symmetric(
          horizontal: sizes.md,
          vertical: sizes.md,
        ),
        enabledBorder: border(colorScheme.outline),
        focusedBorder: border(colorScheme.primary, width: 1.5),
        disabledBorder: border(
          colorScheme.onSurface.withValues(alpha: .12),
        ),
        errorBorder: border(colorScheme.error),
        focusedErrorBorder: border(colorScheme.error, width: 1.5),
      ),
    );
  }
}
