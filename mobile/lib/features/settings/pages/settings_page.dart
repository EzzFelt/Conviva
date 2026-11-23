import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/settings/app_settings_provider.dart';
import '../../../shared/widgets/button_widget.dart';
import '../../../shared/widgets/confirm_modal.dart';
import '../../../shared/widgets/content_panel_widget.dart';
import '../../../shared/widgets/page_header_widget.dart';
import '../../auth/models/user_session.dart';
import '../../auth/providers/authenticated_user_navigator.dart';
import '../../auth/providers/current_user_provider.dart';
import '../widgets/settings_adjustment_buttons_widget.dart';
import '../widgets/settings_controls_widget.dart';
import '../widgets/settings_palette_option_widget.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _goHome(BuildContext context, UserSession session) async {
    await AuthenticatedUserNavigator.open(context, session);
  }

  Future<void> _restoreDefaults(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmModal(
      context,
      title: 'Restaurar padrão?',
      message:
          'Fonte, ícones, botões, cores e notificações voltam para o padrão '
          'do app.',
      confirmLabel: 'Restaurar',
    );

    if (!confirmed || !context.mounted) return;

    ref.read(appSettingsProvider.notifier).reset();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configurações restauradas ao padrão.')),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    UserSession session,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final ovalRadius = Radius.elliptical(screenWidth * .27, sizes.xxl);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.appGradientColors.bottom,
            context.appGradientColors.top,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: PageHeaderWidget(
                title: 'Configurações',
                onBackPressed: () => _goHome(context, session),
              ),
            ),
            SliverToBoxAdapter(
              child: ContentPanelWidget(
                borderRadius: BorderRadius.only(
                  topLeft: ovalRadius,
                  topRight: ovalRadius,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    sizes.lg,
                    sizes.xxl,
                    sizes.lg,
                    sizes.xxl * 3,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Fonte', style: theme.textTheme.headlineSmall),
                      SizedBox(height: sizes.md),
                      SettingsTextPreview(
                        label: 'Tamanho:',
                        previewStyle: theme.textTheme.titleLarge,
                        onIncrease: () {
                          notifier.setFontScale(settings.fontScale + .1);
                        },
                        onDecrease: () {
                          notifier.setFontScale(settings.fontScale - .1);
                        },
                      ),
                      SettingsTextPreview(
                        label: 'Grossura títulos:',
                        previewStyle: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: settings.titleFontWeight,
                        ),
                        onIncrease: () {
                          notifier.setTitleFontWeight(FontWeight.w800);
                        },
                        onDecrease: () {
                          notifier.setTitleFontWeight(FontWeight.w600);
                        },
                      ),
                      SettingsTextPreview(
                        label: 'Grossura texto normal:',
                        previewStyle: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: settings.bodyFontWeight,
                        ),
                        onIncrease: () {
                          notifier.setBodyFontWeight(FontWeight.w600);
                        },
                        onDecrease: () {
                          notifier.setBodyFontWeight(FontWeight.w400);
                        },
                      ),
                      Text(
                        'Notificações',
                        style: theme.textTheme.headlineSmall,
                      ),
                      SizedBox(height: sizes.lg),
                      SettingsToggle(
                        label: 'Mensagens:',
                        value: settings.messageNotifications,
                        onChanged: notifier.setMessageNotifications,
                      ),
                      SettingsToggle(
                        label: 'Lembretes:',
                        value: settings.reminderNotifications,
                        onChanged: notifier.setReminderNotifications,
                      ),
                      SizedBox(height: sizes.xxl),
                      SettingsVolume(
                        volume: settings.volume,
                        onIncrease: () {
                          notifier.setVolume(settings.volume + .1);
                        },
                        onDecrease: () {
                          notifier.setVolume(settings.volume - .1);
                        },
                      ),
                      SizedBox(height: sizes.xxl),
                      Text('Ícones', style: theme.textTheme.headlineSmall),
                      SizedBox(height: sizes.lg),
                      Semantics(
                        label: 'Exemplo do tamanho dos ícones',
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children:
                              [
                                Icons.grid_view_rounded,
                                Icons.home_rounded,
                                Icons.image_rounded,
                                Icons.settings_rounded,
                              ].asMap().entries.map((entry) {
                                final selected = entry.key == 2;

                                return Icon(
                                  entry.value,
                                  size: sizes.icon(sizes.lg),
                                  color: selected
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant.withValues(
                                          alpha: .65,
                                        ),
                                );
                              }).toList(),
                        ),
                      ),
                      SizedBox(height: sizes.lg),
                      SettingsAdjustmentButtonsWidget(
                        onIncrease: () {
                          notifier.setIconScale(settings.iconScale + .1);
                        },
                        onDecrease: () {
                          notifier.setIconScale(settings.iconScale - .1);
                        },
                      ),
                      SizedBox(height: sizes.xxl),
                      Text('Botões', style: theme.textTheme.headlineSmall),
                      SizedBox(height: sizes.lg),
                      FractionallySizedBox(
                        widthFactor: .82,
                        child: ButtonWidget(
                          label: 'Botão',
                          size: ButtonSize.medium,
                          variant: ButtonVariant.secondary,
                          onPressed: () {},
                        ),
                      ),
                      SizedBox(height: sizes.lg),
                      SettingsAdjustmentButtonsWidget(
                        onIncrease: () {
                          notifier.setButtonScale(settings.buttonScale + .1);
                        },
                        onDecrease: () {
                          notifier.setButtonScale(settings.buttonScale - .1);
                        },
                      ),
                      SizedBox(height: sizes.xxl),
                      Text('Cores', style: theme.textTheme.headlineSmall),
                      SizedBox(height: sizes.lg),
                      SettingsPaletteOptionWidget(
                        colors: const [
                          AppColors.primary,
                          AppColors.gradientBottom,
                          AppColors.white,
                        ],
                        selected: settings.primaryColor == AppColors.primary,
                        onSelected: () {
                          notifier.setPalette(
                            primaryColor: AppColors.primary,
                            gradientTop: AppColors.gradientTop,
                            gradientBottom: AppColors.gradientBottom,
                          );
                        },
                      ),
                      SizedBox(height: sizes.xxl),
                      SettingsPaletteOptionWidget(
                        colors: const [
                          AppColors.greenPrimary,
                          AppColors.greenGradientBottom,
                          AppColors.white,
                        ],
                        selected:
                            settings.primaryColor == AppColors.greenPrimary,
                        onSelected: () {
                          notifier.setPalette(
                            primaryColor: AppColors.greenPrimary,
                            gradientTop: AppColors.greenGradientTop,
                            gradientBottom: AppColors.greenGradientBottom,
                          );
                        },
                      ),
                      SizedBox(height: sizes.xxl),
                      Text('Intensidade', style: theme.textTheme.headlineSmall),
                      SizedBox(height: sizes.lg),
                      SettingsIntensity(
                        value: settings.colorIntensity,
                        onChanged: notifier.setColorIntensity,
                        onIncrease: () {
                          notifier.setColorIntensity(
                            settings.colorIntensity + .1,
                          );
                        },
                        onDecrease: () {
                          notifier.setColorIntensity(
                            settings.colorIntensity - .1,
                          );
                        },
                      ),
                      SizedBox(height: sizes.xxl),
                      ButtonWidget(
                        label: 'Restaurar padrão',
                        variant: ButtonVariant.outlined,
                        onPressed: () => _restoreDefaults(context, ref),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final sizes = context.appSizes;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: currentUser.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: EdgeInsets.all(sizes.lg),
            child: Text(
              error.toString().replaceFirst('Bad state: ', ''),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (session) {
          if (session == null) {
            return const Center(child: Text('Usuário não autenticado.'));
          }

          return _buildContent(context, ref, session);
        },
      ),
    );
  }
}
