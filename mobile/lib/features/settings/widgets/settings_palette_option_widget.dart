import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/button_widget.dart';

class SettingsPaletteOptionWidget extends StatelessWidget {
  const SettingsPaletteOptionWidget({
    super.key,
    required this.colors,
    required this.selected,
    required this.onSelected,
  }) : assert(colors.length == 3);

  final List<Color> colors;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final circleSize = sizes.xxl * 2.2;
    final sideCircleSize = circleSize * .7;
    final centerOffset = sideCircleSize * .68;
    final rightOffset = centerOffset + circleSize * .7;
    final circlesWidth = rightOffset + sideCircleSize;

    return Semantics(
      button: true,
      selected: selected,
      label: selected ? 'Paleta selecionada' : 'Selecionar paleta',
      child: Column(
        children: [
          Material(
            color: colorScheme.surface,
            elevation: 1,
            shadowColor: colorScheme.shadow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(sizes.radiusMd),
              side: BorderSide(color: colorScheme.outline),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onSelected,
              child: SizedBox(
                width: double.infinity,
                height: sizes.xxl * 4.2,
                child: Center(
                  child: SizedBox(
                    width: circlesWidth,
                    height: circleSize,
                    child: Stack(
                      children: [
                        _PaletteCircle(
                          color: colors[0],
                          size: sideCircleSize,
                          left: 0,
                          top: circleSize * .3,
                          borderColor: colorScheme.outline,
                        ),
                        _PaletteCircle(
                          color: colors[2],
                          size: sideCircleSize,
                          left: rightOffset,
                          top: 0,
                          borderColor: colorScheme.outline,
                        ),
                        _PaletteCircle(
                          color: colors[1],
                          size: circleSize,
                          left: centerOffset,
                          top: 0,
                          borderColor: colorScheme.outline,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: sizes.md),
          ButtonWidget(
            label: selected ? 'Selecionado' : 'Selecionar',
            size: ButtonSize.large,
            variant: selected
                ? ButtonVariant.secondary
                : ButtonVariant.outlined,
            onPressed: onSelected,
          ),
        ],
      ),
    );
  }
}

class _PaletteCircle extends StatelessWidget {
  const _PaletteCircle({
    required this.color,
    required this.size,
    required this.left,
    required this.top,
    required this.borderColor,
  });

  final Color color;
  final double size;
  final double left;
  final double top;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor),
        ),
      ),
    );
  }
}
