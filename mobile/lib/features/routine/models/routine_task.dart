import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum RoutineTaskType {
  breakfast,
  medication,
  meal,
  exercise,
  leisure,
  appointment,
  hygiene,
  sleep,
  other,
}

enum RoutineTaskCreatorRole {
  elder,
  caregiver,
  family,
}

@immutable
class RoutineTask {
  const RoutineTask({
    required this.id,
    required this.elderId,
    required this.title,
    required this.startAt,
    required this.endAt,
    required this.createdByUserId,
    required this.createdByRole,
    this.type = RoutineTaskType.other,
    this.repeatWeekly = false,
    this.repeatWeekdays = const <int>{},
  });

  final String id;
  final String elderId;
  final String title;
  final DateTime startAt;
  final DateTime endAt;
  final String createdByUserId;
  final RoutineTaskCreatorRole createdByRole;
  final RoutineTaskType type;
  final bool repeatWeekly;

  /// Usa os valores de [DateTime.monday] até [DateTime.sunday].
  final Set<int> repeatWeekdays;

  factory RoutineTask.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) {
      throw StateError('Tarefa de rotina não encontrada.');
    }

    final startAt = data['startAt'];
    final endAt = data['endAt'];
    if (startAt is! Timestamp || endAt is! Timestamp) {
      throw StateError('A tarefa ${document.id} possui horários inválidos.');
    }

    final repeatWeekdays = (data['repeatWeekdays'] as List? ?? const [])
        .whereType<num>()
        .map((value) => value.toInt())
        .where(
          (weekday) =>
              weekday >= DateTime.monday && weekday <= DateTime.sunday,
        )
        .toSet();

    return RoutineTask(
      id: document.id,
      elderId: data['elderId']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      startAt: startAt.toDate(),
      endAt: endAt.toDate(),
      createdByUserId: data['createdByUserId']?.toString() ?? '',
      createdByRole: RoutineTaskCreatorRole.values.firstWhere(
        (role) => role.name == data['createdByRole']?.toString(),
        orElse: () => RoutineTaskCreatorRole.elder,
      ),
      type: RoutineTaskType.values.firstWhere(
        (type) => type.name == data['type']?.toString(),
        orElse: () => RoutineTaskType.other,
      ),
      repeatWeekly: data['repeatWeekly'] == true,
      repeatWeekdays: repeatWeekdays,
    );
  }

  Map<String, dynamic> toFirestore({
    required String institutionId,
  }) {
    return {
      'taskId': id,
      'elderId': elderId,
      'institutionId': institutionId,
      'title': title.trim(),
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'createdByUserId': createdByUserId,
      'createdByRole': createdByRole.name,
      'type': type.name,
      'repeatWeekly': repeatWeekly,
      'repeatWeekdays': repeatWeekdays.toList()..sort(),
    };
  }

  bool get endsOnNextDay => !_isSameDate(startAt, endAt);

  String get timeLabel {
    final endLabel = endsOnNextDay ? 'Amanhã' : _formatTime(endAt);
    return '${_formatTime(startAt)} - $endLabel';
  }

  bool occursOn(DateTime day) {
    final normalizedDay = dateOnly(day);
    final firstScheduledDay = dateOnly(startAt);

    if (!repeatWeekly) {
      return normalizedDay == firstScheduledDay;
    }

    return !normalizedDay.isBefore(firstScheduledDay) &&
        repeatWeekdays.contains(normalizedDay.weekday);
  }

  DateTime startOn(DateTime day) {
    return DateTime(
      day.year,
      day.month,
      day.day,
      startAt.hour,
      startAt.minute,
    );
  }

  DateTime endOn(DateTime day) {
    final end = DateTime(
      day.year,
      day.month,
      day.day,
      endAt.hour,
      endAt.minute,
    );

    return endsOnNextDay ? end.add(const Duration(days: 1)) : end;
  }

  RoutineTask copyWith({
    String? id,
    String? title,
    DateTime? startAt,
    DateTime? endAt,
    RoutineTaskType? type,
    bool? repeatWeekly,
    Set<int>? repeatWeekdays,
  }) {
    return RoutineTask(
      id: id ?? this.id,
      elderId: elderId,
      title: title ?? this.title,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      createdByUserId: createdByUserId,
      createdByRole: createdByRole,
      type: type ?? this.type,
      repeatWeekly: repeatWeekly ?? this.repeatWeekly,
      repeatWeekdays: repeatWeekdays ?? this.repeatWeekdays,
    );
  }

  static DateTime dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  static String _formatTime(DateTime value) {
    final hour = value.hour.toString();
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
