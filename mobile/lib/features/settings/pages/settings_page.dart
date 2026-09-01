import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/settings/app_settings_provider.dart';
import '../../../shared/widgets/button_widget.dart';
import '../../../shared/widgets/content_panel_widget.dart';
import '../../../shared/widgets/page_header_widget.dart';
import '../../auth/models/user_session.dart';
import '../../auth/providers/authenticated_user_navigator.dart';
import '../../auth/providers/current_user_provider.dart';
import '../widgets/settings_adjustment_buttons_widget.dart';
import '../widgets/settings_palette_option_widget.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _goHome(
    BuildContext context,
    UserSession session,
  ) async {
    await AuthenticatedUserNavigator.open(context, session);
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
    final ovalRadius = Radius.elliptical(
      screenWidth * .27,
      sizes.xxl,
    );

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
        child: Column(
          children: [
            PageHeaderWidget(
              title: 'Configurações',
              onBackPressed: () => _goHome(context, session),
            ),
            Expanded(
              child: ContentPanelWidget(
                borderRadius: BorderRadius.only(
                  topLeft: ovalRadius,
                  topRight: ovalRadius,
                ),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    sizes.lg,
                    sizes.xl,
                    sizes.lg,
                    sizes.xxl * 3,
                  ),
                  children: [
                    Text(
                      'Fonte',
                      style: theme.textTheme.headlineSmall,
                    ),
                    SizedBox(height: sizes.sm),
                    _TextPreviewSetting(
                      label: 'Tamanho:',
                      previewStyle: theme.textTheme.titleLarge,
                      onIncrease: () {
                        notifier.setFontScale(settings.fontScale + .1);
                      },
                      onDecrease: () {
                        notifier.setFontScale(settings.fontScale - .1);
                      },
                    ),
                    _TextPreviewSetting(
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
                    _TextPreviewSetting(
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
                    SizedBox(height: sizes.md),
                    _ToggleSetting(
                      label: 'Mensagens:',
                      value: settings.messageNotifications,
                      onChanged: notifier.setMessageNotifications,
                    ),
                    _ToggleSetting(
                      label: 'Lembretes:',
                      value: settings.reminderNotifications,
                      onChanged: notifier.setReminderNotifications,
                    ),
                    SizedBox(height: sizes.xl),
                    _VolumeSetting(
                      volume: settings.volume,
                      onIncrease: () {
                        notifier.setVolume(settings.volume + .1);
                      },
                      onDecrease: () {
                        notifier.setVolume(settings.volume - .1);
                      },
                    ),
                    SizedBox(height: sizes.xl),
                    Text(
                      'Ícones',
                      style: theme.textTheme.headlineSmall,
                    ),
                    SizedBox(height: sizes.md),
                    Semantics(
                      label: 'Exemplo do tamanho dos ícones',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
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
                    SizedBox(height: sizes.md),
                    SettingsAdjustmentButtonsWidget(
                      onIncrease: () {
                        notifier.setIconScale(settings.iconScale + .1);
                      },
                      onDecrease: () {
                        notifier.setIconScale(settings.iconScale - .1);
                      },
                    ),
                    SizedBox(height: sizes.xl),
                    Text(
                      'Botões',
                      style: theme.textTheme.headlineSmall,
                    ),
                    SizedBox(height: sizes.md),
                    FractionallySizedBox(
                      widthFactor: .82,
                      child: ButtonWidget(
                        label: 'Botão',
                        size: ButtonSize.small,
                        variant: ButtonVariant.secondary,
                        onPressed: () {},
                      ),
                    ),
                    SizedBox(height: sizes.md),
                    SettingsAdjustmentButtonsWidget(
                      onIncrease: () {
                        notifier.setButtonScale(settings.buttonScale + .1);
                      },
                      onDecrease: () {
                        notifier.setButtonScale(settings.buttonScale - .1);
                      },
                    ),
                    SizedBox(height: sizes.xl),
                    Text(
                      'Cores',
                      style: theme.textTheme.headlineSmall,
                    ),
                    SizedBox(height: sizes.md),
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
                    SizedBox(height: sizes.lg),
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
                    SizedBox(height: sizes.xl),
                    Text(
                      'Intensidade',
                      style: theme.textTheme.headlineSmall,
                    ),
                    SizedBox(height: sizes.md),
                    _IntensitySetting(
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
                  ],
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

class _TextPreviewSetting extends StatelessWidget {
  const _TextPreviewSetting({
    required this.label,
    required this.previewStyle,
    required this.onIncrease,
    required this.onDecrease,
  });

  final String label;
  final TextStyle? previewStyle;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.appSizes;

    return Padding(
      padding: EdgeInsets.only(bottom: sizes.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.titleMedium),
          SizedBox(height: sizes.md),
          Center(
            child: Text(
              'A a 1 2 3',
              textAlign: TextAlign.center,
              style: previewStyle,
            ),
          ),
          SizedBox(height: sizes.lg),
          SettingsAdjustmentButtonsWidget(
            onIncrease: onIncrease,
            onDecrease: onDecrease,
          ),
        ],
      ),
    );
  }
}

class _ToggleSetting extends StatelessWidget {
  const _ToggleSetting({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    return Semantics(
      label: label,
      toggled: value,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: sizes.xs),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: theme.textTheme.titleMedium),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: context.appGradientColors.bottom,
              activeTrackColor: colorScheme.surface,
              inactiveThumbColor: colorScheme.onSurfaceVariant,
              inactiveTrackColor: colorScheme.surface,
              trackOutlineColor: WidgetStatePropertyAll(
                colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VolumeSetting extends StatelessWidget {
  const _VolumeSetting({
    required this.volume,
    required this.onIncrease,
    required this.onDecrease,
  });

  final double volume;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Volume:', style: theme.textTheme.titleMedium),
        SizedBox(height: sizes.sm),
        Semantics(
          button: true,
          label: 'Tocar som de exemplo',
          value: '${(volume * 100).round()} por cento',
          child: Material(
            color: colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(sizes.radiusFull),
              side: BorderSide(color: colorScheme.outline),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => SystemSound.play(SystemSoundType.click),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: sizes.md,
                  vertical: sizes.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tocar',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.notifications_rounded,
                      color: colorScheme.primary,
                      size: sizes.icon(sizes.md),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: sizes.md),
        SettingsAdjustmentButtonsWidget(
          onIncrease: onIncrease,
          onDecrease: onDecrease,
        ),
      ],
    );
  }
}

class _IntensitySetting extends StatelessWidget {
  const _IntensitySetting({
    required this.value,
    required this.onChanged,
    required this.onIncrease,
    required this.onDecrease,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    return Column(
      children: [
        Semantics(
          label: 'Intensidade das cores',
          value: '${(value * 100).round()} por cento',
          increasedValue:
              '${((value + .1).clamp(.5, 1) * 100).round()} por cento',
          decreasedValue:
              '${((value - .1).clamp(.5, 1) * 100).round()} por cento',
          onIncrease: onIncrease,
          onDecrease: onDecrease,
          child: LayoutBuilder(
            builder: (context, constraints) {
              void updateValue(double horizontalPosition) {
                final newValue = horizontalPosition / constraints.maxWidth;
                onChanged(newValue.clamp(.5, 1).toDouble());
              }

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  updateValue(details.localPosition.dx);
                },
                onHorizontalDragUpdate: (details) {
                  updateValue(details.localPosition.dx);
                },
                child: Container(
                  height: sizes.buttonSmall * .62,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(sizes.radiusFull),
                    border: Border.all(color: colorScheme.outline),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: .14),
                        blurRadius: sizes.xs,
                        offset: Offset(0, sizes.xs / 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: value,
                        child: ColoredBox(
                          color: context.appGradientColors.bottom,
                        ),
                      ),
                      Center(
                        child: Text(
                          '${(value * 100).round()}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: sizes.md),
        SettingsAdjustmentButtonsWidget(
          onIncrease: onIncrease,
          onDecrease: onDecrease,
        ),
      ],
    );
  }
}
