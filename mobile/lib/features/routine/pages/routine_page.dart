import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';
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
import '../providers/routine_provider.dart';
import '../widgets/routine_calendar_widget.dart';
import '../widgets/routine_task_form_modal.dart';
import '../widgets/routine_view_toggle_widget.dart';

class RoutinePage extends ConsumerWidget {
  const RoutinePage({
    super.key,
    this.elderId,
  });

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

            return _RoutineDetailPage(
              actor: session,
              elderId: session.uid,
            );
          }

          if (elderId == null) {
            return _RoutineElderSelectionPage(actor: session);
          }

          return _RoutineDetailPage(
            actor: session,
            elderId: elderId!,
          );
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

  Widget _avatar(BuildContext context, RoutineElderSummary elder) {
    final colorScheme = Theme.of(context).colorScheme;
    final photoUrl = elder.photoUrl;

    return CircleAvatar(
      backgroundColor: colorScheme.primary.withValues(alpha: .12),
      foregroundImage: photoUrl == null ? null : NetworkImage(photoUrl),
      child: photoUrl == null
          ? Icon(Icons.elderly_rounded, color: colorScheme.primary)
          : null,
    );
  }

  Widget _elderCard(BuildContext context, RoutineElderSummary elder) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final details = <String>[
      if (elder.phone.isNotEmpty)
        'Tel: ${BrazilianPhoneFormatter.format(elder.phone)}',
      if (elder.gender != null) 'Sexo: ${elder.gender}',
      if (elder.bloodType != null) 'Tipo sanguíneo: ${elder.bloodType}',
      if (elder.dependencyLevel != null)
        'Grau de dependência: ${elder.dependencyLevel}',
    ];

    return InfoCardWidget(
      size: InfoCardSize.large,
      borderRadius: BorderRadius.circular(sizes.radiusMd),
      leading: _avatar(context, elder),
      onPressed: () => context.go(RouteNames.routinePath(elder.id)),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(elder.name, style: theme.textTheme.titleMedium),
          if (details.isNotEmpty) ...[
            SizedBox(height: sizes.xs),
            for (final detail in details)
              Text(
                detail,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
          SizedBox(height: sizes.xs),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Ver rotina',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                decoration: TextDecoration.underline,
                decorationColor: colorScheme.primary,
              ),
            ),
          ),
        ],
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
              if (index < elders.length - 1) SizedBox(height: sizes.lg),
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(bottom: sizes.xxl * 3),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PageHeaderWidget(
                      title: actor.accountType == AccountType.caregiver
                          ? 'Residentes'
                          : 'Rotinas',
                      onBackPressed: () => _goHome(context),
                    ),
                    ContentPanelWidget(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(sizes.radiusLg),
                        topRight: Radius.circular(sizes.radiusLg),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        sizes.lg,
                        sizes.lg,
                        sizes.lg,
                        sizes.xxl * 2,
                      ),
                      child: _elderList(context, eldersState),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RoutineDetailPage extends ConsumerStatefulWidget {
  const _RoutineDetailPage({
    required this.actor,
    required this.elderId,
  });

  final UserSession actor;
  final String elderId;

  @override
  ConsumerState<_RoutineDetailPage> createState() =>
      _RoutineDetailPageState();
}

class _RoutineDetailPageState extends ConsumerState<_RoutineDetailPage> {
  late DateTime _selectedDay;
  RoutineViewMode _viewMode = RoutineViewMode.day;
  bool _savingPermissions = false;

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
    };
  }

  Future<void> _goBack() async {
    if (widget.actor.accountType == AccountType.elder) {
      await AuthenticatedUserNavigator.open(context, widget.actor);
      return;
    }
    if (mounted) context.go(RouteNames.routine);
  }

  void _changeView(RoutineViewMode mode) {
    setState(() {
      _viewMode = mode;
      if (mode == RoutineViewMode.day) {
        _selectedDay = RoutineTask.dateOnly(DateTime.now());
      }
    });
  }

  void _selectDay(DateTime day) {
    setState(() {
      _selectedDay = RoutineTask.dateOnly(day);
      _viewMode = RoutineViewMode.day;
    });
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
            await repository.createTask(
              actor: widget.actor,
              task: result.task,
            );
          } else {
            await repository.updateTask(
              actor: widget.actor,
              task: result.task,
            );
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
    setState(() => _savingPermissions = true);

    try {
      await ref.read(routineRepositoryProvider).setElderPermissions(
            actor: widget.actor,
            elderId: widget.elderId,
            canManageOwnRoutine: value,
          );
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _savingPermissions = false);
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_errorMessage(error))),
    );
  }

  bool _isToday(DateTime day) {
    return RoutineTask.dateOnly(day) == RoutineTask.dateOnly(DateTime.now());
  }

  String _selectedDateLabel() {
    final weekday = _weekdayNames[_selectedDay.weekday - 1];
    final day = _selectedDay.day.toString().padLeft(2, '0');
    final month = _selectedDay.month.toString().padLeft(2, '0');
    return '${weekday[0].toUpperCase()}${weekday.substring(1)}\n$day/$month';
  }

  List<RoutineTask> _visibleTasks(RoutineState routineState) {
    return routineState.tasksForDay(
      elderId: widget.elderId,
      day: _selectedDay,
    );
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
      trailing: canEdit ? EditButtonWidget(onPressed: onEdit) : null,
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
        RoutineViewToggleWidget(
          value: _viewMode,
          onChanged: _changeView,
        ),
        if (_viewMode == RoutineViewMode.day) ...[
          SizedBox(height: sizes.md),
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colorScheme.onPrimary,
                  ),
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
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final tasks = _visibleTasks(routineState);
    final nextTask = _isToday(_selectedDay)
        ? routineState.nextTask(
            elderId: widget.elderId,
            moment: DateTime.now(),
          )
        : (tasks.isEmpty ? null : tasks.first);
    final remainingTasks = tasks
        .where((task) => task.id != nextTask?.id)
        .toList();
    final canCreate = canCreateRoutineTask(
      actor: widget.actor,
      elderId: widget.elderId,
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
          onPressed: nextTask != null &&
                  canEditRoutineTask(
                    actor: widget.actor,
                    task: nextTask,
                    permissions: permissions,
                  )
              ? () => _openTaskForm(task: nextTask)
              : null,
        ),
        if (remainingTasks.isNotEmpty) ...[
          SizedBox(height: sizes.xl),
          Text(
            nextTask == null ? 'Tarefas do dia:' : 'Próximo:',
            style: theme.textTheme.titleMedium,
          ),
          SizedBox(height: sizes.md),
          for (var index = 0; index < remainingTasks.length; index++) ...[
            _taskCard(context, remainingTasks[index], permissions),
            if (index < remainingTasks.length - 1)
              SizedBox(height: sizes.md),
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

  Widget _allDaysContent(
    BuildContext context,
    RoutineState routineState,
  ) {
    final sizes = context.appSizes;
    final today = DateTime.now();
    final months = List.generate(
      12,
      (index) => DateTime(today.year, today.month + index),
    );

    return Column(
      children: [
        for (var index = 0; index < months.length; index++) ...[
          RoutineCalendarWidget(
            month: months[index],
            selectedDay: _selectedDay,
            eventLoader: (day) {
              return routineState.tasksForDay(
                elderId: widget.elderId,
                day: day,
              );
            },
            onDaySelected: _selectDay,
          ),
          if (index < months.length - 1) SizedBox(height: sizes.xl),
        ],
      ],
    );
  }

  Widget _routineContent(
    BuildContext context,
    AsyncValue<List<RoutineTask>> tasksState,
    AsyncValue<RoutinePermissions> permissionsState,
  ) {
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
            final routineState = RoutineState(tasks: tasks);
            return _viewMode == RoutineViewMode.day
                ? _dayContent(context, routineState, permissions)
                : _allDaysContent(context, routineState);
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
    final sizes = context.appSizes;

    return DecoratedBox(
      decoration: _gradientDecoration(context),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: sizes.xxl * 3),
          child: Column(
            children: [
              PageHeaderWidget(
                title: 'Rotina',
                onBackPressed: _goBack,
              ),
              ContentPanelWidget(
                borderRadius: BorderRadius.circular(sizes.radiusLg),
                topPanelPadding: EdgeInsets.all(sizes.md),
                topPanel: _viewControls(
                  context,
                  permissionsState,
                  elderState,
                ),
                padding: EdgeInsets.fromLTRB(
                  sizes.md,
                  sizes.lg,
                  sizes.md,
                  sizes.xl,
                ),
                child: _routineContent(
                  context,
                  tasksState,
                  permissionsState,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutineMessageState extends StatelessWidget {
  const _RoutineMessageState({
    required this.icon,
    required this.message,
  });

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
  const _RoutineInlineMessage({
    required this.icon,
    required this.message,
  });

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
          Icon(icon, size: sizes.xxl, color: colorScheme.primary),
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
      colors: [
        context.appGradientColors.bottom,
        context.appGradientColors.top,
      ],
    ),
  );
}

String _errorMessage(Object error) {
  return error
      .toString()
      .replaceFirst('Bad state: ', '')
      .replaceFirst('Exception: ', '');
}
