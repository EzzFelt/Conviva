import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';
import '../../../shared/utils/profile_image.dart';
import '../../../shared/widgets/app_modal_widget.dart';
import '../../../shared/widgets/button_widget.dart';
import '../../auth/providers/current_user_provider.dart';
import '../models/report_draft.dart';
import '../providers/reports_provider.dart';
import '../widgets/report_flow_scaffold.dart';
import '../widgets/report_pill_field.dart';

class ReportSelectPersonPage extends ConsumerStatefulWidget {
  const ReportSelectPersonPage({super.key, this.draft});

  final ReportDraft? draft;

  @override
  ConsumerState<ReportSelectPersonPage> createState() =>
      _ReportSelectPersonPageState();
}

class _ReportSelectPersonPageState
    extends ConsumerState<ReportSelectPersonPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _instituteController = TextEditingController();

  late final ReportDraft _draft;
  ReportTarget? _selectedTarget;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft ?? ref.read(reportDraftProvider);
    _nameController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_onTextChanged)
      ..dispose();
    _phoneController.dispose();
    _instituteController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_nameController.text.trim().isNotEmpty) {
      _selectedTarget = null;
    }
    setState(() {});
  }

  bool get _isInstitution => _draft.offender == OffenderKind.institution;

  String get _selectTitle => switch (_draft.offender) {
    OffenderKind.caregiver => 'Selecione o cuidador:',
    OffenderKind.relative => 'Selecione o parente:',
    OffenderKind.institution => 'Selecione a instituição:',
    null => 'Selecione o acusado:',
  };

  String get _nameHint => switch (_draft.offender) {
    OffenderKind.caregiver => 'Nome do cuidador',
    OffenderKind.relative => 'Nome do parente',
    OffenderKind.institution => 'Nome da instituição',
    null => 'Nome',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.appSizes;
    final offender = _draft.offender;

    if (offender == null) {
      return ReportFlowScaffold(
        step: 5,
        orangeHeader: true,
        fallbackRoute: RouteNames.reportOffenderChoice,
        body: const Center(child: Text('Tipo de acusado não informado.')),
      );
    }

    final targets = ref.watch(reportTargetsProvider(offender));

    return ReportFlowScaffold(
      step: 5,
      orangeHeader: true,
      fallbackRoute: RouteNames.reportOffenderChoice,
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(sizes.lg, sizes.lg, sizes.lg, sizes.xl),
        children: [
          Text(
            _selectTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          SizedBox(height: sizes.md),
          targets.when(
            loading: () => Padding(
              padding: EdgeInsets.all(sizes.lg),
              child: const Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Text(
              'Não foi possível carregar a lista: $error',
              textAlign: TextAlign.center,
            ),
            data: (items) => items.isEmpty
                ? Text(
                    'Nenhuma pessoa disponível na lista.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  )
                : Column(
                    children: [
                      for (final target in items)
                        Padding(
                          padding: EdgeInsets.only(bottom: sizes.sm),
                          child: _TargetTile(
                            target: target,
                            selected: _selectedTarget?.id == target.id,
                            onSelect: () => _confirm(target),
                          ),
                        ),
                    ],
                  ),
          ),
          SizedBox(height: sizes.lg),
          Text(
            'Outro (escreva o que você conseguir):',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          SizedBox(height: sizes.md),
          ReportPillField(
            label: _isInstitution ? 'Nome:' : 'Nome completo:',
            hintText: _nameHint,
            controller: _nameController,
            keyboardType: TextInputType.name,
          ),
          SizedBox(height: sizes.md),
          ReportPillField(
            label: 'Telefone:',
            hintText: '(xx) xxxxx-xxxx',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
          ),
          if (!_isInstitution) ...[
            SizedBox(height: sizes.md),
            ReportPillField(
              label: 'Instituto:',
              hintText: 'Nome do instituto',
              controller: _instituteController,
            ),
          ],
        ],
      ),
      bottomButton: ButtonWidget(
        label: 'Continuar',
        onPressed:
            _selectedTarget == null && _nameController.text.trim().isEmpty
            ? null
            : () => _confirm(
                _selectedTarget ??
                    ReportTarget(
                      id: '',
                      name: _nameController.text.trim(),
                      phone: _phoneController.text.trim(),
                      institute: _instituteController.text.trim(),
                    ),
              ),
      ),
    );
  }

  Future<void> _confirm(ReportTarget target) async {
    final confirmed = await showAppModal<bool>(
      context: context,
      size: AppModalSize.medium,
      showCloseButton: false,
      child: _ConfirmContent(
        target: target,
        title: _isInstitution
            ? 'Tem certeza que deseja\ndenunciar esta instituição?'
            : 'Tem certeza que deseja\ndenunciar esta pessoa?',
        isInstitution: _isInstitution,
      ),
    );

    if (confirmed != true || !mounted) return;

    final session = await ref.read(currentUserProvider.future);
    if (session == null || !mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await submitReport(draft: _draft, target: target, session: session);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ref
          .read(reportDraftProvider.notifier)
          .update(
            _draft.copyWith(
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

class _TargetTile extends StatelessWidget {
  const _TargetTile({
    required this.target,
    required this.selected,
    required this.onSelect,
  });

  final ReportTarget target;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    return Material(
      color: colorScheme.surface,
      elevation: sizes.xs / 2,
      shadowColor: colorScheme.shadow.withValues(alpha: .24),
      borderRadius: BorderRadius.circular(sizes.radiusFull),
      child: Padding(
        padding: EdgeInsets.fromLTRB(sizes.sm, sizes.sm, sizes.md, sizes.sm),
        child: Row(
          children: [
            _Avatar(photoUrl: target.photoUrl, radius: sizes.lg),
            SizedBox(width: sizes.sm),
            Expanded(
              child: Text(
                target.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            TextButton(
              onPressed: onSelect,
              child: Text(
                selected ? 'Selecionado' : 'Selecionar',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.photoUrl,
    required this.radius,
    this.fallbackIcon = Icons.person_rounded,
  });

  final String? photoUrl;
  final double radius;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final image = profileImageProvider(photoUrl);

    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      backgroundImage: image,
      child: image == null ? Icon(fallbackIcon) : null,
    );
  }
}

class _ConfirmContent extends StatelessWidget {
  const _ConfirmContent({
    required this.target,
    required this.title,
    required this.isInstitution,
  });

  final ReportTarget target;
  final String title;
  final bool isInstitution;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            tooltip: 'Fechar',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () => Navigator.of(context).pop(false),
            icon: Icon(Icons.close_rounded, size: sizes.icon(sizes.xl)),
          ),
        ),
        SizedBox(height: sizes.xs),
        Center(
          child: FractionallySizedBox(
            widthFactor: .9,
            child: Text(
              title,
              textAlign: TextAlign.left,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SizedBox(height: sizes.lg),
        Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surfaceContainerLow,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: .14),
                  blurRadius: sizes.sm,
                  offset: Offset(0, sizes.xs / 2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(sizes.xs),
              child: _Avatar(
                photoUrl: target.photoUrl,
                radius: sizes.xxl - sizes.xs,
                fallbackIcon: isInstitution
                    ? Icons.apartment_rounded
                    : Icons.person_rounded,
              ),
            ),
          ),
        ),
        SizedBox(height: sizes.md),
        Text(
          target.name,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: sizes.xxl * 1.5),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: sizes.sm),
          child: ButtonWidget(
            label: 'Confirmar',
            size: ButtonSize.small,
            variant: ButtonVariant.secondary,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ),
        SizedBox(height: sizes.sm),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: sizes.sm),
          child: ButtonWidget(
            label: 'Cancelar',
            size: ButtonSize.small,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ),
      ],
    );
  }
}
