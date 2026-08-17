import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';

/// Cabeçalho da tela de vincular parente.
///
/// Local sugerido: lib/features/family/presentation/widgets/link_relative_header.dart
class LinkRelativeHeader extends StatelessWidget {
  const LinkRelativeHeader({
    super.key,
    required this.userName,
  });

  final String userName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    return Padding(
      padding: EdgeInsets.fromLTRB(sizes.lg, sizes.xxl, sizes.lg, sizes.xl),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text.rich(
          TextSpan(
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onPrimary,
              fontSize: theme.textTheme.titleLarge?.fontSize,
            ),
            children: [
              const TextSpan(text: 'Olá, '),
              TextSpan(
                text: '$userName!',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}