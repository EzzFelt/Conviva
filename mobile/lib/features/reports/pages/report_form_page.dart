import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';
import '../../../shared/widgets/button_widget.dart';
import '../models/report_draft.dart';
import '../widgets/report_flow_scaffold.dart';
import '../widgets/report_yes_no_group.dart';

class ReportFormPage extends ConsumerStatefulWidget {
  const ReportFormPage({super.key, this.initialDraft});

  final ReportDraft? initialDraft;

  @override
  ConsumerState<ReportFormPage> createState() => _ReportFormPageState();
}

class _ReportFormPageState extends ConsumerState<ReportFormPage> {
  late ReportDraft _draft;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // O rascunho do provider é a fonte da verdade (sobrevive a recarregar a
    // página); o extra do router é usado só como valor inicial.
    _draft = widget.initialDraft ?? ref.read(reportDraftProvider);
    _controller = TextEditingController(text: _draft.description);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateDraft(ReportDraft draft) {
    setState(() => _draft = draft);
    ref.read(reportDraftProvider.notifier).update(draft);
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

    final updated = _draft.copyWith(description: description);
    ref.read(reportDraftProvider.notifier).update(updated);
    context.push(RouteNames.reportOffenderChoice, extra: updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    Widget question(String text) => Padding(
      padding: EdgeInsets.only(top: sizes.lg, bottom: sizes.xs),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.titleMedium,
      ),
    );

    return ReportFlowScaffold(
      step: 3,
      fallbackRoute: RouteNames.reportType,
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(sizes.lg, sizes.lg, sizes.lg, sizes.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Qual foi o ocorrido?',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            SizedBox(height: sizes.lg),
            Material(
              color: colorScheme.surface,
              elevation: sizes.xs / 2,
              shadowColor: colorScheme.shadow.withValues(alpha: .24),
              borderRadius: BorderRadius.circular(sizes.radiusMd),
              child: TextField(
                controller: _controller,
                minLines: 6,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                style: theme.textTheme.bodyLarge,
                onChanged: (value) =>
                    _draft = _draft.copyWith(description: value),
                decoration: InputDecoration(
                  hintText: 'Descreva o ocorrido...',
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  filled: true,
                  fillColor: colorScheme.surface,
                  contentPadding: EdgeInsets.all(sizes.md),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(sizes.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            question('É um caso recente?'),
            ReportYesNoGroup(
              value: _draft.isRecent,
              onChanged: (value) =>
                  _updateDraft(_draft.copyWith(isRecent: value)),
            ),
            question('Ocorreu outras vezes?'),
            ReportYesNoGroup(
              value: _draft.happenedBefore,
              onChanged: (value) =>
                  _updateDraft(_draft.copyWith(happenedBefore: value)),
            ),
          ],
        ),
      ),
      bottomButton: ButtonWidget(label: 'Continuar', onPressed: _submit),
    );
  }
}
