import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/assets_paths.dart';
import '../../core/settings/app_settings_provider.dart';

/// Mascote do Auri.
///
/// Na paleta padrão (laranja) usa a ilustração original do Figma. O PNG tem
/// as cores "gravadas" e não muda com a paleta; por isso, nas outras paletas
/// o robô é desenhado em código, com olhos e sorriso na cor principal do tema.
class AuriAvatarWidget extends ConsumerWidget {
  const AuriAvatarWidget({super.key});

  static const _semanticLabel = 'Assistente virtual Auri';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usesDefaultPalette = ref.watch(
      appSettingsProvider.select(
        (settings) => settings.primaryColor == AppColors.primary,
      ),
    );

    if (usesDefaultPalette) {
      return Image.asset(
        AssetPaths.auri,
        fit: BoxFit.contain,
        semanticLabel: _semanticLabel,
      );
    }

    final accent = Theme.of(context).colorScheme.primary;

    return Semantics(
      label: _semanticLabel,
      image: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = constraints.biggest.shortestSide;

          return Center(
            child: _AuriRobot(
              size: side.isFinite ? side : 80,
              accent: accent,
            ),
          );
        },
      ),
    );
  }
}

class _AuriRobot extends StatelessWidget {
  const _AuriRobot({required this.size, required this.accent});

  final double size;
  final Color accent;

  static const _shell = Color(0xFFF3F4F6);
  static const _shellEdge = Color(0xFFD5D9DF);
  static const _visor = Color(0xFF1E2733);

  @override
  Widget build(BuildContext context) {
    final s = size;

    Widget ear({required bool left}) {
      return Positioned(
        left: left ? s * .05 : null,
        right: left ? null : s * .05,
        top: s * .38,
        child: Container(
          width: s * .1,
          height: s * .24,
          decoration: BoxDecoration(
            color: _shellEdge,
            borderRadius: BorderRadius.circular(s * .05),
          ),
        ),
      );
    }

    Widget eye() {
      return Container(
        width: s * .075,
        height: s * .075,
        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
      );
    }

    return SizedBox.square(
      dimension: s,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ear(left: true),
          ear(left: false),
          Container(
            width: s * .74,
            height: s * .62,
            decoration: BoxDecoration(
              color: _shell,
              borderRadius: BorderRadius.circular(s * .28),
              border: Border.all(color: _shellEdge, width: s * .02),
            ),
            alignment: Alignment.center,
            child: Container(
              width: s * .56,
              height: s * .36,
              decoration: BoxDecoration(
                color: _visor,
                borderRadius: BorderRadius.circular(s * .16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [eye(), SizedBox(width: s * .16), eye()],
                  ),
                  SizedBox(height: s * .03),
                  // Sorriso: metade de baixo de um círculo com borda.
                  ClipRect(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      heightFactor: .5,
                      child: Container(
                        width: s * .12,
                        height: s * .12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: accent, width: s * .02),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
