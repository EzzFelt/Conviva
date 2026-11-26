import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';
import 'app_modal_widget.dart';
import 'button_widget.dart';

/// Pede uma confirmação simples (Confirmar / Cancelar).
/// Retorna `true` somente se a pessoa confirmar.
Future<bool> showConfirmModal(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancelar',
}) async {
  final result = await showAppModal<bool>(
    context: context,
    title: title,
    size: AppModalSize.small,
    child: _ConfirmModalBody(
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
    ),
  );

  return result ?? false;
}

class _ConfirmModalBody extends StatelessWidget {
  const _ConfirmModalBody({
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
  });

  final String message;
  final String confirmLabel;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    final sizes = context.appSizes;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        SizedBox(height: sizes.xl),
        ButtonWidget(
          label: confirmLabel,
          variant: ButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        SizedBox(height: sizes.md),
        ButtonWidget(
          label: cancelLabel,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
