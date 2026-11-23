import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';
import '../../../shared/widgets/button_widget.dart';

/// Tela final do tutorial do idoso ("Parabéns!").
class TutorialDonePage extends StatelessWidget {
  const TutorialDonePage({super.key});

  /// Ilustração da tela final. A pasta `assets/images/onboarding/` já está
  /// registrada no pubspec.yaml.
  static const _imagePath = 'assets/images/onboarding/tutorial_concluido.png';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    final textStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w800,
      fontSize: 22,
      height: 1.3,
    );
    final highlightStyle = textStyle?.copyWith(color: colorScheme.primary);

    return PopScope(
      // O tutorial acabou: não há para onde voltar.
      canPop: false,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: sizes.lg),
                  child: Column(
                    children: [
                      SizedBox(height: sizes.xxl),
                      Text(
                        'Parabéns!',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 32,
                        ),
                      ),
                      const Spacer(),
                      Image.asset(
                        _imagePath,
                        width: math.min(
                          MediaQuery.sizeOf(context).width * .62,
                          280,
                        ),
                        fit: BoxFit.contain,
                        // Se a imagem ainda não estiver no projeto, mostra um
                        // ícone em vez de quebrar a tela.
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.celebration_rounded,
                            size: sizes.xxl * 3,
                            color: colorScheme.primary,
                          );
                        },
                      ),
                      const Spacer(),
                      Text.rich(
                        TextSpan(
                          style: textStyle,
                          children: [
                            const TextSpan(text: 'Você terminou nosso\n'),
                            TextSpan(text: 'tutorial', style: highlightStyle),
                            const TextSpan(text: ' e está pronto\npara usar o '),
                            TextSpan(text: 'aplicativo', style: highlightStyle),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: sizes.xl),
                      ButtonWidget(
                        label: 'Comece agora!',
                        variant: ButtonVariant.primary,
                        onPressed: () => context.go(RouteNames.elderHome),
                      ),
                      SizedBox(height: sizes.xl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
