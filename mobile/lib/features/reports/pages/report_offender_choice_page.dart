import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/report_offender_card.dart';
import '../widgets/report_flow_scaffold.dart';
import '../models/report_draft.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';

class ReportOffenderChoicePage extends StatefulWidget {
  final ReportDraft draft;
  const ReportOffenderChoicePage({super.key, required this.draft});

  @override
  State<ReportOffenderChoicePage> createState() => _ReportOffenderChoicePageState();
}

class _ReportOffenderChoicePageState extends State<ReportOffenderChoicePage> {
  OffenderKind? _selected;

  @override
  Widget build(BuildContext context) {
    final sizes = context.appSizes;

    Widget illustrationFor(OffenderKind kind) {
      switch (kind) {
        case OffenderKind.relative:
          return Icon(Icons.family_restroom, size: sizes.xxl * 1.2);
        case OffenderKind.caregiver:
          return Icon(Icons.health_and_safety, size: sizes.xxl * 1.2);
        case OffenderKind.institution:
          return Icon(Icons.apartment, size: sizes.xxl * 1.2);
      }
    }

    return ReportFlowScaffold(
      step: 2,
      body: Padding(
        padding: EdgeInsets.all(sizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Quem fez isto?',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: sizes.lg),
            ReportOffenderCard(
              label: 'Parente',
              illustration: illustrationFor(OffenderKind.relative),
              selected: _selected == OffenderKind.relative,
              onTap: () => setState(() => _selected = OffenderKind.relative),
            ),
            SizedBox(height: sizes.md),
            ReportOffenderCard(
              label: 'Cuidador',
              illustration: illustrationFor(OffenderKind.caregiver),
              selected: _selected == OffenderKind.caregiver,
              onTap: () => setState(() => _selected = OffenderKind.caregiver),
            ),
            SizedBox(height: sizes.md),
            ReportOffenderCard(
              label: 'Instituição',
              illustration: illustrationFor(OffenderKind.institution),
              selected: _selected == OffenderKind.institution,
              onTap: () => setState(() => _selected = OffenderKind.institution),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _selected == null
                  ? null
                  : () {
                      final updated = widget.draft.copyWith(offender: _selected);
                      context.go(RouteNames.reportSelectPerson, extra: updated);
                    },
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}
