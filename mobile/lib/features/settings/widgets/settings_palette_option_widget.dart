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
    final circleSize = sizes.xxl;
    final overlap = circleSize * .58;

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
                height: sizes.xxl * 1.65,
                child: Center(
                  child: SizedBox(
                    width: circleSize + overlap * 2,
                    height: circleSize,
                    child: Stack(
                      children: List.generate(colors.length, (index) {
                        return Positioned(
                          left: index * overlap,
                          child: Container(
                            width: circleSize,
                            height: circleSize,
                            decoration: BoxDecoration(
                              color: colors[index],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.outline,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: sizes.sm),
          ButtonWidget(
            label: selected ? 'Selecionado' : 'Selecionar',
            size: ButtonSize.small,
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
