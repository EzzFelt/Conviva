import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_colors.dart';
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
import '../models/routine_task.dart';
import '../providers/routine_provider.dart';
import '../widgets/routine_calendar_widget.dart';
import '../widgets/routine_task_form_modal.dart';
import '../widgets/routine_view_toggle_widget.dart';

class RoutinePage extends ConsumerStatefulWidget {
  const RoutinePage({super.key});

  @override
  ConsumerState<RoutinePage> createState() => _RoutinePageState();
}

class _RoutinePageState extends ConsumerState<RoutinePage> {
  late DateTime _selectedDay;
  RoutineViewMode _viewMode = RoutineViewMode.day;

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

  RoutineTaskCreatorRole _creatorRole(AccountType accountType) {
    return switch (accountType) {
      AccountType.elder => RoutineTaskCreatorRole.elder,
      AccountType.caregiver => RoutineTaskCreatorRole.caregiver,
      AccountType.family => RoutineTaskCreatorRole.family,
    };
  }

  Future<void> _goHome(
    BuildContext context,
    UserSession session,
  ) async {
    await AuthenticatedUserNavigator.open(context, session);
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

  Future<void> _openTaskForm(
    UserSession session, {
    RoutineTask? task,
  }) async {
    final result = await showAppModal<RoutineTaskFormResult>(
      context: context,
      size: AppModalSize.large,
      child: RoutineTaskFormModal(
        selectedDate: _selectedDay,
        elderId: session.uid,
        createdByUserId: session.uid,
        createdByRole: _creatorRole(session.accountType),
        task: task,
      ),
    );

    if (result == null || !mounted) return;

    final notifier = ref.read(routineProvider.notifier);
    try {
      switch (result.action) {
        case RoutineTaskFormAction.save:
          if (task == null) {
            notifier.addTask(actor: session, task: result.task);
          } else {
            notifier.updateTask(actor: session, task: result.task);
          }
          break;
        case RoutineTaskFormAction.delete:
          notifier.removeTask(actor: session, task: result.task);
          break;
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage(error))),
      );
    }
  }

  String _errorMessage(Object error) {
    return error
        .toString()
        .replaceFirst('Bad state: ', '')
        .replaceFirst('Exception: ', '');
  }

  bool _isToday(DateTime day) {
    return RoutineTask.dateOnly(day) ==
        RoutineTask.dateOnly(DateTime.now());
  }

  String _selectedDateLabel() {
    final weekday = _weekdayNames[_selectedDay.weekday - 1];
    final day = _selectedDay.day.toString().padLeft(2, '0');
    final month = _selectedDay.month.toString().padLeft(2, '0');
    return '${weekday[0].toUpperCase()}${weekday.substring(1)}\n$day/$month';
  }

  List<RoutineTask> _visibleTasks(
    RoutineState routineState,
    UserSession session,
  ) {
    final tasks = routineState.tasksForDay(
      elderId: session.uid,
      day: _selectedDay,
    );

    return tasks;
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
    UserSession session,
    RoutineTask task,
    RoutineNotifier notifier,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final sizes = context.appSizes;
    final canEdit = notifier.canEditTask(
      actor: session,
      task: task,
    );
    final onEdit = canEdit
        ? () => _openTaskForm(session, task: task)
        : null;

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
      trailing: canEdit
          ? EditButtonWidget(onPressed: onEdit)
          : null,
    );
  }

  Widget _viewControls(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sizes = context.appSizes;

    return Column(
      children: [
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
      ],
    );
  }

  Widget _dayContent(
    BuildContext context,
    UserSession session,
    RoutineState routineState,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final notifier = ref.read(routineProvider.notifier);
    final tasks = _visibleTasks(routineState, session);
    final nextTask = _isToday(_selectedDay)
        ? routineState.nextTask(
            elderId: session.uid,
            moment: DateTime.now(),
          )
        : (tasks.isEmpty ? null : tasks.first);
    final remainingTasks = tasks
        .where((task) => task.id != nextTask?.id)
        .toList();
    final canCreate = notifier.canCreateTask(
      actor: session,
      elderId: session.uid,
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
                  notifier.canEditTask(actor: session, task: nextTask)
              ? () => _openTaskForm(session, task: nextTask)
              : null,
        ),
        if (remainingTasks.isNotEmpty) ...[
          SizedBox(height: sizes.xl),
          Text(
            nextTask == null ? 'Tarefas de hoje:' : 'Próximo:',
            style: theme.textTheme.titleMedium,
          ),
          SizedBox(height: sizes.md),
          for (var index = 0;
              index < remainingTasks.length;
              index++) ...[
            _taskCard(
              context,
              session,
              remainingTasks[index],
              notifier,
            ),
            if (index < remainingTasks.length - 1)
              SizedBox(height: sizes.md),
          ],
        ],
        SizedBox(height: sizes.xl),
        if (canCreate)
          AddNewButtonWidget(
            label: 'Adicionar tarefa',
            onPressed: () => _openTaskForm(session),
          )
        else
          Container(
            padding: EdgeInsets.all(sizes.md),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(sizes.radiusMd),
            ),
            child: Text(
              'Seu cuidador desativou a criação de tarefas próprias.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ),
      ],
    );
  }

  Widget _allDaysContent(
    BuildContext context,
    UserSession session,
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
                elderId: session.uid,
                day: day,
              );
            },
            onDaySelected: _selectDay,
          ),
          if (index < months.length - 1)
            SizedBox(height: sizes.xl),
        ],
      ],
    );
  }

  Widget _elderRoutine(
    BuildContext context,
    UserSession session,
  ) {
    final sizes = context.appSizes;
    final routineState = ref.watch(routineProvider);
    final panelRadius = BorderRadius.circular(sizes.radiusLg);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.appGradientColors.bottom,
            context.appGradientColors.top,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: sizes.xxl * 3,
          ),
          child: Column(
            children: [
              PageHeaderWidget(
                title: 'Rotina',
                onBackPressed: () => _goHome(context, session),
              ),
              ContentPanelWidget(
                borderRadius: panelRadius,
                topPanelPadding: EdgeInsets.all(sizes.md),
                topPanel: _viewControls(context),
                padding: EdgeInsets.fromLTRB(
                  sizes.md,
                  sizes.lg,
                  sizes.md,
                  sizes.xl,
                ),
                child: _viewMode == RoutineViewMode.day
                    ? _dayContent(context, session, routineState)
                    : _allDaysContent(context, session, routineState),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _messageState(
    BuildContext context, {
    required IconData icon,
    required String message,
    bool loading = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(sizes.lg),
          child: loading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: sizes.xxl,
                      color: colorScheme.primary,
                    ),
                    SizedBox(height: sizes.md),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: currentUser.when(
        loading: () => _messageState(
          context,
          icon: Icons.event_rounded,
          message: '',
          loading: true,
        ),
        error: (error, _) => _messageState(
          context,
          icon: Icons.error_outline_rounded,
          message: _errorMessage(error),
        ),
        data: (session) {
          if (session == null) {
            return _messageState(
              context,
              icon: Icons.person_off_rounded,
              message: 'Usuário não autenticado.',
            );
          }

          if (session.accountType != AccountType.elder) {
            return _messageState(
              context,
              icon: Icons.construction_rounded,
              message: 'A rotina deste perfil será construída na próxima etapa.',
            );
          }

          return _elderRoutine(context, session);
        },
      ),
    );
  }
}
