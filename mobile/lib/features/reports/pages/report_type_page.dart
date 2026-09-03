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
      body: Padding(
        padding: EdgeInsets.all(sizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Que tipo de denúncia deseja fazer?',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: sizes.lg),
            ReportTypeCard(
              title: 'Pessoal',
              description: 'Relate algo que aconteceu com você.',
              onTap: () => _select(context, ref, ReportKind.personal),
            ),
            SizedBox(height: sizes.md),
            ReportTypeCard(
              title: 'De terceiros',
              description: 'Relate algo que aconteceu com outra pessoa.',
              onTap: () => _select(context, ref, ReportKind.thirdParty),
            ),
          ],
        ),
      ),
    );
  }

  void _select(BuildContext context, WidgetRef ref, ReportKind kind) {
    ref.read(reportDraftProvider.notifier).update(ReportDraft(kind: kind));
    context.go(RouteNames.reportForm, extra: ReportDraft(kind: kind));
  }
}
