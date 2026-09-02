import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/models/account_type.dart';
import '../../auth/models/user_session.dart';
import '../models/routine_permissions.dart';
import '../models/routine_task.dart';

final routineProvider = NotifierProvider<RoutineNotifier, RoutineState>(
  RoutineNotifier.new,
);

@immutable
class RoutineState {
  const RoutineState({
    this.tasks = const <RoutineTask>[],
    this.permissionsByElder = const <String, RoutinePermissions>{},
  });

  final List<RoutineTask> tasks;
  final Map<String, RoutinePermissions> permissionsByElder;

  RoutinePermissions permissionsFor(String elderId) {
    return permissionsByElder[elderId] ??
        RoutinePermissions(elderId: elderId);
  }

  List<RoutineTask> tasksForDay({
    required String elderId,
    required DateTime day,
  }) {
    final result = tasks
        .where((task) => task.elderId == elderId && task.occursOn(day))
        .toList()
      ..sort((first, second) {
        return first.startOn(day).compareTo(second.startOn(day));
      });

    return List.unmodifiable(result);
  }

  RoutineTask? nextTask({
    required String elderId,
    required DateTime moment,
  }) {
    final day = RoutineTask.dateOnly(moment);
    final candidates = tasksForDay(elderId: elderId, day: day)
        .where((task) => task.endOn(day).isAfter(moment))
        .toList();

    return candidates.isEmpty ? null : candidates.first;
  }

  RoutineState copyWith({
    List<RoutineTask>? tasks,
    Map<String, RoutinePermissions>? permissionsByElder,
  }) {
    return RoutineState(
      tasks: tasks ?? this.tasks,
      permissionsByElder:
          permissionsByElder ?? this.permissionsByElder,
    );
  }
}

class RoutineNotifier extends Notifier<RoutineState> {
  @override
  RoutineState build() => const RoutineState();

  bool canCreateTask({
    required UserSession actor,
    required String elderId,
  }) {
    if (actor.accountType != AccountType.elder) {
      return true;
    }

    return actor.uid == elderId &&
        state.permissionsFor(elderId).canElderCreateTasks;
  }

  bool canEditTask({
    required UserSession actor,
    required RoutineTask task,
  }) {
    if (actor.accountType != AccountType.elder) {
      return true;
    }

    final permissions = state.permissionsFor(task.elderId);
    return actor.uid == task.elderId &&
        task.createdByUserId == actor.uid &&
        permissions.canElderEditOwnTasks;
  }

  void addTask({
    required UserSession actor,
    required RoutineTask task,
  }) {
    if (!canCreateTask(actor: actor, elderId: task.elderId)) {
      throw StateError(
        'Seu cuidador desativou a criação de tarefas.',
      );
    }

    _validateTask(task);
    state = state.copyWith(tasks: [...state.tasks, task]);
  }

  void updateTask({
    required UserSession actor,
    required RoutineTask task,
  }) {
    final currentIndex = state.tasks.indexWhere(
      (currentTask) => currentTask.id == task.id,
    );
    if (currentIndex == -1) {
      throw StateError('Tarefa não encontrada.');
    }

    final currentTask = state.tasks[currentIndex];
    if (!canEditTask(actor: actor, task: currentTask)) {
      throw StateError('Você não possui permissão para editar esta tarefa.');
    }

    _validateTask(task);
    final updatedTasks = [...state.tasks];
    updatedTasks[currentIndex] = task;
    state = state.copyWith(tasks: updatedTasks);
  }

  void removeTask({
    required UserSession actor,
    required RoutineTask task,
  }) {
    if (!canEditTask(actor: actor, task: task)) {
      throw StateError('Você não possui permissão para remover esta tarefa.');
    }

    state = state.copyWith(
      tasks: state.tasks
          .where((currentTask) => currentTask.id != task.id)
          .toList(),
    );
  }

  void setElderPermissions({
    required UserSession actor,
    required String elderId,
    required bool canCreateTasks,
    required bool canEditOwnTasks,
  }) {
    if (actor.accountType != AccountType.caregiver) {
      throw StateError(
        'Somente o cuidador pode alterar as permissões da rotina.',
      );
    }

    state = state.copyWith(
      permissionsByElder: {
        ...state.permissionsByElder,
        elderId: RoutinePermissions(
          elderId: elderId,
          canElderCreateTasks: canCreateTasks,
          canElderEditOwnTasks: canEditOwnTasks,
        ),
      },
    );
  }

  void _validateTask(RoutineTask task) {
    if (task.title.trim().isEmpty) {
      throw StateError('Informe o nome da tarefa.');
    }

    if (!task.endAt.isAfter(task.startAt)) {
      throw StateError('O término deve ser posterior ao começo.');
    }

    if (task.repeatWeekly && task.repeatWeekdays.isEmpty) {
      throw StateError('Escolha pelo menos um dia para repetir a tarefa.');
    }
  }
}
