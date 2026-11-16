import 'package:conviva/core/settings/app_settings.dart';
import 'package:conviva/core/themes/app_theme.dart';
import 'package:conviva/features/auth/models/account_type.dart';
import 'package:conviva/features/auth/models/user_session.dart';
import 'package:conviva/features/auth/providers/current_user_provider.dart';
import 'package:conviva/features/chat/models/conversation_preview.dart';
import 'package:conviva/features/chat/pages/chat_page.dart';
import 'package:conviva/features/chat/providers/conversation_previews_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('caregivers can list institution elders or caregivers only', (
    tester,
  ) async {
    final contacts = [
      const InstitutionContact(
        uid: 'elder-1',
        name: 'Idoso da instituição',
        type: ConversationParticipantType.elder,
      ),
      const InstitutionContact(
        uid: 'caregiver-2',
        name: 'Cuidador da instituição',
        type: ConversationParticipantType.caregiver,
      ),
      const InstitutionContact(
        uid: 'family-1',
        name: 'Familiar da instituição',
        type: ConversationParticipantType.family,
      ),
      const InstitutionContact(
        uid: 'staff-1',
        name: 'Outro perfil',
        type: ConversationParticipantType.staff,
      ),
    ];

    await _pumpChat(
      tester,
      accountType: AccountType.caregiver,
      contacts: contacts,
    );

    expect(find.text('Idoso da'), findsOneWidget);
    expect(find.text('Cuidador da'), findsNothing);
    expect(find.text('Familiar da instituição'), findsNothing);
    expect(find.text('Outro perfil'), findsNothing);

    await tester.tap(find.text('Cuidadores'));
    await tester.pumpAndSettle();

    expect(find.text('Cuidador da'), findsOneWidget);
    expect(find.text('Idoso da'), findsNothing);
    expect(find.text('Familiar da instituição'), findsNothing);
    expect(find.text('Outro perfil'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('elders see the larger name style with the family filter', (
    tester,
  ) async {
    await _pumpChat(
      tester,
      accountType: AccountType.elder,
      contacts: const [
        InstitutionContact(
          uid: 'caregiver-1',
          name: 'Cuidador da instituição',
          type: ConversationParticipantType.caregiver,
        ),
        InstitutionContact(
          uid: 'family-1',
          name: 'Familiar da instituição',
          type: ConversationParticipantType.family,
        ),
      ],
      linkedFamilyIds: const {'family-1'},
    );

    await tester.tap(find.text('Familiar'));
    await tester.pumpAndSettle();

    expect(find.text('Familiar da'), findsOneWidget);
    final name = tester.widget<Text>(find.text('Familiar da'));
    expect(
      name.style?.fontSize,
      AppTheme.light(const AppSettings()).textTheme.titleSmall?.fontSize,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('family members can see only linked elders', (tester) async {
    await _pumpChat(
      tester,
      accountType: AccountType.family,
      contacts: const [
        InstitutionContact(
          uid: 'elder-linked',
          name: 'Idoso vinculado',
          type: ConversationParticipantType.elder,
        ),
        InstitutionContact(
          uid: 'elder-unlinked',
          name: 'Idoso não vinculado',
          type: ConversationParticipantType.elder,
        ),
        InstitutionContact(
          uid: 'caregiver',
          name: 'Cuidador',
          type: ConversationParticipantType.caregiver,
        ),
      ],
      linkedFamilyIds: const {'elder-linked'},
      conversations: const [
        ConversationPreview(
          id: 'existing-unlinked-chat',
          participantId: 'elder-unlinked',
          participantName: 'Conversa com idoso sem vínculo',
          lastMessage: 'Mensagem antiga',
          participantType: ConversationParticipantType.elder,
        ),
        ConversationPreview(
          id: 'existing-caregiver-chat',
          participantId: 'caregiver',
          participantName: 'Conversa com cuidador',
          lastMessage: 'Mensagem antiga',
          participantType: ConversationParticipantType.caregiver,
        ),
      ],
    );

    expect(find.text('Idoso vinculado'), findsOneWidget);
    expect(find.text('Idoso não vinculado'), findsNothing);
    expect(find.text('Cuidador'), findsNothing);
    expect(find.text('Conversa com idoso sem vínculo'), findsNothing);
    expect(find.text('Conversa com cuidador'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpChat(
  WidgetTester tester, {
  required AccountType accountType,
  required List<InstitutionContact> contacts,
  Set<String> linkedFamilyIds = const {},
  List<ConversationPreview> conversations = const [],
}) async {
  tester.view.physicalSize = const Size(365, 802);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWith(
          () => _TestCurrentUserNotifier(accountType),
        ),
        conversationPreviewsProvider.overrideWith(
          (_) => Stream.value(conversations),
        ),
        institutionContactsProvider.overrideWith((_) => Stream.value(contacts)),
        linkedFamilyIdsProvider.overrideWith(
          (_) => Stream.value(linkedFamilyIds),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(const AppSettings()),
        home: const ChatPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _TestCurrentUserNotifier extends CurrentUserNotifier {
  _TestCurrentUserNotifier(this.accountType);

  final AccountType accountType;

  @override
  Future<UserSession?> build() async => UserSession(
    uid: 'current-user',
    name: 'Usuário',
    phone: '',
    accountType: accountType,
    institutionId: 'institution-1',
    status: 'active',
  );
}
