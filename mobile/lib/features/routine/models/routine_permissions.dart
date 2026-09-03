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
    return RoutinePermissions(
      elderId: document.id,
      canElderCreateTasks: data?['canElderCreateTasks'] != false,
      canElderEditOwnTasks: data?['canElderEditOwnTasks'] != false,
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
