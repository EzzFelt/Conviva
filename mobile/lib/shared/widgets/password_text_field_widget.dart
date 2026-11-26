
import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';

class PasswordTextFieldWidget extends StatefulWidget {
  const PasswordTextFieldWidget({
    super.key,
    required this.controller,
    this.hintText = 'Senha',
    this.textInputAction,
    this.focusNode,
    this.enabled = true,
    this.validator,
    this.onFieldSubmitted,
    this.autofillHints = const [AutofillHints.password],
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final bool enabled;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;

  @override
  State<PasswordTextFieldWidget> createState() =>
      _PasswordTextFieldWidgetState();
}

class _PasswordTextFieldWidgetState
    extends State<PasswordTextFieldWidget> {
  bool _obscureText = true;

  late final FocusNode _internalFocusNode = FocusNode();

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? _internalFocusNode;

  void _togglePasswordVisibility() {
    if (!widget.enabled) return;

    final selection = widget.controller.selection;

    setState(() {
      _obscureText = !_obscureText;
    });

    // Mantém o campo pronto para receber novas entradas.
    _effectiveFocusNode.requestFocus();

    // Preserva a posição do cursor, quando válida.
    if (selection.isValid) {
      widget.controller.selection = selection;
    }
  }

  @override
  void dispose() {
    _internalFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    OutlineInputBorder border(
      Color color, {
      double width = 1,
    }) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(sizes.radiusFull),
        borderSide: BorderSide(
          color: color,
          width: width,
        ),
      );
    }

    return TextFormField(
      controller: widget.controller,
      focusNode: _effectiveFocusNode,
      enabled: widget.enabled,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      onFieldSubmitted: widget.onFieldSubmitted,
      autofillHints: widget.autofillHints,
      keyboardType: TextInputType.visiblePassword,
      obscureText: _obscureText,
      enableSuggestions: false,
      autocorrect: false,
      cursorColor: colorScheme.primary,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: sizes.md,
          vertical: sizes.md,
        ),
        enabledBorder: border(colorScheme.outline),
        focusedBorder: border(
          colorScheme.primary,
          width: 1.5,
        ),
        errorBorder: border(colorScheme.error),
        focusedErrorBorder: border(
          colorScheme.error,
          width: 1.5,
        ),
        suffixIcon: IconButton(
          tooltip: _obscureText ? 'Mostrar senha' : 'Ocultar senha',
          onPressed: widget.enabled
              ? _togglePasswordVisibility
              : null,
          icon: Icon(
            _obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
