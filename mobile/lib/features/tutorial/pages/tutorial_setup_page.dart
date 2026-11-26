import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/settings/app_settings_provider.dart';
import '../../../shared/widgets/button_widget.dart';
import '../../settings/widgets/settings_adjustment_buttons_widget.dart';
import '../../settings/widgets/settings_controls_widget.dart';
import '../../settings/widgets/settings_palette_option_widget.dart';
import '../providers/tutorial_provider.dart';

/// Passo a passo de personalização exibido no começo do tutorial do idoso:
/// fonte, notificações, ícones e botões e cores do aplicativo.
///
/// Cada ajuste é aplicado na hora (a própria tela muda) e fica salvo nas
/// configurações do app, como na tela de Configurações.
class TutorialSetupPage extends ConsumerStatefulWidget {
  const TutorialSetupPage({super.key});

  @override
  ConsumerState<TutorialSetupPage> createState() => _TutorialSetupPageState();
}

class _TutorialSetupPageState extends ConsumerState<TutorialSetupPage> {
  static const _titles = [
    'Vamos começar personalizando\no tamanho da fonte',
    'Agora a grossura da fonte',
    'Agora as notificações',
    'Agora o tamanho dos\nícones e dos botões',
    'E para finalizar a\npersonalização as cores\ndo aplicativo',
  ];

  int _step = 0;

  void _next() {
    if (_step < _titles.length - 1) {
      setState(() => _step++);
      return;
    }

    // Personalização concluída: começa o tutorial da tela inicial.
    context.go(RouteNames.elderHome);
    ref.read(tutorialProvider.notifier).start();
  }

  void _skip() {
    context.go(RouteNames.elderHome);
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  List<Widget> _content(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);

    switch (_step) {
      case 0:
        return [
          SettingsTextPreview(
            label: 'Tamanho:',
            previewStyle: theme.textTheme.titleLarge,
            onIncrease: () => notifier.setFontScale(settings.fontScale + .1),
            onDecrease: () => notifier.setFontScale(settings.fontScale - .1),
          ),
        ];
      case 1:
        return [
          SettingsTextPreview(
            label: 'Grossura títulos:',
            previewStyle: theme.textTheme.titleLarge?.copyWith(
              fontWeight: settings.titleFontWeight,
            ),
            onIncrease: () => notifier.setTitleFontWeight(FontWeight.w800),
            onDecrease: () => notifier.setTitleFontWeight(FontWeight.w600),
          ),
          SettingsTextPreview(
            label: 'Grossura texto normal:',
            previewStyle: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: settings.bodyFontWeight,
            ),
            onIncrease: () => notifier.setBodyFontWeight(FontWeight.w600),
            onDecrease: () => notifier.setBodyFontWeight(FontWeight.w400),
          ),
        ];
      case 2:
        return [
          Text('Permitir notificações:', style: theme.textTheme.titleMedium),
          SizedBox(height: sizes.sm),
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
          SizedBox(height: sizes.xl),
          SettingsVolume(
            volume: settings.volume,
            onIncrease: () => notifier.setVolume(settings.volume + .1),
            onDecrease: () => notifier.setVolume(settings.volume - .1),
          ),
        ];
      case 3:
        return [
          Text('Ícones:', style: theme.textTheme.titleMedium),
          SizedBox(height: sizes.lg),
          Semantics(
            label: 'Exemplo do tamanho dos ícones',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final (index, icon) in [
                  Icons.grid_view_rounded,
                  Icons.home_rounded,
                  Icons.image_rounded,
                  Icons.settings_rounded,
                ].indexed)
                  Icon(
                    icon,
                    size: sizes.icon(sizes.lg),
                    color: index == 2
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant.withValues(alpha: .65),
                  ),
              ],
            ),
          ),
          SizedBox(height: sizes.lg),
          SettingsAdjustmentButtonsWidget(
            onIncrease: () => notifier.setIconScale(settings.iconScale + .1),
            onDecrease: () => notifier.setIconScale(settings.iconScale - .1),
          ),
          SizedBox(height: sizes.xl),
          Text('Botões:', style: theme.textTheme.titleMedium),
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
            onIncrease: () =>
                notifier.setButtonScale(settings.buttonScale + .1),
            onDecrease: () =>
                notifier.setButtonScale(settings.buttonScale - .1),
          ),
        ];
      default:
        return [
          Text('Cores:', style: theme.textTheme.titleMedium),
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
          SizedBox(height: sizes.xl),
          SettingsPaletteOptionWidget(
            colors: const [
              AppColors.greenPrimary,
              AppColors.greenGradientBottom,
              AppColors.white,
            ],
            selected: settings.primaryColor == AppColors.greenPrimary,
            onSelected: () {
              notifier.setPalette(
                primaryColor: AppColors.greenPrimary,
                gradientTop: AppColors.greenGradientTop,
                gradientBottom: AppColors.greenGradientBottom,
              );
            },
          ),
          SizedBox(height: sizes.xl),
          Text('Intensidade:', style: theme.textTheme.titleMedium),
          SizedBox(height: sizes.lg),
          SettingsIntensity(
            value: settings.colorIntensity,
            onChanged: notifier.setColorIntensity,
            onIncrease: () =>
                notifier.setColorIntensity(settings.colorIntensity + .1),
            onDecrease: () =>
                notifier.setColorIntensity(settings.colorIntensity - .1),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final ovalRadius = Radius.elliptical(screenWidth * .27, sizes.xxl);

    return PopScope(
      // Voltar leva ao passo anterior; no primeiro passo não faz nada.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: DecoratedBox(
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
            child: Column(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: sizes.xxl * 2.6),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: sizes.lg,
                        vertical: sizes.md,
                      ),
                      child: Text(
                        _titles[_step],
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: ovalRadius,
                        topRight: ovalRadius,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SafeArea(
                      top: false,
                      child: SingleChildScrollView(
                        key: ValueKey(_step),
                        padding: EdgeInsets.fromLTRB(
                          sizes.lg,
                          sizes.xl + sizes.md,
                          sizes.lg,
                          sizes.xl,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ..._content(context),
                            SizedBox(height: sizes.xl),
                            ButtonWidget(
                              label: 'Continuar',
                              variant: ButtonVariant.primary,
                              onPressed: _next,
                            ),
                            SizedBox(height: sizes.md),
                            ButtonWidget(
                              label: 'Pular tutorial',
                              variant: ButtonVariant.outlined,
                              onPressed: _skip,
                            ),
                          ],
                        ),
                      ),
                    ),
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
