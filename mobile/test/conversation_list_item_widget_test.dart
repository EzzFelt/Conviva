import 'package:conviva/core/settings/app_settings.dart';
import 'package:conviva/core/themes/app_theme.dart';
import 'package:conviva/features/chat/models/conversation_preview.dart';
import 'package:conviva/features/chat/widgets/conversation_card_content.dart';
import 'package:conviva/features/chat/widgets/conversation_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows participant photo and the redesigned conversation card', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(365, 802);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final today = DateTime.now();
    final conversation = ConversationPreview(
      id: 'conversation-1',
      participantId: 'family-1',
      participantName: 'Isabelle Guimarães Silva',
      lastMessage: 'Bom dia, como você está se sentindo?',
      participantType: ConversationParticipantType.family,
      photoUrl:
          'data:image/png;base64,'
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      lastMessageAt: DateTime(today.year, today.month, today.day, 12, 30),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(const AppSettings()),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ConversationListItemWidget(
              conversation: conversation,
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatar.foregroundImage, isA<MemoryImage>());
    expect(avatar.child, isNull);
    expect(find.text('Isabelle Guimarães'), findsOneWidget);
    expect(find.text('Isabelle Guimarães Silva'), findsNothing);
    final name = tester.widget<Text>(find.text('Isabelle Guimarães'));
    expect(
      name.style?.fontSize,
      AppTheme.light(const AppSettings()).textTheme.titleMedium?.fontSize,
    );
    expect(name.style?.fontWeight, FontWeight.w600);
    expect(find.text('Bom dia, como você está se sentindo?'), findsOneWidget);
    expect(find.text('12:30'), findsOneWidget);
    expect(
      tester.getCenter(find.text('12:30')).dx,
      lessThan(tester.getCenter(find.byIcon(Icons.arrow_forward_ios)).dx),
    );
    expect(find.byIcon(Icons.groups_rounded), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses the larger name style in home conversation cards', (
    tester,
  ) async {
    final conversation = ConversationPreview(
      id: 'conversation-card',
      participantId: 'elder-1',
      participantName: 'Isabelle Guimarães Silva',
      lastMessage: '',
      participantType: ConversationParticipantType.elder,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(const AppSettings()),
        home: Scaffold(
          body: ConversationCardContent(conversation: conversation),
        ),
      ),
    );

    final name = tester.widget<Text>(find.text('Isabelle Guimarães'));
    expect(
      name.style?.fontSize,
      AppTheme.light(const AppSettings()).textTheme.bodySmall?.fontSize,
    );
    expect(name.style?.fontWeight, FontWeight.w600);
    expect(tester.takeException(), isNull);
  });

  test('uses the existing family icon and caregiver fallback icon', () {
    expect(
      conversationRoleIcon(ConversationParticipantType.family),
      Icons.groups_rounded,
    );
    expect(
      conversationRoleIcon(ConversationParticipantType.caregiver),
      Icons.health_and_safety_rounded,
    );
  });
}
