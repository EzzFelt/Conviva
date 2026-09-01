import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/models/account_type.dart';
import '../../auth/providers/current_user_provider.dart';
import '../models/routine_task.dart';

final nextElderRoutineProvider = FutureProvider<RoutineTask?>((ref) async {
  final session = await ref.watch(currentUserProvider.future);

  if (session == null || session.accountType != AccountType.elder) {
    return null;
  }

  // Ponto de integração com o repositório de rotinas do idoso.
  return null;
});
