import '../models/routine_elder_summary.dart';
import '../models/routine_task.dart';
import '../models/routine_task_completion.dart';

typedef PendingRoutineTask = ({RoutineElderSummary elder, RoutineTask task});

List<PendingRoutineTask> findPendingRoutineTasks({
  required List<RoutineElderSummary> elders,
  required List<List<RoutineTask>> tasksByElder,
  required List<List<RoutineTaskCompletion>> completionsByElder,
  required DateTime now,
}) {
  final today = RoutineTask.dateOnly(now);
  final pendingTasks = <PendingRoutineTask>[];

  for (var index = 0; index < elders.length; index++) {
    final elder = elders[index];
    final completedIds = completionsByElder[index]
        .map((completion) => completion.id)
        .toSet();

    for (final task in tasksByElder[index]) {
      if (!task.occursOn(today) || task.startOn(today).isAfter(now)) {
        continue;
      }

      final completionId = RoutineTaskCompletion.documentIdFor(
        taskId: task.id,
        occurrenceDate: today,
        taskWasRecurring: task.repeatWeekly,
      );
      if (!completedIds.contains(completionId)) {
        pendingTasks.add((elder: elder, task: task));
      }
    }
  }

  pendingTasks.sort(
    (first, second) =>
        first.task.startOn(today).compareTo(second.task.startOn(today)),
  );
  return pendingTasks;
}
