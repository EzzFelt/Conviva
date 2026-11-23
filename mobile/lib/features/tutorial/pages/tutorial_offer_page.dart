import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/route_names.dart';
import '../../../shared/widgets/button_widget.dart';
import '../../auth/providers/current_user_provider.dart';
import '../services/elder_tutorial_storage.dart';

/// Tela exibida logo depois do cadastro do idoso, perguntando se ele quer
/// fazer o tutorial.
class TutorialOfferPage extends ConsumerStatefulWidget {
  const TutorialOfferPage({super.key});

  @override
  ConsumerState<TutorialOfferPage> createState() => _TutorialOfferPageState();
}

class _TutorialOfferPageState extends ConsumerState<TutorialOfferPage> {
  bool _isBusy = false;

  Future<void> _decide({required bool startTutorial}) async {
    if (_isBusy) return;

    setState(() => _isBusy = true);

    // Depois da escolha (fazer ou pular), a pergunta não aparece de novo.
    final session = ref.read(currentUserProvider).value;
    if (session != null) {
      await ElderTutorialStorage.clearPending(session.uid);
    }

    if (!mounted) return;

    // Continuar abre a personalização do app; só depois dela começa o
    // tutorial da tela inicial.
    context.go(
      startTutorial ? RouteNames.tutorialSetup : RouteNames.elderHome,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final gradient = context.appGradientColors;

    final titleStyle = theme.textTheme.headlineLarge?.copyWith(
      color: colorScheme.primary,
      fontWeight: FontWeight.w800,
      fontSize: 26,
    );
    final questionStyle = theme.textTheme.titleLarge?.copyWith(
      color: AppColors.textPrimary.withValues(alpha: .8),
      fontWeight: FontWeight.w800,
      fontSize: 22,
      height: 1.3,
    );

    return PopScope(
      // O cadastro já foi concluído: não há para onde voltar.
      canPop: false,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: Column(
          children: [
            Container(
              width: double.infinity,
              height: MediaQuery.paddingOf(context).top + sizes.xxl * 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [gradient.top, gradient.bottom],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(sizes.xxl + sizes.sm),
                ),
              ),
            ),
            Expanded(
              child: SafeArea(
                top: false,
                child: CustomScrollView(
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: sizes.lg),
                        child: Column(
                          children: [
                            const Spacer(flex: 3),
                            Text(
                              'Sua conta foi criada\ncom sucesso!',
                              textAlign: TextAlign.center,
                              style: titleStyle,
                            ),
                            SizedBox(height: sizes.xl + sizes.md),
                            Text.rich(
                              TextSpan(
                                style: questionStyle,
                                children: [
                                  const TextSpan(text: 'Deseja fazer um '),
                                  TextSpan(
                                    text: 'tutorial',
                                    style: questionStyle?.copyWith(
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const TextSpan(
                                    text:
                                        '\npara que você aprenda a\n'
                                        'usar nosso aplicativo?',
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const Spacer(flex: 4),
                            ButtonWidget(
                              label: 'Continuar',
                              variant: ButtonVariant.primary,
                              onPressed: _isBusy
                                  ? null
                                  : () => _decide(startTutorial: true),
                            ),
                            SizedBox(height: sizes.md),
                            ButtonWidget(
                              label: 'Pular tutorial',
                              variant: ButtonVariant.outlined,
                              onPressed: _isBusy
                                  ? null
                                  : () => _decide(startTutorial: false),
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
          ],
        ),
      ),
    );
  }
}
