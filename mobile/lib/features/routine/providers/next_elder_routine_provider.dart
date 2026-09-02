import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/models/account_type.dart';
import '../../auth/providers/current_user_provider.dart';
import '../models/routine_task.dart';
import 'routine_provider.dart';

final nextElderRoutineProvider = FutureProvider<RoutineTask?>((ref) async {
  final routineState = ref.watch(routineProvider);
  final session = await ref.watch(currentUserProvider.future);

  if (session == null || session.accountType != AccountType.elder) {
    return null;
  }

  return routineState.nextTask(
    elderId: session.uid,
    moment: DateTime.now(),
  );
});
