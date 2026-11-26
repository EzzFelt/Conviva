import 'package:flutter/material.dart';

import '../../routine/models/routine_task.dart';

IconData routineTaskIcon(RoutineTaskType? type) {
  return switch (type) {
    RoutineTaskType.breakfast => Icons.breakfast_dining_rounded,
    RoutineTaskType.medication => Icons.medication_rounded,
    RoutineTaskType.meal => Icons.restaurant_rounded,
    RoutineTaskType.exercise => Icons.directions_walk_rounded,
    RoutineTaskType.leisure => Icons.interests_rounded,
    RoutineTaskType.appointment => Icons.medical_services_rounded,
    RoutineTaskType.hygiene => Icons.shower_rounded,
    RoutineTaskType.sleep => Icons.bed_rounded,
    RoutineTaskType.other || null => Icons.event_available_rounded,
  };
}
