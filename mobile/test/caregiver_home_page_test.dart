import 'package:conviva/core/settings/app_settings.dart';
import 'package:conviva/core/themes/app_theme.dart';
import 'package:conviva/features/auth/models/account_type.dart';
import 'package:conviva/features/auth/models/user_session.dart';
import 'package:conviva/features/auth/providers/current_user_provider.dart';
import 'package:conviva/features/chat/models/conversation_preview.dart';
import 'package:conviva/features/chat/providers/conversation_previews_provider.dart';
import 'package:conviva/features/chat/widgets/conversation_card_content.dart';
import 'package:conviva/features/home/caregiver/caregiver_home_page.dart';
import 'package:conviva/features/home/widgets/home_header_widget.dart';
import 'package:conviva/features/routine/models/routine_elder_summary.dart';
import 'package:conviva/features/routine/models/routine_task.dart';
import 'package:conviva/features/routine/models/routine_task_completion.dart';
import 'package:conviva/features/routine/providers/routine_provider.dart';
import 'package:conviva/shared/widgets/info_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders caregiver home on a phone without layout errors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(365, 802);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith(_TestCaregiverNotifier.new),
          accessibleRoutineEldersProvider.overrideWith(
            (_) => Stream.value(const [
              RoutineElderSummary(
                id: 'elder-1',
                name: 'Adalberto Emanuel',
                phone: '',
                institutionId: 'institution-1',
              ),
            ]),
          ),
          routineTasksProvider.overrideWith(
            (_, _) => Stream.value(const <RoutineTask>[]),
          ),
          routineCompletionsProvider.overrideWith(
            (_, _) => Stream.value(const <RoutineTaskCompletion>[]),
          ),
          conversationPreviewsProvider.overrideWith(
            (_) => Stream.value(const <ConversationPreview>[]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(const AppSettings()),
          home: const CaregiverHomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Chat - Converse'), findsOneWidget);
    expect(find.text('Residentes sob cuidado'), findsOneWidget);
    expect(find.text('Adalberto Emanuel'), findsWidgets);
    expect(find.text('Não possui tarefas na rotina.'), findsOneWidget);
    expect(find.textContaining('1 pendência'), findsOneWidget);
    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the three most recently messaged chat contacts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(365, 802);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith(_TestCaregiverNotifier.new),
          accessibleRoutineEldersProvider.overrideWith(
            (_) => Stream.value(const [
              RoutineElderSummary(
                id: 'elder-1',
                name: 'Residente Um',
                phone: '',
                institutionId: 'institution-1',
              ),
              RoutineElderSummary(
                id: 'elder-2',
                name: 'Residente Dois',
                phone: '',
                institutionId: 'institution-1',
              ),
              RoutineElderSummary(
                id: 'elder-3',
                name: 'Residente Três',
                phone: '',
                institutionId: 'institution-1',
              ),
              RoutineElderSummary(
                id: 'elder-4',
                name: 'Residente Quatro',
                phone: '',
                institutionId: 'institution-1',
              ),
            ]),
          ),
          routineTasksProvider.overrideWith(
            (_, _) => Stream.value(const <RoutineTask>[]),
          ),
          routineCompletionsProvider.overrideWith(
            (_, _) => Stream.value(const <RoutineTaskCompletion>[]),
          ),
          conversationPreviewsProvider.overrideWith(
            (_) => Stream.value([
              ConversationPreview(
                id: 'old-chat',
                participantId: 'old-contact',
                participantName: 'Contato Antigo',
                lastMessage: 'Mensagem antiga',
                participantType: ConversationParticipantType.elder,
                lastMessageAt: DateTime(2026, 1, 1),
              ),
              ConversationPreview(
                id: 'third-chat',
                participantId: 'third-contact',
                participantName: 'Contato Terceiro',
                lastMessage: 'Mensagem recente',
                participantType: ConversationParticipantType.elder,
                lastMessageAt: DateTime(2026, 1, 2),
              ),
              ConversationPreview(
                id: 'newest-chat',
                participantId: 'newest-contact',
                participantName: 'Contato Primeiro',
                lastMessage: 'Mensagem recente',
                participantType: ConversationParticipantType.elder,
                lastMessageAt: DateTime(2026, 1, 4),
              ),
              ConversationPreview(
                id: 'second-chat',
                participantId: 'second-contact',
                participantName: 'Contato Segundo',
                lastMessage: 'Mensagem recente',
                participantType: ConversationParticipantType.elder,
                lastMessageAt: DateTime(2026, 1, 3),
              ),
            ]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(const AppSettings()),
          home: const CaregiverHomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ConversationCardContent), findsNWidgets(3));
    expect(find.text('Contato Primeiro'), findsOneWidget);
    expect(find.text('Contato Segundo'), findsOneWidget);
    expect(find.text('Contato Terceiro'), findsOneWidget);
    expect(find.text('Contato Antigo'), findsNothing);
    final homeContentScrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.byType(Scrollable),
      ),
    );
    expect(homeContentScrollable.position.maxScrollExtent, greaterThan(0));

    final header = find.byType(HomeHeaderWidget);
    final chatTitle = find.text('Chat - Converse');
    final initialOffset =
        tester.getTopLeft(chatTitle).dy - tester.getTopLeft(header).dy;
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -100));
    await tester.pumpAndSettle();
    final scrolledOffset =
        tester.getTopLeft(chatTitle).dy - tester.getTopLeft(header).dy;
    expect(scrolledOffset, closeTo(initialOffset, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps a gap between a pending task and an elder without tasks', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(365, 802);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith(_TestCaregiverNotifier.new),
          accessibleRoutineEldersProvider.overrideWith(
            (_) => Stream.value(const [
              RoutineElderSummary(
                id: 'elder-1',
                name: 'Residente com tarefa',
                phone: '',
                institutionId: 'institution-1',
              ),
              RoutineElderSummary(
                id: 'elder-2',
                name: 'Residente sem tarefa',
                phone: '',
                institutionId: 'institution-1',
              ),
            ]),
          ),
          routineTasksProvider.overrideWith((_, elderId) {
            if (elderId == 'elder-1') {
              return Stream.value([
                RoutineTask(
                  id: 'task-1',
                  elderId: elderId,
                  title: 'Tarefa pendente',
                  startAt: RoutineTask.dateOnly(now),
                  endAt: RoutineTask.dateOnly(now).add(
                    const Duration(hours: 1),
                  ),
                  createdByUserId: 'caregiver-1',
                  createdByRole: RoutineTaskCreatorRole.caregiver,
                ),
              ]);
            }
            return Stream.value(const <RoutineTask>[]);
          }),
          routineCompletionsProvider.overrideWith(
            (_, _) => Stream.value(const <RoutineTaskCompletion>[]),
          ),
          conversationPreviewsProvider.overrideWith(
            (_) => Stream.value(const <ConversationPreview>[]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(const AppSettings()),
          home: const CaregiverHomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final taskCard = find.ancestor(
      of: find.text('Tarefa pendente'),
      matching: find.byType(InfoCardWidget),
    );
    final elderCard = find.ancestor(
      of: find.text('Residente sem tarefa'),
      matching: find.byType(InfoCardWidget),
    );
    expect(
      tester.getTopLeft(elderCard).dy,
      greaterThan(tester.getBottomLeft(taskCard).dy),
    );
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
