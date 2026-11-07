import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/assets_paths.dart';
import '../../../core/routes/route_names.dart';
import '../../../shared/widgets/button_widget.dart';
import '../models/report_draft.dart';
import '../widgets/report_flow_scaffold.dart';

class ReportStartPage extends ConsumerWidget {
  const ReportStartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    return ReportFlowScaffold(
      step: 1,
      fallbackRoute: RouteNames.menu,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: sizes.lg),
        child: Column(
          children: [
            SizedBox(height: sizes.lg),
            Text.rich(
              TextSpan(
                text: 'Bem vindo a ',
                children: [
                  TextSpan(
                    text: 'Central de\nDenúncias!',
                    style: TextStyle(color: colorScheme.primary),
                  ),
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
                    AssetPaths.reportEmergency,
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
          constraints: const BoxConstraints(maxWidth: 240),
          child: ButtonWidget(
            label: 'Continuar',
            onPressed: () {
              ref.read(reportDraftProvider.notifier).reset();
              context.push(RouteNames.reportType);
            },
          ),
        ),
      ),
    );
  }
}
