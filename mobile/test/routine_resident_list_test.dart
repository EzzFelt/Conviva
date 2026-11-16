import 'package:conviva/core/settings/app_settings.dart';
import 'package:conviva/core/themes/app_theme.dart';
import 'package:conviva/features/auth/models/account_type.dart';
import 'package:conviva/features/auth/models/user_session.dart';
import 'package:conviva/features/auth/providers/current_user_provider.dart';
import 'package:conviva/features/routine/models/routine_elder_summary.dart';
import 'package:conviva/features/routine/models/routine_permissions.dart';
import 'package:conviva/features/routine/models/routine_task.dart';
import 'package:conviva/features/routine/models/routine_task_completion.dart';
import 'package:conviva/features/routine/pages/routine_page.dart';
import 'package:conviva/features/routine/providers/routine_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the routine detail on a phone without layout errors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(365, 802);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final elder = RoutineElderSummary(
      id: 'elder-1',
      name: 'Maria',
      phone: '',
      institutionId: 'institution-1',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith(_TestCaregiverNotifier.new),
          routineElderProvider(
            elder.id,
          ).overrideWith((_) => Stream.value(elder)),
          routineTasksProvider(
            elder.id,
          ).overrideWith((_) => Stream.value(const <RoutineTask>[])),
          routinePermissionsProvider(elder.id).overrideWith(
            (_) => Stream.value(RoutinePermissions(elderId: elder.id)),
          ),
          routineCompletionsProvider(
            elder.id,
          ).overrideWith((_) => Stream.value(const <RoutineTaskCompletion>[])),
        ],
        child: MaterialApp(
          theme: AppTheme.light(const AppSettings()),
          home: RoutinePage(elderId: elder.id),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Rotina'), findsOneWidget);
    expect(find.text('Sua próxima tarefa:'), findsOneWidget);
    final routineBackground = tester.widget<ColoredBox>(
      find.byKey(const ValueKey('routine-content-background')),
    );
    expect(
      routineBackground.color,
      AppTheme.light(const AppSettings()).scaffoldBackgroundColor,
    );
    final pageTitle = find.text('Rotina', skipOffstage: false);
    final dailyTitleTop = tester.getTopLeft(pageTitle).dy;
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -100));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(pageTitle).dy, lessThan(dailyTitleTop));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 100));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ver histórico'));
    await tester.pumpAndSettle();
    expect(
      find.text('Nenhuma tarefa concluída até o momento.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Voltar à rotina'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Todos os dias'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final titleTop = tester.getTopLeft(pageTitle).dy;
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -100));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(pageTitle).dy, lessThan(titleTop));
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows resident profile details in the caregiver list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(365, 802);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final elder = RoutineElderSummary(
      id: 'elder-1',
      name: 'Maria Antônia',
      phone: '11987654321',
      institutionId: 'institution-1',
      gender: 'Feminino',
      bloodType: 'O+',
      dependencyLevel: '1',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith(_TestCaregiverNotifier.new),
          accessibleRoutineEldersProvider.overrideWith(
            (_) => Stream.value([elder]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(const AppSettings()),
          home: const RoutinePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Residentes'), findsOneWidget);
    expect(find.text('Seus residentes'), findsOneWidget);
    expect(find.text('Maria Antônia'), findsOneWidget);
    expect(find.text('Tel: (11) 98765-4321'), findsOneWidget);
    expect(find.text('Sexo: Feminino'), findsOneWidget);
    expect(find.text('Tipo sanguíneo: O+'), findsOneWidget);
    expect(find.text('Grau de dependência: 1'), findsOneWidget);
    expect(find.text('Ver rotina'), findsOneWidget);
    final residentsScrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.byType(Scrollable),
      ),
    );
    expect(residentsScrollable.position.maxScrollExtent, 0);
    expect(tester.takeException(), isNull);
  });
}

class _TestCaregiverNotifier extends CurrentUserNotifier {
  @override
  Future<UserSession?> build() async => const UserSession(
    uid: 'caregiver-1',
    name: 'Cuidador',
    phone: '',
    accountType: AccountType.caregiver,
    institutionId: 'institution-1',
    status: 'active',
  );
}
