import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import 'settings_adjustment_buttons_widget.dart';

/// Controles de configuração usados na tela de configurações e no passo a
/// passo de personalização do tutorial do idoso.

class SettingsTextPreview extends StatelessWidget {
  const SettingsTextPreview({
    super.key,
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

class SettingsToggle extends StatelessWidget {
  const SettingsToggle({
    super.key,
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
        padding: EdgeInsets.symmetric(vertical: sizes.sm),
        child: Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.titleMedium)),
            Transform.scale(
              scale: 1.1,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: context.appGradientColors.bottom,
                activeTrackColor: colorScheme.surface,
                inactiveThumbColor: colorScheme.onSurfaceVariant,
                inactiveTrackColor: colorScheme.surface,
                trackOutlineColor: WidgetStatePropertyAll(colorScheme.outline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsVolume extends StatelessWidget {
  const SettingsVolume({
    super.key,
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
                  vertical: sizes.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tocar',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.notifications_rounded,
                      color: colorScheme.primary,
                      size: sizes.icon(sizes.lg),
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

class SettingsIntensity extends StatelessWidget {
  const SettingsIntensity({
    super.key,
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
                  height: sizes.buttonSmall * .85,
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
                          style: theme.textTheme.bodyMedium?.copyWith(
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
