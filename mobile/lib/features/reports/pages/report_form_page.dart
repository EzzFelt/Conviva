import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import '../models/report_draft.dart';
import '../widgets/report_flow_scaffold.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';

class ReportFormPage extends StatefulWidget {
  final ReportDraft? initialDraft;
  const ReportFormPage({super.key, this.initialDraft});

  @override
  State<ReportFormPage> createState() => _ReportFormPageState();
}

class _ReportFormPageState extends State<ReportFormPage> {
  late ReportDraft draft;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Prefer the draft passed through the widget (router builder). Fallback to extras if needed.
    final extra = ModalRoute.of(context)?.settings.arguments;
    draft = widget.initialDraft ?? ReportDraft.fromExtra((extra is ReportDraft) ? extra : null);
    _controller.text = draft.description;
  }

  void _submit() {
    // Move to offender selection step, passing the filled draft along.
    final updated = draft.copyWith(description: _controller.text);
    if (mounted) context.go(RouteNames.reportOffenderChoice, extra: updated);
  }

  @override
  Widget build(BuildContext context) {
    final sizes = context.appSizes;

    return ReportFlowScaffold(
      step: 1,
      body: Padding(
        padding: EdgeInsets.all(sizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              draft.kind == ReportKind.personal ? 'Seu relato' : 'Relato sobre a pessoa',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: sizes.md),
            TextField(
              controller: _controller,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'Descreva o ocorrido (quanto mais detalhes, melhor)',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {},
            ),
          ],
        ),
      ),
      bottomButton: ElevatedButton(
        onPressed: _submit,
        child: const Text('Enviar denúncia (simulação)'),
      ),
    );
  }
}
