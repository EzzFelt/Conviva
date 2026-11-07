
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'routine_task.dart';

@immutable
class RoutineTaskCompletion {
  const RoutineTaskCompletion({
    required this.id,
    required this.taskId,
    required this.elderId,
    required this.institutionId,
    required this.taskTitle,
    required this.taskType,
    required this.occurrenceDate,
    required this.scheduledStartAt,
    required this.scheduledEndAt,
    required this.completedAt,
    required this.completedByUserId,
    required this.completedByRole,
    required this.taskWasRecurring,
  });

  final String id;
  final String taskId;
  final String elderId;
  final String institutionId;

  // Informações preservadas da tarefa original.
  final String taskTitle;
  final RoutineTaskType taskType;

  // Data específica em que a tarefa foi realizada.
  final DateTime occurrenceDate;

  // Horários previstos para aquela ocorrência.
  final DateTime scheduledStartAt;
  final DateTime scheduledEndAt;

  // Registro da conclusão.
  final DateTime completedAt;
  final String completedByUserId;
  final RoutineTaskCreatorRole completedByRole;

  // Indica se a tarefa original era recorrente.
  final bool taskWasRecurring;

  factory RoutineTaskCompletion.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (data == null) {
      throw StateError('Registro de conclusão não encontrado.');
    }

    DateTime readDate(String field) {
      final value = data[field];

      if (value is! Timestamp) {
        throw StateError(
          'O campo $field do histórico possui uma data inválida.',
        );
      }

      return value.toDate();
    }

    return RoutineTaskCompletion(
      id: document.id,
      taskId: data['taskId']?.toString() ?? '',
      elderId: data['elderId']?.toString() ?? '',
      institutionId: data['institutionId']?.toString() ?? '',
      taskTitle: data['taskTitle']?.toString() ?? '',
      taskType: RoutineTaskType.values.firstWhere(
        (type) => type.name == data['taskType']?.toString(),
        orElse: () => RoutineTaskType.other,
      ),
      occurrenceDate: readDate('occurrenceDate'),
      scheduledStartAt: readDate('scheduledStartAt'),
      scheduledEndAt: readDate('scheduledEndAt'),
      completedAt: readDate('completedAt'),
      completedByUserId:
          data['completedByUserId']?.toString() ?? '',
      completedByRole: RoutineTaskCreatorRole.values.firstWhere(
        (role) => role.name == data['completedByRole']?.toString(),
        orElse: () => RoutineTaskCreatorRole.elder,
      ),
      taskWasRecurring: data['taskWasRecurring'] == true,
    );
  }

  /// Gera um ID determinístico para impedir conclusões duplicadas.
  ///
  /// Tarefas únicas possuem apenas um registro.
  /// Tarefas recorrentes possuem um registro para cada ocorrência.
  static String documentIdFor({
    required String taskId,
    required DateTime occurrenceDate,
    required bool taskWasRecurring,
  }) {
    if (!taskWasRecurring) {
      return taskId;
    }

    final day = occurrenceDate.day.toString().padLeft(2, '0');
    final month = occurrenceDate.month.toString().padLeft(2, '0');

    return '${taskId}_${occurrenceDate.year}$month$day';
  }

  String get timeLabel {
    final sameDay =
        scheduledStartAt.year == scheduledEndAt.year &&
        scheduledStartAt.month == scheduledEndAt.month &&
        scheduledStartAt.day == scheduledEndAt.day;

    final endLabel = sameDay
        ? _formatTime(scheduledEndAt)
        : 'Amanhã';

    return '${_formatTime(scheduledStartAt)} - $endLabel';
  }

  String get occurrenceDateLabel {
    final day = occurrenceDate.day.toString().padLeft(2, '0');
    final month = occurrenceDate.month.toString().padLeft(2, '0');

    return '$day/$month/${occurrenceDate.year}';
  }

  String get completedTimeLabel {
    return _formatTime(completedAt);
  }

  static String _formatTime(DateTime value) {
    final hour = value.hour.toString();
    final minute = value.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}
