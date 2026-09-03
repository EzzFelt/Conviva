import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/report_draft.dart';
import '../providers/reports_provider.dart';
import '../widgets/report_flow_scaffold.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';
import '../../auth/providers/current_user_provider.dart';

class ReportSelectPersonPage extends ConsumerStatefulWidget {
  final ReportDraft draft;
  const ReportSelectPersonPage({super.key, required this.draft});

  @override
  ConsumerState<ReportSelectPersonPage> createState() =>
      _ReportSelectPersonPageState();
}

class _ReportSelectPersonPageState
    extends ConsumerState<ReportSelectPersonPage> {
  ReportTarget? _selectedTarget;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sizes = context.appSizes;
    final offender = widget.draft.offender;

    if (offender == null) {
      return const ReportFlowScaffold(
        step: 5,
        body: Center(child: Text('Tipo de acusado não informado.')),
      );
    }

    return ReportFlowScaffold(
      step: 5,
      useGradient: offender == OffenderKind.caregiver,
      body: Consumer(
        builder: (context, ref, child) {
          final targets = ref.watch(reportTargetsProvider(offender));
          return targets.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                Center(child: Text('Erro ao carregar alvos: $error')),
            data: (items) => _buildTargets(context, items, sizes),
          );
        },
      ),
      bottomButton: ElevatedButton(
        onPressed: _selectedTarget == null
            ? null
            : () => _confirmTarget(_selectedTarget!),
        child: const Text('Continuar'),
      ),
    );
  }

  Widget _buildTargets(
    BuildContext context,
    List<ReportTarget> targets,
    AppSizesTheme sizes,
  ) {
    if (targets.isEmpty) {
      return const Center(child: Text('Nenhum alvo disponível para denúncia.'));
    }
    return ListView(
      padding: EdgeInsets.all(sizes.lg),
      children: [
        Text(
          'Selecione o acusado:',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        SizedBox(height: sizes.md),
        ...targets.map(
          (target) => Card(
            child: ListTile(
              leading: _targetAvatar(target),
              title: Text(target.name),
              trailing: TextButton(
                onPressed: () => setState(() => _selectedTarget = target),
                child: const Text('Selecionar'),
              ),
              selected: _selectedTarget?.id == target.id,
            ),
          ),
        ),
      ],
    );
  }

  Widget _targetAvatar(ReportTarget target) {
    if (target.photoUrl == null) {
      return const CircleAvatar(child: Icon(Icons.person));
    }
    return CircleAvatar(backgroundImage: NetworkImage(target.photoUrl!));
  }

  Future<void> _confirmTarget(ReportTarget target) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Tem certeza que deseja denunciar esta pessoa?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundImage: target.photoUrl == null
                  ? null
                  : NetworkImage(target.photoUrl!),
              child: target.photoUrl == null ? const Icon(Icons.person) : null,
            ),
            SizedBox(height: 12),
            Text(target.name, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final session = await ref.read(currentUserProvider.future);
      if (session == null || !mounted) return;

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      try {
        await submitReport(
          draft: widget.draft,
          target: target,
          session: session,
        );
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        ref
            .read(reportDraftProvider.notifier)
            .update(
              widget.draft.copyWith(
                person: MockReportedPerson(id: target.id, name: target.name),
              ),
            );
        context.go(RouteNames.reportSuccess);
      } catch (error) {
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível salvar a denúncia: $error')),
        );
      }
    }
  }
}
