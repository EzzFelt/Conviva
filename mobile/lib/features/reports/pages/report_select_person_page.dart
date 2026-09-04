import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/report_draft.dart';
import '../widgets/report_flow_scaffold.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';

class ReportSelectPersonPage extends StatefulWidget {
  final ReportDraft draft;
  const ReportSelectPersonPage({super.key, required this.draft});

  @override
  State<ReportSelectPersonPage> createState() => _ReportSelectPersonPageState();
}

class _ReportSelectPersonPageState extends State<ReportSelectPersonPage> {
  @override
  Widget build(BuildContext context) {
    final sizes = context.appSizes;
    final offender = widget.draft.offender;

    List<MockReportedPerson> persons;
    if (offender == OffenderKind.caregiver) {
      persons = MockReportData.caregivers;
    } else if (offender == OffenderKind.relative) {
      persons = MockReportData.relatives;
    } else {
      // Institution selected - show institution as single option and also an "Other" form
      persons = [MockReportData.institution];
    }

    return ReportFlowScaffold(
      step: 3,
      useGradient: offender == OffenderKind.caregiver,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(sizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              offender == OffenderKind.caregiver
                  ? 'Selecione o cuidador:'
                  : offender == OffenderKind.relative
                      ? 'Selecione o parente:'
                      : 'Selecione a instituição:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: sizes.md),
            ...persons.map(
              (p) => Padding(
                padding: EdgeInsets.symmetric(vertical: sizes.xs),
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(sizes.lg),
                    child: Row(
                      children: [
                        CircleAvatar(
                          child: p.imageAsset != null ? Image.asset(p.imageAsset!) : null,
                        ),
                        SizedBox(width: sizes.lg),
                        Expanded(
                          child: Text(p.name, style: Theme.of(context).textTheme.titleMedium),
                        ),
                        TextButton(
                          onPressed: () => _confirmPerson(p),
                          child: const Text('Selecionar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (offender == OffenderKind.institution) ...[
              SizedBox(height: sizes.lg),
              Text('Outro (escreva o que você conseguir):', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: sizes.sm),
              TextField(decoration: const InputDecoration(hintText: 'Nome do cuidador')),
              SizedBox(height: sizes.sm),
              TextField(decoration: const InputDecoration(hintText: 'Telefone')),
              SizedBox(height: sizes.sm),
              TextField(decoration: const InputDecoration(hintText: 'Instituto')),
            ],
            SizedBox(height: sizes.xxl),
          ],
        ),
      ),
    );
  }

  void _confirmPerson(MockReportedPerson person) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Tem certeza que deseja denunciar esta pessoa?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 36, child: person.imageAsset != null ? Image.asset(person.imageAsset!) : null),
            SizedBox(height: 12),
            Text(person.name, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirmed == true) {
      // In a real app, here we would submit to backend. For mock flow, navigate to success.
      if (!mounted) return;
      context.go(RouteNames.reportSuccess);
    }
  }
}
