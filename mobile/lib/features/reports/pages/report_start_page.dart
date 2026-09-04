import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/report_type_card.dart';
import '../models/report_draft.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';

class ReportStartPage extends StatelessWidget {
  const ReportStartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sizes = context.appSizes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Denuncie'),
      ),
      body: Padding(
        padding: EdgeInsets.all(sizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Que tipo de denúncia deseja fazer?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: sizes.lg),
            ReportTypeCard(
              title: 'É sobre você',
              description: 'Relate algo que aconteceu com você',
              onTap: () {
                final draft = ReportDraft(kind: ReportKind.personal);
                context.go(RouteNames.reportForm, extra: draft);
              },
            ),
            SizedBox(height: sizes.md),
            ReportTypeCard(
              title: 'É sobre outra pessoa',
              description: 'Relate algo que aconteceu com outra pessoa',
              onTap: () {
                final draft = ReportDraft(kind: ReportKind.thirdParty);
                context.go(RouteNames.reportForm, extra: draft);
              },
            ),
          ],
        ),
      ),
    );
  }
}
