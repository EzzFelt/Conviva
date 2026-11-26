import 'package:conviva/core/settings/app_settings.dart';
import 'package:conviva/core/themes/app_theme.dart';
import 'package:conviva/features/auth/models/account_type.dart';
import 'package:conviva/features/auth/models/user_session.dart';
import 'package:conviva/features/auth/providers/current_user_provider.dart';
import 'package:conviva/features/chat/models/conversation_preview.dart';
import 'package:conviva/features/chat/providers/conversation_previews_provider.dart';
import 'package:conviva/features/home/family/family_home_page.dart';
import 'package:conviva/features/routine/models/routine_elder_summary.dart';
import 'package:conviva/features/routine/models/routine_task.dart';
import 'package:conviva/features/routine/providers/routine_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('switches the elder shown on the family home', (tester) async {
    final firstElder = RoutineElderSummary(
      id: 'elder-1',
      name: 'Primeiro idoso',
      phone: '',
      institutionId: 'institution-1',
    );
    final secondElder = RoutineElderSummary(
      id: 'elder-2',
      name: 'Segundo idoso',
      phone: '',
      institutionId: 'institution-1',
    );
    final today = DateTime.now();

    RoutineTask taskFor(RoutineElderSummary elder, String title) {
      final now = DateTime.now();
      return RoutineTask(
        id: 'task-${elder.id}',
        elderId: elder.id,
        title: title,
        startAt: DateTime(now.year, now.month, now.day, 9),
        endAt: DateTime(now.year, now.month, now.day, 10),
        createdByUserId: elder.id,
        createdByRole: RoutineTaskCreatorRole.elder,
      );
    }

    final firstConversation = ConversationPreview(
      id: 'conversation-1',
      participantId: firstElder.id,
      participantName: firstElder.name,
      lastMessage: 'Mensagem do primeiro idoso',
      participantType: ConversationParticipantType.elder,
      lastMessageAt: DateTime(today.year, today.month, today.day, 12),
    );
    final secondConversation = ConversationPreview(
      id: 'conversation-2',
      participantId: secondElder.id,
      participantName: secondElder.name,
      lastMessage: 'Mensagem do segundo idoso',
      participantType: ConversationParticipantType.elder,
      lastMessageAt: DateTime(today.year, today.month, today.day, 13),
    );

    tester.view.physicalSize = const Size(365, 802);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final providerOverrides = [
      currentUserProvider.overrideWith(_TestCurrentUserNotifier.new),
      accessibleRoutineEldersProvider.overrideWith(
        (_) => Stream.value([firstElder, secondElder]),
      ),
      linkedFamilyIdsProvider.overrideWith(
        (_) => Stream.value({firstElder.id, secondElder.id}),
      ),
      conversationPreviewsProvider.overrideWith(
        (_) => Stream.value([firstConversation, secondConversation]),
      ),
      routineTasksProvider(
        firstElder.id,
      ).overrideWith((_) => Stream.value([taskFor(firstElder, 'Rotina um')])),
      routineTasksProvider(secondElder.id).overrideWith(
        (_) => Stream.value([taskFor(secondElder, 'Rotina dois')]),
      ),
    ];

    Widget homeApp({Key? pageKey}) {
      return ProviderScope(
        overrides: providerOverrides,
        child: MaterialApp(
          theme: AppTheme.light(const AppSettings()),
          home: FamilyHomePage(key: pageKey, elderId: 'elder-1'),
        ),
      );
    }

    await tester.pumpWidget(homeApp());
    await tester.pumpAndSettle();

    expect(find.text('Rotina um'), findsOneWidget);
    expect(find.text('Mensagem do primeiro idoso'), findsOneWidget);
    expect(find.text('Mensagem do segundo idoso'), findsNothing);
    expect(find.text('12:00'), findsOneWidget);
    expect(find.text('Adicionar Familiar'), findsOneWidget);
    expect(find.text('Trocar o idoso visualizado'), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const ValueKey('family-elder-selector'))).top,
      lessThan(
        tester.getRect(find.byKey(const ValueKey('family-routine-card'))).top,
      ),
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('family-elder-selector')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('family-elder-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Segundo idoso').last);
    await tester.pumpAndSettle();

    expect(find.text('Rotina dois'), findsOneWidget);
    expect(find.text('Rotina um'), findsNothing);
    expect(find.text('Mensagem do segundo idoso'), findsOneWidget);
    expect(find.text('Mensagem do primeiro idoso'), findsNothing);
    expect(
      await SharedPreferencesAsync().getString(
        'conviva_family_selected_elder_family-1',
      ),
      secondElder.id,
    );

    await tester.pumpWidget(homeApp(pageKey: const ValueKey('restored-home')));
    await tester.pumpAndSettle();

    expect(find.text('Rotina dois'), findsOneWidget);
    expect(find.text('Mensagem do segundo idoso'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders routine tasks inside the scrollable family home', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(365, 802);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now();
    final elder = RoutineElderSummary(
      id: 'elder-1',
      name: 'Pessoa idosa',
      phone: '',
      institutionId: 'institution-1',
    );
    final task = RoutineTask(
      id: 'task-1',
      elderId: elder.id,
      title: 'Alongamento',
      startAt: DateTime(now.year, now.month, now.day, 9),
      endAt: DateTime(now.year, now.month, now.day, 10),
      createdByUserId: elder.id,
      createdByRole: RoutineTaskCreatorRole.elder,
      type: RoutineTaskType.leisure,
    );
    final secondTask = RoutineTask(
      id: 'task-2',
      elderId: elder.id,
      title: 'Medicação',
      startAt: DateTime(now.year, now.month, now.day, 20, 5),
      endAt: DateTime(now.year, now.month, now.day, 20, 15),
      createdByUserId: elder.id,
      createdByRole: RoutineTaskCreatorRole.elder,
      type: RoutineTaskType.meal,
    );
    final thirdTask = RoutineTask(
      id: 'task-3',
      elderId: elder.id,
      title: 'Jantar',
      startAt: DateTime(now.year, now.month, now.day, 20, 30),
      endAt: DateTime(now.year, now.month, now.day, 21),
      createdByUserId: elder.id,
      createdByRole: RoutineTaskCreatorRole.elder,
      type: RoutineTaskType.medication,
    );
    final yesterdayTask = RoutineTask(
      id: 'task-yesterday',
      elderId: elder.id,
      title: 'Tarefa de ontem',
      startAt: DateTime(now.year, now.month, now.day - 1, 8),
      endAt: DateTime(now.year, now.month, now.day - 1, 9),
      createdByUserId: elder.id,
      createdByRole: RoutineTaskCreatorRole.elder,
    );
    final tomorrowTask = RoutineTask(
      id: 'task-tomorrow',
      elderId: elder.id,
      title: 'Tarefa de amanhã',
      startAt: DateTime(now.year, now.month, now.day + 1, 8),
      endAt: DateTime(now.year, now.month, now.day + 1, 9),
      createdByUserId: elder.id,
      createdByRole: RoutineTaskCreatorRole.elder,
    );
    final otherWeekdayTask = RoutineTask(
      id: 'task-other-weekday',
      elderId: elder.id,
      title: 'Rotina de outro dia',
      startAt: DateTime(now.year, now.month, now.day - 7, 8),
      endAt: DateTime(now.year, now.month, now.day - 7, 9),
      createdByUserId: elder.id,
      createdByRole: RoutineTaskCreatorRole.elder,
      repeatWeekly: true,
      repeatWeekdays: {
        now.weekday == DateTime.monday ? DateTime.tuesday : DateTime.monday,
      },
    );
    final conversation = ConversationPreview(
      id: 'conversation-1',
      participantId: elder.id,
      participantName: elder.name,
      lastMessage: 'Oi',
      participantType: ConversationParticipantType.elder,
      lastMessageAt: DateTime(now.year, now.month, now.day, 12, 5),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith(_TestCurrentUserNotifier.new),
          accessibleRoutineEldersProvider.overrideWith(
            (_) => Stream.value([elder]),
          ),
          linkedFamilyIdsProvider.overrideWith((_) => Stream.value({elder.id})),
          conversationPreviewsProvider.overrideWith(
            (_) => Stream.value([conversation]),
          ),
          routineTasksProvider(elder.id).overrideWith(
            (_) => Stream.value([
              task,
              secondTask,
              thirdTask,
              yesterdayTask,
              tomorrowTask,
              otherWeekdayTask,
            ]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(const AppSettings()),
          home: const FamilyHomePage(elderId: 'elder-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Alongamento'), findsOneWidget);
    expect(find.text('Medicação'), findsOneWidget);
    expect(find.text('Jantar'), findsOneWidget);
    expect(find.text('Tarefa de ontem'), findsNothing);
    expect(find.text('Tarefa de amanhã'), findsNothing);
    expect(find.text('Rotina de outro dia'), findsNothing);
    expect(find.byIcon(Icons.interests_rounded), findsOneWidget);
    expect(find.byIcon(Icons.restaurant_rounded), findsOneWidget);
    expect(find.byIcon(Icons.medication_rounded), findsOneWidget);
    final firstTaskTile = tester.widget<Container>(
      find.byKey(const ValueKey('family-task-task-1')),
    );
    expect(firstTaskTile.constraints?.minHeight, 120);
    expect(
      (firstTaskTile.decoration! as BoxDecoration).color,
      AppTheme.light(const AppSettings()).colorScheme.surfaceContainerLow,
    );
    expect(find.text('Converse com seu\nparente'), findsOneWidget);
    expect(find.text('Última mensagem'), findsOneWidget);
    expect(find.text('Oi'), findsOneWidget);
    final addFamilyButton = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('family-add-elder-button')),
    );
    final addFamilyButtonRect = tester.getRect(
      find.byKey(const ValueKey('family-add-elder-button')),
    );
    expect(addFamilyButtonRect.width, 280);
    expect(
      addFamilyButton.style?.backgroundColor?.resolve(const <WidgetState>{}),
      AppTheme.light(const AppSettings()).colorScheme.surfaceContainerLow,
    );
    expect(
      addFamilyButton.style?.side?.resolve(const <WidgetState>{})?.style,
      BorderStyle.solid,
    );
    final addFamilyButtonShape = addFamilyButton.style?.shape?.resolve(
      const <WidgetState>{},
    );
    expect(addFamilyButtonShape, isA<RoundedRectangleBorder>());
    expect(
      tester.getRect(find.text('Adicionar Familiar')).center.dx,
      closeTo(tester.view.physicalSize.width / 2, 1),
    );

    final routineCardRect = tester.getRect(
      find.byKey(const ValueKey('family-routine-card')),
    );
    final routineButtonRect = tester.getRect(
      find.widgetWithText(ElevatedButton, 'Ver rotina completa'),
    );
    expect(routineButtonRect.right, greaterThan(routineCardRect.right));
    expect(routineButtonRect.top, lessThan(routineCardRect.bottom));
    expect(routineButtonRect.bottom, greaterThan(routineCardRect.bottom));

    final messageTimeRect = tester.getRect(
      find.byKey(const ValueKey('family-message-time')),
    );
    final messageBubbleRect = tester.getRect(
      find.byKey(const ValueKey('family-message-bubble')),
    );
    final sendButtonRect = tester.getRect(
      find.byKey(const ValueKey('family-message-send-button')),
    );
    expect(messageBubbleRect.width, greaterThan(200));
    expect(addFamilyButtonRect.top, greaterThan(messageBubbleRect.bottom));
    expect(messageTimeRect.right, lessThanOrEqualTo(sendButtonRect.left));
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(2, 2);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(365, 802);
    await tester.pumpAndSettle();
    expect(find.text('Alongamento'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _TestCurrentUserNotifier extends CurrentUserNotifier {
  @override
  Future<UserSession?> build() async => const UserSession(
    uid: 'family-1',
    name: 'Familiar',
    phone: '',
    accountType: AccountType.family,
    institutionId: 'institution-1',
    status: 'active',
  );
}
