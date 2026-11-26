import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';
import '../models/report_draft.dart';
import '../widgets/report_flow_scaffold.dart';
import '../widgets/report_type_card.dart';

class ReportTypePage extends ConsumerWidget {
  const ReportTypePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sizes = context.appSizes;

    return ReportFlowScaffold(
      step: 2,
      fallbackRoute: RouteNames.reportStart,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(sizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: sizes.lg),
            Text(
              'Essa denúncia é:',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: sizes.xl),
            ReportTypeCard(
              title: 'Pessoal',
              description: 'Você é a pessoa que está sendo alvo da situação',
              onTap: () => _select(context, ref, ReportKind.personal),
            ),
            SizedBox(height: sizes.lg),
            ReportTypeCard(
              title: 'De Terceiros',
              description: 'Outra pessoa está sendo afetada pela situação',
              onTap: () => _select(context, ref, ReportKind.thirdParty),
            ),
          ],
        ),
      ),
    );
  }

  void _select(BuildContext context, WidgetRef ref, ReportKind kind) {
    final draft = ReportDraft(kind: kind);
    ref.read(reportDraftProvider.notifier).update(draft);
    context.push(RouteNames.reportForm, extra: draft);
  }
}
