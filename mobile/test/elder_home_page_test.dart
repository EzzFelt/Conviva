import 'package:conviva/core/settings/app_settings.dart';
import 'package:conviva/core/themes/app_theme.dart';
import 'package:conviva/features/auth/models/account_type.dart';
import 'package:conviva/features/auth/models/user_session.dart';
import 'package:conviva/features/auth/providers/current_user_provider.dart';
import 'package:conviva/features/chat/models/conversation_preview.dart';
import 'package:conviva/features/chat/providers/conversation_previews_provider.dart';
import 'package:conviva/features/chat/widgets/conversation_card_content.dart';
import 'package:conviva/features/home/elder/elder_home_page.dart';
import 'package:conviva/features/home/widgets/home_header_widget.dart';
import 'package:conviva/features/home/widgets/next_task_card.dart';
import 'package:conviva/features/routine/providers/next_elder_routine_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  testWidgets('the elder home header and next task scroll with the page', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();

    tester.view.physicalSize = const Size(365, 802);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith(_TestElderNotifier.new),
          nextElderRoutineProvider.overrideWith((_) => Stream.value(null)),
          conversationPreviewsProvider.overrideWith(
            (_) => Stream.value([
              ConversationPreview(
                id: 'old-chat',
                participantId: 'old-contact',
                participantName: 'Contato Antigo',
                lastMessage: 'Mensagem antiga',
                participantType: ConversationParticipantType.caregiver,
                lastMessageAt: DateTime(2026, 1, 1),
              ),
              ConversationPreview(
                id: 'newest-chat',
                participantId: 'newest-contact',
                participantName: 'Contato Primeiro',
                lastMessage: 'Mensagem recente',
                participantType: ConversationParticipantType.caregiver,
                lastMessageAt: DateTime(2026, 1, 4),
              ),
              ConversationPreview(
                id: 'second-chat',
                participantId: 'second-contact',
                participantName: 'Contato Segundo',
                lastMessage: 'Mensagem recente',
                participantType: ConversationParticipantType.caregiver,
                lastMessageAt: DateTime(2026, 1, 3),
              ),
              ConversationPreview(
                id: 'third-chat',
                participantId: 'third-contact',
                participantName: 'Contato Terceiro',
                lastMessage: 'Mensagem recente',
                participantType: ConversationParticipantType.caregiver,
                lastMessageAt: DateTime(2026, 1, 2),
              ),
            ]),
          ),
          linkedFamilyIdsProvider.overrideWith((_) => Stream.value(const {})),
        ],
        child: MaterialApp(
          theme: AppTheme.light(const AppSettings()),
          home: const ElderHomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final nextTaskPanel = tester.widget<Container>(
      find.byKey(const ValueKey('elder-home-next-task-panel')),
    );
    final panelDecoration = nextTaskPanel.decoration! as BoxDecoration;
    expect(
      panelDecoration.borderRadius,
      const BorderRadius.only(
        topLeft: Radius.circular(32),
        topRight: Radius.circular(32),
      ),
    );

    final header = find.byType(HomeHeaderWidget, skipOffstage: false);
    final title = tester.widget<Text>(
      find.descendant(of: header, matching: find.byType(Text)),
    );
    expect(title.textSpan?.toPlainText(), 'Olá, Pessoa idosa');
    expect(find.byType(ConversationCardContent), findsNWidgets(3));
    expect(find.text('Contato Antigo'), findsNothing);
    expect(find.text('Contato Primeiro'), findsOneWidget);
    expect(find.text('Contato Segundo'), findsOneWidget);
    expect(find.text('Contato Terceiro'), findsOneWidget);
    final dateCenter = tester.getCenter(find.text('04/01'));
    final buttonCenter = tester.getCenter(
      find.byIcon(Icons.arrow_forward_ios).first,
    );
    expect(dateCenter.dx, lessThan(buttonCenter.dx));
    expect(buttonCenter.dx - dateCenter.dx, lessThan(80));
    final nextTask = find.byType(NextTaskCard, skipOffstage: false);
    final headerTop = tester.getTopLeft(header).dy;
    final nextTaskTop = tester.getTopLeft(nextTask).dy;

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(header).dy, lessThan(headerTop));
    expect(tester.getTopLeft(nextTask).dy, lessThan(nextTaskTop));
    expect(tester.takeException(), isNull);
  });
}

class _TestElderNotifier extends CurrentUserNotifier {
  @override
  Future<UserSession?> build() async => const UserSession(
    uid: 'elder-1',
    name: 'Pessoa idosa da instituição',
    phone: '',
    accountType: AccountType.elder,
    institutionId: 'institution-1',
    status: 'active',
  );
}
