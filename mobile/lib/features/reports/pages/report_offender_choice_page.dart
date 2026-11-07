import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/assets_paths.dart';
import '../../../core/routes/route_names.dart';
import '../../../shared/widgets/button_widget.dart';
import '../models/report_draft.dart';
import '../widgets/report_flow_scaffold.dart';
import '../widgets/report_offender_card.dart';

class ReportOffenderChoicePage extends ConsumerStatefulWidget {
  const ReportOffenderChoicePage({super.key, this.draft});

  final ReportDraft? draft;

  @override
  ConsumerState<ReportOffenderChoicePage> createState() =>
      _ReportOffenderChoicePageState();
}

class _ReportOffenderChoicePageState
    extends ConsumerState<ReportOffenderChoicePage> {
  late ReportDraft _draft;
  OffenderKind? _selected;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft ?? ref.read(reportDraftProvider);
    _selected = _draft.offender;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.appSizes;

    Widget card(OffenderKind kind, String label, String asset) {
      return ReportOffenderCard(
        label: label,
        illustration: Image.asset(asset, fit: BoxFit.contain),
        selected: _selected == kind,
        onTap: () => setState(() => _selected = kind),
      );
    }

    return ReportFlowScaffold(
      step: 4,
      fallbackRoute: RouteNames.reportForm,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(sizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Quem fez isto?',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            SizedBox(height: sizes.lg),
            card(OffenderKind.relative, 'Parente', AssetPaths.reportRelative),
            SizedBox(height: sizes.md),
            card(OffenderKind.caregiver, 'Cuidador', AssetPaths.reportCaregiver),
            SizedBox(height: sizes.md),
            card(
              OffenderKind.institution,
              'Instituição',
              AssetPaths.reportInstitution,
            ),
          ],
        ),
      ),
      bottomButton: ButtonWidget(
        label: 'Continuar',
        onPressed: _selected == null
            ? null
            : () {
                final updated = _draft.copyWith(offender: _selected);
                ref.read(reportDraftProvider.notifier).update(updated);
                context.push(RouteNames.reportSelectPerson, extra: updated);
              },
      ),
    );
  }
}
