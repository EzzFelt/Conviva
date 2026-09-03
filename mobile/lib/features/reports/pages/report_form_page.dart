import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../models/report_draft.dart';
import '../widgets/report_flow_scaffold.dart';
import '../widgets/report_yes_no_group.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';

class ReportFormPage extends ConsumerStatefulWidget {
  final ReportDraft? initialDraft;
  const ReportFormPage({super.key, this.initialDraft});

  @override
  ConsumerState<ReportFormPage> createState() => _ReportFormPageState();
}

class _ReportFormPageState extends ConsumerState<ReportFormPage> {
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
    draft =
        widget.initialDraft ??
        ReportDraft.fromExtra((extra is ReportDraft) ? extra : null);
    _controller.text = draft.description;
  }

  void _submit() {
    final description = _controller.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Descreva o ocorrido antes de continuar.'),
        ),
      );
      return;
    }
    final updated = draft.copyWith(description: description);
    ref.read(reportDraftProvider.notifier).update(updated);
    if (mounted) context.go(RouteNames.reportOffenderChoice, extra: updated);
  }

  @override
  Widget build(BuildContext context) {
    final sizes = context.appSizes;

    return ReportFlowScaffold(
      step: 3,
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(sizes.lg, sizes.lg, sizes.lg, sizes.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              draft.kind == ReportKind.personal
                  ? 'Seu relato'
                  : 'Relato sobre a pessoa',
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
            ),
            SizedBox(height: sizes.lg),
            const Text('É um caso recente?'),
            ReportYesNoGroup(
              value: draft.isRecent,
              onChanged: (value) {
                setState(() => draft = draft.copyWith(isRecent: value));
                ref.read(reportDraftProvider.notifier).update(draft);
              },
            ),
            const Text('Ocorreu outras vezes?'),
            ReportYesNoGroup(
              value: draft.happenedBefore,
              onChanged: (value) {
                setState(() => draft = draft.copyWith(happenedBefore: value));
                ref.read(reportDraftProvider.notifier).update(draft);
              },
            ),
          ],
        ),
      ),
      bottomButton: ElevatedButton(
        onPressed: _submit,
        child: const Text('Continuar'),
      ),
    );
  }
}
