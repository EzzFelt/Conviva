import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';
import 'report_progress_bar.dart';

/// Estrutura comum das telas da Central de Denúncias.
///
/// A seta de voltar volta sempre para a etapa anterior:
/// - se existir uma tela anterior na pilha, faz `pop`;
/// - senão (ex.: página recarregada), vai para [fallbackRoute].
/// Use [onBack] para sobrescrever totalmente esse comportamento.
class ReportFlowScaffold extends StatelessWidget {
  const ReportFlowScaffold({
    super.key,
    required this.step,
    required this.body,
    this.bottomButton,
    this.orangeHeader = false,
    this.showProgress = true,
    this.fallbackRoute,
    this.onBack,
  });

  static const totalSteps = 6;

  final int step;
  final Widget body;
  final Widget? bottomButton;

  /// Cabeçalho laranja com o conteúdo numa folha branca (tela "Selecionar").
  final bool orangeHeader;
  final bool showProgress;
  final String? fallbackRoute;
  final VoidCallback? onBack;

  void _handleBack(BuildContext context) {
    if (onBack != null) {
      onBack!();
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(fallbackRoute ?? RouteNames.menu);
    }
  }

  Widget _backButton(BuildContext context, Color color) {
    final sizes = context.appSizes;

    return Padding(
      padding: EdgeInsets.fromLTRB(sizes.md, sizes.sm, sizes.lg, sizes.sm),
      child: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          tooltip: 'Voltar',
          onPressed: () => _handleBack(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: color,
            size: sizes.icon(sizes.lg),
          ),
        ),
      ),
    );
  }

  Widget _bottom(BuildContext context) {
    final sizes = context.appSizes;

    return Padding(
      padding: EdgeInsets.fromLTRB(sizes.lg, sizes.sm, sizes.lg, sizes.md),
      child: bottomButton,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sizes = context.appSizes;

    if (orangeHeader) {
      final gradient = context.appGradientColors;

      return Scaffold(
        backgroundColor: gradient.top,
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [gradient.top, gradient.bottom],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _backButton(context, AppColors.white),
                Expanded(
                  child: Material(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(sizes.radiusLg),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SafeArea(
                      top: false,
                      child: Column(
                        children: [
                          Expanded(child: body),
                          if (bottomButton != null) _bottom(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _backButton(context, colorScheme.primary),
            if (showProgress)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: sizes.lg),
                child: ReportProgressBar(step: step, totalSteps: totalSteps),
              ),
            Expanded(child: body),
            if (bottomButton != null) _bottom(context),
          ],
        ),
      ),
    );
  }
}
