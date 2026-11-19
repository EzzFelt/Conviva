import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:conviva/shared/utils/profile_image.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/formatters/brazilian_phone_formatter.dart';
import '../../../shared/widgets/add_new_button_widget.dart';
import '../../../shared/widgets/app_modal_widget.dart';
import '../../../shared/widgets/content_panel_widget.dart';
import '../../../shared/widgets/edit_button_widget.dart';
import '../../../shared/widgets/info_card_widget.dart';
import '../../../shared/widgets/page_header_widget.dart';
import '../../auth/models/account_type.dart';
import '../../auth/models/user_session.dart';
import '../../auth/providers/authenticated_user_navigator.dart';
import '../../auth/providers/current_user_provider.dart';
import '../../home/widgets/next_task_card.dart';
import '../models/routine_elder_summary.dart';
import '../models/routine_permissions.dart';
import '../models/routine_task.dart';
import '../models/routine_task_completion.dart';
import '../providers/routine_provider.dart';
import '../widgets/routine_calendar_widget.dart';
import '../widgets/routine_task_form_modal.dart';
import '../widgets/routine_view_toggle_widget.dart';

class RoutinePage extends ConsumerWidget {
  const RoutinePage({super.key, this.elderId});

  final String? elderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: sessionState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _RoutineMessageState(
          icon: Icons.error_outline_rounded,
          message: _errorMessage(error),
        ),
        data: (session) {
          if (session == null) {
            return const _RoutineMessageState(
              icon: Icons.person_off_rounded,
              message: 'Usuário não autenticado.',
            );
          }

          if (session.accountType == AccountType.elder) {
            if (elderId != null && elderId != session.uid) {
              return const _RoutineMessageState(
                icon: Icons.lock_rounded,
                message: 'Você não possui acesso a esta rotina.',
              );
            }

            return _RoutineDetailPage(actor: session, elderId: session.uid);
          }

          if (elderId == null) {
            return _RoutineElderSelectionPage(actor: session);
          }

          return _RoutineDetailPage(actor: session, elderId: elderId!);
        },
      ),
    );
  }
}

class _RoutineElderSelectionPage extends ConsumerWidget {
  const _RoutineElderSelectionPage({required this.actor});

  final UserSession actor;

  Future<void> _goHome(BuildContext context) async {
    await AuthenticatedUserNavigator.open(context, actor);
  }

  Widget _elderCard(BuildContext context, RoutineElderSummary elder) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final photoUrl = elder.photoUrl?.trim();

    final details = <String>[
      if (elder.phone.isNotEmpty)
        'Tel: ${BrazilianPhoneFormatter.format(elder.phone)}',
      if (elder.gender != null) 'Sexo: ${elder.gender}',
      if (elder.bloodType != null) 'Tipo sanguíneo: ${elder.bloodType}',
      if (elder.dependencyLevel != null)
        'Grau de dependência: ${elder.dependencyLevel}',
    ];

    return Material(
      color: colorScheme.surface,
      elevation: sizes.sm,
      shadowColor: colorScheme.shadow.withValues(alpha: .24),
      borderRadius: BorderRadius.circular(sizes.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(RouteNames.routinePath(elder.id)),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: sizes.md,
            vertical: sizes.sm + sizes.xs,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: sizes.xl,
                backgroundColor: colorScheme.primary.withValues(alpha: .12),
                foregroundImage: photoUrl == null || photoUrl.isEmpty
                    ? null
                    : profileImageProvider(photoUrl),
                child: photoUrl == null || photoUrl.isEmpty
                    ? Icon(Icons.elderly_rounded, color: colorScheme.primary)
                    : null,
              ),
              SizedBox(width: sizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      elder.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    for (final detail in details)
                      Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: sizes.sm),
              Text(
                'Ver rotina',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _elderList(
    BuildContext context,
    AsyncValue<List<RoutineElderSummary>> eldersState,
  ) {
    final theme = Theme.of(context);
    final sizes = context.appSizes;

    return eldersState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _RoutineInlineMessage(
        icon: Icons.error_outline_rounded,
        message: _errorMessage(error),
      ),
      data: (elders) {
        if (elders.isEmpty) {
          return const _RoutineInlineMessage(
            icon: Icons.elderly_rounded,
            message: 'Nenhum idoso disponível para este perfil.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              actor.accountType == AccountType.caregiver
                  ? 'Seus residentes'
                  : 'Idosos vinculados',
              style: theme.textTheme.titleLarge,
            ),
            SizedBox(height: sizes.lg),
            for (var index = 0; index < elders.length; index++) ...[
              _elderCard(context, elders[index]),
              if (index < elders.length - 1) SizedBox(height: sizes.md),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eldersState = ref.watch(accessibleRoutineEldersProvider);

    final sizes = context.appSizes;

    return DecoratedBox(
      decoration: _gradientDecoration(context),
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: PageHeaderWidget(
                title: actor.accountType == AccountType.caregiver
                    ? 'Residentes'
                    : 'Rotinas',
                onBackPressed: () => _goHome(context),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: true,
              child: SizedBox.expand(
                child: ContentPanelWidget(
                  fillAvailableHeight: true,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(sizes.radiusLg),
                    topRight: Radius.circular(sizes.radiusLg),
                  ),
                  padding: EdgeInsets.fromLTRB(sizes.lg, sizes.lg, sizes.lg, 0),
                  child: SingleChildScrollView(
                    child: _elderList(context, eldersState),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutineDetailPage extends ConsumerStatefulWidget {
  const _RoutineDetailPage({required this.actor, required this.elderId});

  final UserSession actor;
  final String elderId;

  @override
  ConsumerState<_RoutineDetailPage> createState() => _RoutineDetailPageState();
}

class _RoutineDetailPageState extends ConsumerState<_RoutineDetailPage> {
  late DateTime _selectedDay;

  RoutineViewMode _viewMode = RoutineViewMode.day;

  bool _savingPermissions = false;
  bool _showHistory = false;

  final Set<String> _completingOccurrenceIds = {};

  // Cache dos eventos por mês.
  // É invalidado quando a lista de tarefas ou o histórico muda.
  List<RoutineTask>? _cachedTaskSource;
  List<RoutineTaskCompletion>? _cachedCompletionSource;

  final Map<int, Map<DateTime, List<RoutineTask>>> _monthEventsCache = {};

  static const _weekdayNames = [
    'segunda-feira',
    'terça-feira',
    'quarta-feira',
    'quinta-feira',
    'sexta-feira',
    'sábado',
    'domingo',
  ];

  @override
  void initState() {
    super.initState();

    _selectedDay = RoutineTask.dateOnly(DateTime.now());
  }

  RoutineTaskCreatorRole _creatorRole() {
    return switch (widget.actor.accountType) {
      AccountType.elder => RoutineTaskCreatorRole.elder,
      AccountType.caregiver => RoutineTaskCreatorRole.caregiver,
      AccountType.family => RoutineTaskCreatorRole.family,
      AccountType.support => throw StateError(
        'A equipe de suporte não pode editar rotinas.',
      ),
    };
  }

  Future<void> _goBack() async {
    if (widget.actor.accountType == AccountType.elder) {
      await AuthenticatedUserNavigator.open(context, widget.actor);
      return;
    }

    if (mounted) {
      context.go(RouteNames.routine);
    }
  }

  void _changeView(RoutineViewMode mode) {
    setState(() {
      _viewMode = mode;
      _showHistory = false;

      if (mode == RoutineViewMode.day) {
        _selectedDay = RoutineTask.dateOnly(DateTime.now());
      }
    });
  }

  void _selectDay(DateTime day) {
    setState(() {
      _selectedDay = RoutineTask.dateOnly(day);
      _viewMode = RoutineViewMode.day;
      _showHistory = false;
    });
  }

  void _toggleHistory() {
    setState(() {
      _showHistory = !_showHistory;
    });
  }

  String _completionIdFor(RoutineTask task, DateTime day) {
    return RoutineTaskCompletion.documentIdFor(
      taskId: task.id,
      occurrenceDate: day,
      taskWasRecurring: task.repeatWeekly,
    );
  }

  Future<void> _completeTask(
    RoutineTask task,
    RoutinePermissions permissions,
  ) async {
    // Verifica novamente a permissão antes de concluir.
    // A conclusão segue a mesma regra da edição.
    final canComplete = canEditRoutineTask(
      actor: widget.actor,
      task: task,
      permissions: permissions,
    );

    if (!canComplete) {
      _showError(
        StateError('Você não tem permissão para concluir esta tarefa.'),
      );
      return;
    }

    final occurrenceDay = RoutineTask.dateOnly(_selectedDay);

    final completionId = _completionIdFor(task, occurrenceDay);

    if (_completingOccurrenceIds.contains(completionId)) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Concluir tarefa?'),
          content: Text(
            task.repeatWeekly
                ? 'Apenas a ocorrência deste dia será marcada como concluída. '
                      'A tarefa continuará na rotina.'
                : 'Esta tarefa será retirada da rotina ativa e ficará '
                      'disponível no histórico.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Concluir'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    if (_completingOccurrenceIds.contains(completionId)) {
      return;
    }

    setState(() {
      _completingOccurrenceIds.add(completionId);
    });

    try {
      await ref
          .read(routineRepositoryProvider)
          .completeTask(
            actor: widget.actor,
            task: task,
            occurrenceDate: occurrenceDay,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            task.repeatWeekly
                ? 'Ocorrência concluída e salva no histórico.'
                : 'Tarefa concluída e movida para o histórico.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        _showError(error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _completingOccurrenceIds.remove(completionId);
        });
      }
    }
  }

  Widget _completionAction(
    BuildContext context,
    RoutineTask task,
    RoutinePermissions permissions, {
    bool compact = false,
  }) {
    // Não exibe a ação se o usuário não puder editar a tarefa.
    final canComplete = canEditRoutineTask(
      actor: widget.actor,
      task: task,
      permissions: permissions,
    );

    if (!canComplete) {
      return const SizedBox.shrink();
    }

    final completionId = _completionIdFor(task, _selectedDay);

    final isCompleting = _completingOccurrenceIds.contains(completionId);

    final label = task.repeatWeekly ? 'Concluir ocorrência' : 'Concluir tarefa';

    if (compact) {
      return IconButton(
        tooltip: label,
        onPressed: isCompleting ? null : () => _completeTask(task, permissions),
        icon: isCompleting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check_circle_outline_rounded),
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: isCompleting ? null : () => _completeTask(task, permissions),
        icon: isCompleting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check_circle_outline_rounded),
        label: Text(isCompleting ? 'Concluindo...' : label),
      ),
    );
  }

  Future<void> _openTaskForm({RoutineTask? task}) async {
    final result = await showAppModal<RoutineTaskFormResult>(
      context: context,
      size: AppModalSize.large,
      child: RoutineTaskFormModal(
        selectedDate: _selectedDay,
        elderId: widget.elderId,
        createdByUserId: widget.actor.uid,
        createdByRole: _creatorRole(),
        task: task,
      ),
    );

    if (result == null || !mounted) return;

    final repository = ref.read(routineRepositoryProvider);

    try {
      switch (result.action) {
        case RoutineTaskFormAction.save:
          if (task == null) {
            await repository.createTask(actor: widget.actor, task: result.task);
          } else {
            await repository.updateTask(actor: widget.actor, task: result.task);
          }
          break;

        case RoutineTaskFormAction.delete:
          await repository.deleteTask(task: result.task);
          break;
      }
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    }
  }

  Future<void> _setElderPermission(bool value) async {
    if (_savingPermissions) return;

    setState(() {
      _savingPermissions = true;
    });

    try {
      await ref
          .read(routineRepositoryProvider)
          .setElderPermissions(
            actor: widget.actor,
            elderId: widget.elderId,
            canManageOwnRoutine: value,
          );
    } catch (error) {
      if (mounted) {
        _showError(error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _savingPermissions = false;
        });
      }
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
  }

  bool _isToday(DateTime day) {
    return RoutineTask.dateOnly(day) == RoutineTask.dateOnly(DateTime.now());
  }

  String _selectedDateLabel() {
    final weekday = _weekdayNames[_selectedDay.weekday - 1];

    final day = _selectedDay.day.toString().padLeft(2, '0');
    final month = _selectedDay.month.toString().padLeft(2, '0');

    return '${weekday[0].toUpperCase()}'
        '${weekday.substring(1)}\n$day/$month';
  }

  List<RoutineTask> _visibleTasks(
    RoutineState routineState,
    List<RoutineTaskCompletion> completions,
  ) {
    final completedIds = <String>{
      for (final completion in completions) completion.id,
    };

    return routineState
        .tasksForDay(elderId: widget.elderId, day: _selectedDay)
        .where((task) {
          final completionId = _completionIdFor(task, _selectedDay);

          return !completedIds.contains(completionId);
        })
        .toList(growable: false);
  }

  IconData _taskIcon(RoutineTaskType type) {
    return switch (type) {
      RoutineTaskType.breakfast => Icons.breakfast_dining_rounded,
      RoutineTaskType.medication => Icons.medication_rounded,
      RoutineTaskType.meal => Icons.restaurant_rounded,
      RoutineTaskType.exercise => Icons.directions_walk_rounded,
      RoutineTaskType.leisure => Icons.auto_stories_rounded,
      RoutineTaskType.appointment => Icons.medical_services_rounded,
      RoutineTaskType.hygiene => Icons.shower_rounded,
      RoutineTaskType.sleep => Icons.bed_rounded,
      RoutineTaskType.other => Icons.event_available_rounded,
    };
  }

  Widget _taskCard(
    BuildContext context,
    RoutineTask task,
    RoutinePermissions permissions,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final sizes = context.appSizes;

    final canEdit = canEditRoutineTask(
      actor: widget.actor,
      task: task,
      permissions: permissions,
    );

    final onEdit = canEdit ? () => _openTaskForm(task: task) : null;

    return InfoCardWidget(
      size: InfoCardSize.small,
      borderRadius: BorderRadius.circular(sizes.radiusMd),
      leading: Icon(
        _taskIcon(task.type),
        color: colorScheme.primary,
        size: sizes.icon(sizes.lg),
      ),
      title: task.title,
      subtitle: task.timeLabel,
      onPressed: onEdit,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canEdit)
            _completionAction(context, task, permissions, compact: true),
          if (canEdit) EditButtonWidget(onPressed: onEdit),
        ],
      ),
    );
  }

  Widget _historyContent(
    BuildContext context,
    AsyncValue<List<RoutineTaskCompletion>> completionsState,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    return completionsState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _RoutineInlineMessage(
        icon: Icons.error_outline_rounded,
        message: _errorMessage(error),
      ),
      data: (completions) {
        if (completions.isEmpty) {
          return const _RoutineInlineMessage(
            icon: Icons.history_rounded,
            message: 'Nenhuma tarefa concluída até o momento.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tarefas concluídas', style: theme.textTheme.titleMedium),
            SizedBox(height: sizes.md),
            for (var index = 0; index < completions.length; index++) ...[
              InfoCardWidget(
                size: InfoCardSize.small,
                borderRadius: BorderRadius.circular(sizes.radiusMd),
                leading: Icon(
                  _taskIcon(completions[index].taskType),
                  color: colorScheme.primary,
                  size: sizes.icon(sizes.lg),
                ),
                title: completions[index].taskTitle,
                subtitle:
                    '${completions[index].occurrenceDateLabel} • '
                    '${completions[index].timeLabel}\n'
                    'Concluída às '
                    '${completions[index].completedTimeLabel}',
                trailing: Icon(
                  Icons.check_circle_rounded,
                  color: colorScheme.primary,
                ),
              ),
              if (index < completions.length - 1) SizedBox(height: sizes.md),
            ],
          ],
        );
      },
    );
  }

  Widget _permissionControl(
    BuildContext context,
    AsyncValue<RoutinePermissions> permissionsState,
  ) {
    if (widget.actor.accountType != AccountType.caregiver) {
      return const SizedBox.shrink();
    }

    final sizes = context.appSizes;

    return permissionsState.when(
      loading: () => Padding(
        padding: EdgeInsets.only(top: sizes.md),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: EdgeInsets.only(top: sizes.md),
        child: _RoutineInlineMessage(
          icon: Icons.error_outline_rounded,
          message: _errorMessage(error),
        ),
      ),
      data: (permissions) => Padding(
        padding: EdgeInsets.only(top: sizes.md),
        child: InfoCardWidget(
          size: InfoCardSize.small,
          borderRadius: BorderRadius.circular(sizes.radiusMd),
          title: 'Permitir alterações pelo idoso',
          subtitle: 'Criar, editar e excluir as próprias tarefas',
          trailing: Switch(
            value: permissions.canElderManageOwnRoutine,
            onChanged: _savingPermissions ? null : _setElderPermission,
          ),
        ),
      ),
    );
  }

  Widget _viewControls(
    BuildContext context,
    AsyncValue<RoutinePermissions> permissionsState,
    AsyncValue<RoutineElderSummary?> elderState,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final sizes = context.appSizes;
    final elder = elderState.asData?.value;

    return Column(
      children: [
        if (widget.actor.accountType != AccountType.elder && elder != null) ...[
          Text(
            'Rotina de ${elder.name}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: sizes.md),
        ],
        if (!_showHistory)
          RoutineViewToggleWidget(value: _viewMode, onChanged: _changeView),
        SizedBox(height: sizes.sm),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _toggleHistory,
            icon: Icon(
              _showHistory ? Icons.event_note_rounded : Icons.history_rounded,
            ),
            label: Text(_showHistory ? 'Voltar à rotina' : 'Ver histórico'),
          ),
        ),
        if (!_showHistory && _viewMode == RoutineViewMode.day) ...[
          SizedBox(height: sizes.sm),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: sizes.md,
              vertical: sizes.sm,
            ),
            decoration: BoxDecoration(
              color: context.appGradientColors.bottom,
              borderRadius: BorderRadius.circular(sizes.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: .20),
                  blurRadius: sizes.xs,
                  offset: Offset(0, sizes.xs / 2),
                ),
              ],
            ),
            child: Text(
              _selectedDateLabel(),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary),
            ),
          ),
        ],
        _permissionControl(context, permissionsState),
      ],
    );
  }

  Widget _dayContent(
    BuildContext context,
    RoutineState routineState,
    RoutinePermissions permissions,
    List<RoutineTaskCompletion> completions,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    final tasks = _visibleTasks(routineState, completions);

    RoutineTask? nextTask;

    if (_isToday(_selectedDay)) {
      final now = DateTime.now();

      for (final task in tasks) {
        if (task.endOn(_selectedDay).isAfter(now)) {
          nextTask = task;
          break;
        }
      }
    } else if (tasks.isNotEmpty) {
      nextTask = tasks.first;
    }

    final remainingTasks = tasks
        .where((task) => task.id != nextTask?.id)
        .toList();

    final canCreate = canCreateRoutineTask(
      actor: widget.actor,
      elderId: widget.elderId,
      permissions: permissions,
    );

    // A próxima tarefa também respeita a permissão de edição.
    final canCompleteNextTask =
        nextTask != null &&
        canEditRoutineTask(
          actor: widget.actor,
          task: nextTask,
          permissions: permissions,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NextTaskCard(
          task: nextTask,
          sectionTitle: _isToday(_selectedDay)
              ? 'Sua próxima tarefa:'
              : 'Primeira tarefa:',
          emptyMessage: _isToday(_selectedDay)
              ? 'Nenhuma tarefa restante hoje'
              : 'Nenhuma tarefa neste dia',
          onPressed:
              nextTask != null &&
                  canEditRoutineTask(
                    actor: widget.actor,
                    task: nextTask,
                    permissions: permissions,
                  )
              ? () => _openTaskForm(task: nextTask)
              : null,
        ),
        if (canCompleteNextTask)
          _completionAction(context, nextTask, permissions),
        if (remainingTasks.isNotEmpty) ...[
          SizedBox(height: sizes.xl),
          Text(
            nextTask == null ? 'Tarefas do dia:' : 'Próximo:',
            style: theme.textTheme.titleMedium,
          ),
          SizedBox(height: sizes.md),
          for (var index = 0; index < remainingTasks.length; index++) ...[
            _taskCard(context, remainingTasks[index], permissions),
            if (index < remainingTasks.length - 1) SizedBox(height: sizes.md),
          ],
        ],
        SizedBox(height: sizes.xl),
        if (canCreate)
          AddNewButtonWidget(
            label: 'Adicionar tarefa',
            onPressed: () => _openTaskForm(),
          )
        else
          Container(
            padding: EdgeInsets.all(sizes.md),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(sizes.radiusMd),
            ),
            child: Text(
              'Seu cuidador desativou as alterações na rotina.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ),
      ],
    );
  }

  Map<DateTime, List<RoutineTask>> _eventsForMonth(
    DateTime month,
    List<RoutineTask> tasks,
    List<RoutineTaskCompletion> completions,
  ) {
    if (!identical(_cachedTaskSource, tasks) ||
        !identical(_cachedCompletionSource, completions)) {
      _cachedTaskSource = tasks;
      _cachedCompletionSource = completions;
      _monthEventsCache.clear();
    }

    final cacheKey = month.year * 100 + month.month;

    return _monthEventsCache.putIfAbsent(cacheKey, () {
      final firstDay = DateTime(month.year, month.month);

      final nextMonth = DateTime(month.year, month.month + 1);

      final completedIds = <String>{
        for (final completion in completions) completion.id,
      };

      final grouped = <DateTime, List<RoutineTask>>{};

      void addTaskForDay(RoutineTask task, DateTime day) {
        final key = RoutineTask.dateOnly(day);

        final completionId = _completionIdFor(task, key);

        if (completedIds.contains(completionId)) {
          return;
        }

        grouped.putIfAbsent(key, () => <RoutineTask>[]).add(task);
      }

      for (final task in tasks) {
        final taskStartDay = RoutineTask.dateOnly(task.startAt);

        if (!task.repeatWeekly) {
          if (!taskStartDay.isBefore(firstDay) &&
              taskStartDay.isBefore(nextMonth)) {
            addTaskForDay(task, taskStartDay);
          }

          continue;
        }

        final firstPossibleDay = taskStartDay.isBefore(firstDay)
            ? firstDay
            : taskStartDay;

        for (final weekday in task.repeatWeekdays) {
          final daysUntilWeekday = (weekday - firstPossibleDay.weekday + 7) % 7;

          var occurrence = firstPossibleDay.add(
            Duration(days: daysUntilWeekday),
          );

          while (occurrence.isBefore(nextMonth)) {
            addTaskForDay(task, occurrence);

            occurrence = occurrence.add(const Duration(days: 7));
          }
        }
      }

      final sorted = <DateTime, List<RoutineTask>>{};

      for (final entry in grouped.entries) {
        final day = entry.key;

        entry.value.sort(
          (first, second) => first.startOn(day).compareTo(second.startOn(day)),
        );

        sorted[day] = List<RoutineTask>.unmodifiable(entry.value);
      }

      return Map<DateTime, List<RoutineTask>>.unmodifiable(sorted);
    });
  }

  Widget _allDaysContent(
    BuildContext context,
    RoutineState routineState,
    List<RoutineTaskCompletion> completions,
  ) {
    final sizes = context.appSizes;
    final theme = Theme.of(context);
    final now = DateTime.now();
    final firstMonth = DateTime(now.year, now.month);

    final months = List<DateTime>.generate(
      12,
      (index) => DateTime(firstMonth.year, firstMonth.month + index),
      growable: false,
    );

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final month = months[index];

        final monthEvents = _eventsForMonth(
          month,
          routineState.tasks,
          completions,
        );

        final isFirst = index == 0;
        final isLast = index == months.length - 1;

        return Container(
          key: ValueKey('routine-month-${month.year}-${month.month}'),
          width: double.infinity,
          color: theme.scaffoldBackgroundColor,
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: isFirst ? Radius.circular(sizes.radiusLg) : Radius.zero,
              topRight: isFirst ? Radius.circular(sizes.radiusLg) : Radius.zero,
              bottomLeft: isLast
                  ? Radius.circular(sizes.radiusLg)
                  : Radius.zero,
              bottomRight: isLast
                  ? Radius.circular(sizes.radiusLg)
                  : Radius.zero,
            ),
            child: Container(
              width: double.infinity,
              color: theme.colorScheme.surface,
              padding: EdgeInsets.fromLTRB(
                sizes.md,
                isFirst ? sizes.lg : 0,
                sizes.md,
                sizes.xl,
              ),
              child: RoutineCalendarWidget(
                month: month,
                selectedDay: _selectedDay,
                eventLoader: (day) =>
                    monthEvents[RoutineTask.dateOnly(day)] ??
                    const <RoutineTask>[],
                onDaySelected: _selectDay,
              ),
            ),
          ),
        );
      }, childCount: months.length),
    );
  }

  List<Widget> _allDaysSlivers(
    BuildContext context,
    AsyncValue<List<RoutineTask>> tasksState,
    AsyncValue<List<RoutineTaskCompletion>> completionsState,
  ) {
    return tasksState.when<List<Widget>>(
      loading: () => const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
      error: (error, _) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(context.appSizes.lg),
            child: _RoutineInlineMessage(
              icon: Icons.error_outline_rounded,
              message: _errorMessage(error),
            ),
          ),
        ),
      ],
      data: (tasks) {
        return completionsState.when<List<Widget>>(
          loading: () => const [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
          error: (error, _) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(context.appSizes.lg),
                child: _RoutineInlineMessage(
                  icon: Icons.error_outline_rounded,
                  message: _errorMessage(error),
                ),
              ),
            ),
          ],
          data: (completions) => [
            _allDaysContent(context, RoutineState(tasks: tasks), completions),
          ],
        );
      },
    );
  }

  Widget _routineContent(
    BuildContext context,
    AsyncValue<List<RoutineTask>> tasksState,
    AsyncValue<RoutinePermissions> permissionsState,
    AsyncValue<List<RoutineTaskCompletion>> completionsState,
  ) {
    if (_showHistory) {
      return _historyContent(context, completionsState);
    }

    return tasksState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _RoutineInlineMessage(
        icon: Icons.error_outline_rounded,
        message: _errorMessage(error),
      ),
      data: (tasks) {
        return permissionsState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _RoutineInlineMessage(
            icon: Icons.error_outline_rounded,
            message: _errorMessage(error),
          ),
          data: (permissions) {
            return completionsState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _RoutineInlineMessage(
                icon: Icons.error_outline_rounded,
                message: _errorMessage(error),
              ),
              data: (completions) {
                final routineState = RoutineState(tasks: tasks);

                return _dayContent(
                  context,
                  routineState,
                  permissions,
                  completions,
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(routineTasksProvider(widget.elderId));

    final permissionsState = ref.watch(
      routinePermissionsProvider(widget.elderId),
    );

    final elderState = ref.watch(routineElderProvider(widget.elderId));

    final completionsState = ref.watch(
      routineCompletionsProvider(widget.elderId),
    );

    final sizes = context.appSizes;

    final theme = Theme.of(context);
    final isAllDaysView = _viewMode == RoutineViewMode.allDays && !_showHistory;
    final slivers = <Widget>[
      SliverToBoxAdapter(
        child: PageHeaderWidget(title: 'Rotina', onBackPressed: _goBack),
      ),
      SliverToBoxAdapter(
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(sizes.md),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(sizes.radiusLg),
              topRight: Radius.circular(sizes.radiusLg),
            ),
          ),
          child: _viewControls(context, permissionsState, elderState),
        ),
      ),
      if (isAllDaysView) ...[
        ..._allDaysSlivers(context, tasksState, completionsState),
        SliverToBoxAdapter(child: SizedBox(height: sizes.xxl * 3)),
      ] else ...[
        SliverToBoxAdapter(
          child: ColoredBox(
            key: const ValueKey('routine-content-background'),
            color: theme.scaffoldBackgroundColor,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                sizes.md,
                sizes.lg,
                sizes.md,
                sizes.xl + sizes.xxl * 3,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(sizes.radiusLg),
                  topRight: Radius.circular(sizes.radiusLg),
                ),
              ),
              child: _routineContent(
                context,
                tasksState,
                permissionsState,
                completionsState,
              ),
            ),
          ),
        ),
      ],
      SliverFillRemaining(
        hasScrollBody: false,
        child: ColoredBox(color: theme.colorScheme.surface),
      ),
    ];
    return DecoratedBox(
      decoration: _gradientDecoration(context),
      child: SafeArea(bottom: false, child: CustomScrollView(slivers: slivers)),
    );
  }
}

class _RoutineMessageState extends StatelessWidget {
  const _RoutineMessageState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _gradientDecoration(context),
      child: SafeArea(
        child: Center(
          child: _RoutineInlineMessage(icon: icon, message: message),
        ),
      ),
    );
  }
}

class _RoutineInlineMessage extends StatelessWidget {
  const _RoutineInlineMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    return Padding(
      padding: EdgeInsets.all(sizes.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: sizes.icon(sizes.xxl), color: colorScheme.primary),
          SizedBox(height: sizes.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

BoxDecoration _gradientDecoration(BuildContext context) {
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [context.appGradientColors.bottom, context.appGradientColors.top],
    ),
  );
}

String _errorMessage(Object error) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'Você não tem permissão para realizar esta ação.';

      case 'unauthenticated':
        return 'Sua sessão expirou. Entre novamente.';

      case 'unavailable':
      case 'network-request-failed':
      case 'deadline-exceeded':
        return 'Não foi possível conectar ao serviço. '
            'Verifique sua conexão e tente novamente.';

      case 'not-found':
        return 'A rotina ou tarefa não foi encontrada.';

      case 'resource-exhausted':
        return 'O serviço está temporariamente indisponível. '
            'Tente novamente mais tarde.';

      default:
        return 'Não foi possível carregar ou atualizar a rotina. '
            'Tente novamente.';
    }
  }

  final rawMessage = error
      .toString()
      .replaceFirst('Bad state: ', '')
      .replaceFirst('Exception: ', '')
      .trim();

  const knownMessages = <String>{
    'Tarefa não identificada.',
    'Idoso não identificado.',
    'Informe o nome da tarefa.',
    'O término deve ser posterior ao começo.',
    'Escolha pelo menos um dia para repetir a tarefa.',
    'Somente o cuidador pode alterar as permissões da rotina.',
    'Esta tarefa não está programada para esta data.',
    'A tarefa não foi encontrada.',
    'Você não tem permissão para concluir esta tarefa.',
  };

  if (knownMessages.contains(rawMessage)) {
    return rawMessage;
  }

  return 'Não foi possível concluir a operação da rotina. '
      'Tente novamente.';
}
