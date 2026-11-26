import 'package:conviva/core/settings/app_settings.dart';
import 'package:conviva/core/themes/app_theme.dart';
import 'package:conviva/features/routine/models/routine_elder_summary.dart';
import 'package:conviva/features/routine/models/routine_task.dart';
import 'package:conviva/features/routine/models/routine_task_completion.dart';
import 'package:conviva/features/routine/pages/pending_routine_tasks_page.dart';
import 'package:conviva/features/routine/providers/routine_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows all pending tasks across residents', (tester) async {
    tester.view.physicalSize = const Size(365, 802);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now();
    final elders = [
      const RoutineElderSummary(
        id: 'elder-1',
        name: 'Residente Um',
        phone: '',
        institutionId: 'institution-1',
      ),
      const RoutineElderSummary(
        id: 'elder-2',
        name: 'Residente Dois',
        phone: '',
        institutionId: 'institution-1',
      ),
      const RoutineElderSummary(
        id: 'elder-3',
        name: 'Residente sem rotina',
        phone: '',
        institutionId: 'institution-1',
      ),
    ];
    final tasks = {
      'elder-1': [
        _pendingTask('task-1', 'elder-1', 'Pendência um', now),
        _pendingTask('task-2', 'elder-1', 'Pendência dois', now),
        _pendingTask('task-3', 'elder-1', 'Pendência três', now),
      ],
      'elder-2': [_pendingTask('task-4', 'elder-2', 'Pendência quatro', now)],
    };

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accessibleRoutineEldersProvider.overrideWith(
            (_) => Stream.value(elders),
          ),
          routineTasksProvider.overrideWith(
            (_, elderId) => Stream.value(tasks[elderId] ?? const []),
          ),
          routineCompletionsProvider.overrideWith(
            (_, _) => Stream.value(const <RoutineTaskCompletion>[]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(const AppSettings()),
          home: const PendingRoutineTasksPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pendência um'), findsOneWidget);
    expect(find.text('Pendência dois'), findsOneWidget);
    expect(find.text('Pendência três'), findsOneWidget);
    expect(find.text('Pendência quatro'), findsOneWidget);
    expect(find.text('Residente sem rotina'), findsOneWidget);
    final bottomSurface = tester.getRect(
      find.byKey(const ValueKey('pending-page-bottom-surface')),
    );
    expect(bottomSurface.bottom, closeTo(802, 1));
    expect(tester.takeException(), isNull);
  });
}

RoutineTask _pendingTask(
  String id,
  String elderId,
  String title,
  DateTime now,
) {
  return RoutineTask(
    id: id,
    elderId: elderId,
    title: title,
    startAt: RoutineTask.dateOnly(now),
    endAt: RoutineTask.dateOnly(now).add(const Duration(hours: 1)),
    createdByUserId: 'caregiver-1',
    createdByRole: RoutineTaskCreatorRole.caregiver,
  );
}
