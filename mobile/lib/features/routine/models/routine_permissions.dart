import 'package:cloud_firestore/cloud_firestore.dart';
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

  bool get canElderManageOwnRoutine =>
      canElderCreateTasks && canElderEditOwnTasks;

  factory RoutinePermissions.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    // Sem documento de permissões, mantém os valores padrão.
    if (!document.exists || data == null) {
      return RoutinePermissions(
        elderId: document.id,
      );
    }

    // Se o documento existe, somente permissões explicitamente
    // habilitadas são consideradas ativas.
    return RoutinePermissions(
      elderId: document.id,
      canElderCreateTasks:
          data['canElderCreateTasks'] == true,
      canElderEditOwnTasks:
          data['canElderEditOwnTasks'] == true,
    );
  }

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