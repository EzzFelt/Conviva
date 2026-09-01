import 'package:flutter/foundation.dart';

enum RoutineTaskType {
  breakfast,
  medication,
  meal,
  exercise,
  leisure,
  appointment,
  other,
}

@immutable
class RoutineTask {
  const RoutineTask({
    required this.id,
    required this.title,
    required this.startAt,
    required this.endAt,
    this.type = RoutineTaskType.other,
  });

  final String id;
  final String title;
  final DateTime startAt;
  final DateTime endAt;
  final RoutineTaskType type;

  String get timeLabel {
    return '${_formatTime(startAt)} - ${_formatTime(endAt)}';
  }

  static String _formatTime(DateTime value) {
    final hour = value.hour.toString();
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
