import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/assets_paths.dart';
import '../../../core/routes/route_names.dart';
import '../../../shared/widgets/button_widget.dart';
import '../../auth/providers/authenticated_user_navigator.dart';
import '../../auth/providers/current_user_provider.dart';
import '../models/report_draft.dart';
import '../widgets/report_flow_scaffold.dart';

class ReportSuccessPage extends ConsumerWidget {
  const ReportSuccessPage({super.key});

  Future<void> _goHome(BuildContext context, WidgetRef ref) async {
    ref.read(reportDraftProvider.notifier).reset();
    final session = await ref.read(currentUserProvider.future);
    if (!context.mounted) return;

    if (session == null) {
      context.go(RouteNames.onboarding);
    } else {
      await AuthenticatedUserNavigator.open(context, session);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    return ReportFlowScaffold(
      step: ReportFlowScaffold.totalSteps,
      // A denúncia já foi enviada: voltar leva ao início, não à etapa anterior.
      onBack: () => _goHome(context, ref),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: sizes.lg),
        child: Column(
          children: [
            SizedBox(height: sizes.xl),
            Text.rich(
              TextSpan(
                text: 'Sua ',
                children: [
                  TextSpan(
                    text: 'denúncia',
                    style: TextStyle(color: colorScheme.primary),
                  ),
                  const TextSpan(text: ' foi\nfinalizada com sucesso!'),
                ],
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: sizes.md),
                  child: Image.asset(
                    AssetPaths.reportSuccess,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomButton: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: ButtonWidget(
            label: 'Voltar para o início',
            onPressed: () => _goHome(context, ref),
          ),
        ),
      ),
    );
  }
}
