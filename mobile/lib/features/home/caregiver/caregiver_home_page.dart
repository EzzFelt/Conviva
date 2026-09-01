import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';
import '../../../shared/widgets/content_panel_widget.dart';
import '../../../shared/widgets/info_card_widget.dart';

class CaregiverHomePage extends StatelessWidget {
  const CaregiverHomePage({
    super.key,
    this.caregiverData = const {},
  });

  final Map<String, dynamic> caregiverData;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final gradientColors = context.appGradientColors;
    final sizes = context.appSizes;
    final caregiverName = caregiverData['name']?.toString() ?? 'Cuidador';

    Widget actionIcon(IconData icon) {
      return CircleAvatar(
        backgroundColor: colorScheme.primary.withValues(alpha: .12),
        child: Icon(
          icon,
          color: colorScheme.primary,
        ),
      );
    }

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              gradientColors.bottom,
              gradientColors.top,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(sizes.lg),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: sizes.xl,
                        backgroundColor: colorScheme.surface,
                        child: Icon(
                          Icons.health_and_safety_rounded,
                          color: colorScheme.primary,
                          size: sizes.xl,
                        ),
                      ),
                      SizedBox(width: sizes.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Olá, $caregiverName!',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: colorScheme.onPrimary,
                              ),
                            ),
                            Text(
                              'Painel do cuidador',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ContentPanelWidget(
                  padding: EdgeInsets.fromLTRB(
                    sizes.lg,
                    sizes.xl,
                    sizes.lg,
                    sizes.xxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Acessos rápidos',
                        style: theme.textTheme.titleLarge,
                      ),
                      SizedBox(height: sizes.lg),
                      InfoCardWidget(
                        leading: actionIcon(Icons.event_note_rounded),
                        title: 'Rotina dos idosos',
                        subtitle: 'Consulte e organize as atividades',
                        size: InfoCardSize.medium,
                        showGotoButton: true,
                        onPressed: () => context.go(RouteNames.routine),
                      ),
                      SizedBox(height: sizes.md),
                      InfoCardWidget(
                        leading: actionIcon(Icons.chat_bubble_rounded),
                        title: 'Conversas',
                        subtitle: 'Acesse as mensagens recentes',
                        size: InfoCardSize.medium,
                        showGotoButton: true,
                        onPressed: () => context.go(RouteNames.chat),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
