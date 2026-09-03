import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/models/account_type.dart';
import '../../auth/providers/current_user_provider.dart';
import '../models/routine_task.dart';
import 'routine_provider.dart';

final nextElderRoutineProvider = StreamProvider<RoutineTask?>((ref) async* {
  final session = await ref.watch(currentUserProvider.future);
  if (session == null || session.accountType != AccountType.elder) {
    yield null;
    return;
  }

  final repository = ref.watch(routineRepositoryProvider);
  yield* repository.watchTasks(session.uid).map((tasks) {
    return RoutineState(tasks: tasks).nextTask(
      elderId: session.uid,
      moment: DateTime.now(),
    );
  });
});
