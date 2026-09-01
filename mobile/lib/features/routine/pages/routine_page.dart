import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';

class RoutinePage extends StatelessWidget {
  const RoutinePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.all(sizes.lg),
          children: [
            Text(
              'Rotina',
              style: theme.textTheme.headlineLarge,
            ),
            SizedBox(height: sizes.xl),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(sizes.lg),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(sizes.radiusLg),
                border: Border.all(color: colorScheme.outline),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.event_available_rounded,
                    size: sizes.xxl,
                    color: colorScheme.primary,
                  ),
                  SizedBox(height: sizes.md),
                  Text(
                    'Nenhuma atividade carregada',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                  SizedBox(height: sizes.sm),
                  Text(
                    'As tarefas serão apresentadas aqui quando conectarmos '
                    'a rotina aos dados do usuário.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
