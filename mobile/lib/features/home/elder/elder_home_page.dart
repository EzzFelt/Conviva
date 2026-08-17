import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/assets_paths.dart';
import '../../../../shared/widgets/action_card_widget.dart';
import '../../../../shared/widgets/content_panel_widget.dart';
import '../../../../shared/widgets/info_card_widget.dart';
import '../../../../shared/widgets/main_navigation_bar.dart';
import '../widgets/elder_home_header.dart';
import '../widgets/next_task_card.dart';

class ElderHomePage extends StatelessWidget {
  const ElderHomePage({
    super.key,
    this.elderData = const {},
  });

  final Map<String, dynamic> elderData;

  @override
  Widget build(BuildContext context) {
    final gradientColors = context.appGradientColors;
    final colorScheme = Theme.of(context).colorScheme;
    final sizes = context.appSizes;
    const currentTask = NextTaskType.breakfast;
    final elderName = elderData['name']?.toString() ?? 'Usuário';

    Widget chatAvatar(IconData icon) {
      return CircleAvatar(
        backgroundColor: colorScheme.primary.withValues(alpha: .12),
        child: Icon(
          icon,
          color: colorScheme.primary,
          size: sizes.md,
        ),
      );
    }

    Widget actionIllustration(IconData icon) {
      return Icon(
        icon,
        size: sizes.xxl * 2,
        color: colorScheme.onPrimary,
      );
    }

    Widget sectionTitle(String title) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    return Scaffold(
      extendBody: true,
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
                ElderHomeHeader(
                  name: elderName,
                  notificationCount: 1,
                  onNotificationsPressed: () {},
                  avatar: Icon(
                    Icons.person_rounded,
                    color: colorScheme.primary,
                    size: sizes.xxl,
                  ),
                ),
                ContentPanelWidget(
                  topPanelPadding: EdgeInsets.fromLTRB(
                    sizes.lg,
                    sizes.lg,
                    sizes.lg,
                    sizes.xl,
                  ),
                  topPanel: const NextTaskCard(
                    taskType: currentTask,
                  ),
                  padding: EdgeInsets.fromLTRB(
                    sizes.lg,
                    sizes.xl + sizes.sm,
                    sizes.lg,
                    sizes.xxl,
                  ),
                  child: Column(
                    children: [
                      sectionTitle('Chat - Converse'),
                      SizedBox(height: sizes.md),
                      InfoCardWidget(
                        leading: chatAvatar(Icons.person_rounded),
                        title: 'Enzo Oliveira',
                        subtitle: 'Oi, pode me ajudar por favor?',
                        size: InfoCardSize.small,
                        showGotoButton: true,
                        onPressed: () {},
                      ),
                      SizedBox(height: sizes.lg),
                      InfoCardWidget(
                        leading: chatAvatar(Icons.medical_services_rounded),
                        title: 'Isabelle Guimarães',
                        subtitle: 'Bom dia, como você está se sentindo?',
                        size: InfoCardSize.small,
                        showGotoButton: true,
                        onPressed: () {},
                      ),
                      SizedBox(height: sizes.sm),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Ver mais'),
                      ),
                      SizedBox(height: sizes.xxl),
                      sectionTitle(
                        'Assistente Virtual  -\nTire Dúvidas',
                      ),
                      SizedBox(height: sizes.md),
                      ActionCardWidget(
                        title: 'Tire dúvidas sobre\ntecnologia com o Auri',
                        imageAsset: AssetPaths.auri,
                        illustrationSize: sizes.xxl * 2.5,
                        imageSemanticLabel: 'Assistente virtual Auri',
                        actionLabel: 'Comece agora!',
                        onPressed: () {},
                      ),
                      SizedBox(height: sizes.xxl),
                      sectionTitle(
                        'Central de Denúncias  -\nDenuncie',
                      ),
                      SizedBox(height: sizes.md),
                      ActionCardWidget(
                        title: 'Denuncie abusos que\nestiver sofrendo de\n'
                            'maneira anônima',
                        illustration: actionIllustration(
                          Icons.report_rounded,
                        ),
                        illustrationSize: sizes.xxl * 2.5,
                        actionLabel: 'Denuncie!',
                        onPressed: () {},
                        layout: ActionCardLayout.textFirst,
                        showIllustrationBackground: false,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: sizes.xxl * 2 + sizes.xl),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: MainNavigationBar(
        currentIndex: 0,
        onDestinationSelected: (_) {},
      ),
    );
  }
}
