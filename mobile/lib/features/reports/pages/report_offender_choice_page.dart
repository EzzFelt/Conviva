import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/report_offender_card.dart';
import '../widgets/report_flow_scaffold.dart';
import '../models/report_draft.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/assets_paths.dart';
import '../../../core/routes/route_names.dart';

class ReportOffenderChoicePage extends ConsumerStatefulWidget {
  final ReportDraft draft;
  const ReportOffenderChoicePage({super.key, required this.draft});

  @override
  ConsumerState<ReportOffenderChoicePage> createState() =>
      _ReportOffenderChoicePageState();
}

class _ReportOffenderChoicePageState
    extends ConsumerState<ReportOffenderChoicePage> {
  OffenderKind? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.draft.offender;
  }

  @override
  Widget build(BuildContext context) {
    final sizes = context.appSizes;

    Widget illustrationFor(OffenderKind kind) {
      switch (kind) {
        case OffenderKind.relative:
          return Image.asset(AssetPaths.reportRelative, fit: BoxFit.contain);
        case OffenderKind.caregiver:
          return Image.asset(AssetPaths.reportCaregiver, fit: BoxFit.contain);
        case OffenderKind.institution:
          return Image.asset(AssetPaths.reportInstitution, fit: BoxFit.contain);
      }
    }

    return ReportFlowScaffold(
      step: 4,
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
                      final updated = widget.draft.copyWith(
                        offender: _selected,
                      );
                      ref.read(reportDraftProvider.notifier).update(updated);
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
