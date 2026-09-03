import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/models/account_type.dart';
import '../../auth/models/user_session.dart';
import '../../auth/providers/current_user_provider.dart';
import '../models/routine_elder_summary.dart';
import '../models/routine_permissions.dart';
import '../models/routine_task.dart';
import '../repositories/routine_repository.dart';

final routineRepositoryProvider = Provider<RoutineRepository>(
  (_) => RoutineRepository.instance,
);

final accessibleRoutineEldersProvider =
    StreamProvider<List<RoutineElderSummary>>((ref) async* {
  final actor = await ref.watch(currentUserProvider.future);
  if (actor == null) {
    yield const <RoutineElderSummary>[];
    return;
  }

  final repository = ref.watch(routineRepositoryProvider);
  yield* repository.watchAccessibleElders(actor);
});

final routineElderProvider =
    StreamProvider.family<RoutineElderSummary?, String>((ref, elderId) {
  return ref.watch(routineRepositoryProvider).watchElder(elderId);
});

final routineTasksProvider =
    StreamProvider.family<List<RoutineTask>, String>((ref, elderId) {
  return ref.watch(routineRepositoryProvider).watchTasks(elderId);
});

final routinePermissionsProvider =
    StreamProvider.family<RoutinePermissions, String>((ref, elderId) {
  return ref.watch(routineRepositoryProvider).watchPermissions(elderId);
});

@immutable
class RoutineState {
  const RoutineState({this.tasks = const <RoutineTask>[]});

  final List<RoutineTask> tasks;

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

    return List<RoutineTask>.unmodifiable(result);
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
}

bool canCreateRoutineTask({
  required UserSession actor,
  required String elderId,
  required RoutinePermissions permissions,
}) {
  if (actor.accountType != AccountType.elder) return true;
  return actor.uid == elderId && permissions.canElderCreateTasks;
}

bool canEditRoutineTask({
  required UserSession actor,
  required RoutineTask task,
  required RoutinePermissions permissions,
}) {
  if (actor.accountType != AccountType.elder) return true;
  return actor.uid == task.elderId &&
      task.createdByUserId == actor.uid &&
      permissions.canElderEditOwnTasks;
}
