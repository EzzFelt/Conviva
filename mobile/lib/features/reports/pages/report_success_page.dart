import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/report_flow_scaffold.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/constants/assets_paths.dart';
import '../../auth/providers/current_user_provider.dart';
import '../../auth/providers/authenticated_user_navigator.dart';
import '../models/report_draft.dart';

class ReportSuccessPage extends ConsumerWidget {
  const ReportSuccessPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sizes = context.appSizes;

    return ReportFlowScaffold(
      step: ReportFlowScaffold.totalSteps,
      showProgress: false,
      body: Padding(
        padding: EdgeInsets.all(sizes.lg),
        child: Column(
          children: [
            SizedBox(height: sizes.xxl),
            Text(
              'Sua denúncia foi finalizada com sucesso!',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: sizes.xxl),
            Expanded(
              child: Center(
                child: Image.asset(
                  AssetPaths.reportSuccess,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                ref.read(reportDraftProvider.notifier).reset();
                final session = await ref.read(currentUserProvider.future);
                if (!context.mounted) return;
                if (session == null) {
                  context.go(RouteNames.onboarding);
                } else {
                  await AuthenticatedUserNavigator.open(context, session);
                }
              },
              child: const Text('Voltar para o início'),
            ),
            SizedBox(height: sizes.xl),
          ],
        ),
      ),
    );
  }
}
