import 'package:flutter/foundation.dart';

@immutable
class RoutinePermissions {
  const RoutinePermissions({
    required this.elderId,
    this.canElderCreateTasks = true,
    this.canElderEditOwnTasks = true,
  });

  final String elderId;
  final bool canElderCreateTasks;
  final bool canElderEditOwnTasks;

  RoutinePermissions copyWith({
    bool? canElderCreateTasks,
    bool? canElderEditOwnTasks,
  }) {
    return RoutinePermissions(
      elderId: elderId,
      canElderCreateTasks:
          canElderCreateTasks ?? this.canElderCreateTasks,
      canElderEditOwnTasks:
          canElderEditOwnTasks ?? this.canElderEditOwnTasks,
    );
  }
}
