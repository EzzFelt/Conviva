import 'package:conviva/core/settings/app_settings.dart';
import 'package:conviva/core/themes/app_theme.dart';
import 'package:conviva/features/chat/models/chat_message.dart';
import 'package:conviva/features/chat/models/conversation_preview.dart';
import 'package:conviva/features/chat/utils/chat_timestamp_formatter.dart';
import 'package:conviva/features/chat/widgets/chat_message_bubble_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 1, 8, 18);

  test('family home shows time today and date on previous days', () {
    expect(
      familyHomeMessageTimestampLabel(DateTime(2026, 1, 8, 12, 34), now: now),
      '12:34',
    );
    expect(
      familyHomeMessageTimestampLabel(DateTime(2026, 1, 7, 12, 34), now: now),
      '07/01/2026',
    );
    expect(familyHomeMessageTimestampLabel(null, now: now), isEmpty);
  });

  test('chat timestamps say today or yesterday and include date and time', () {
    expect(
      chatMessageTimestampLabel(DateTime(2026, 1, 8, 12, 34), now: now),
      'Hoje, 12:34',
    );
    expect(
      chatMessageTimestampLabel(DateTime(2026, 1, 7, 12, 34), now: now),
      'Ontem, 12:34',
    );
    expect(
      chatMessageTimestampLabel(DateTime(2026, 1, 6, 12, 34), now: now),
      '06/01/2026, 12:34',
    );
  });

  testWidgets('message bubble displays its sent date and time', (tester) async {
    final today = DateTime.now();
    final message = ChatMessage(
      id: 'message-today',
      conversationId: 'conversation-1',
      senderId: 'family-1',
      sentAt: DateTime(today.year, today.month, today.day, 9, 17),
      text: 'Bom dia',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(const AppSettings()),
        home: Scaffold(
          body: ChatMessageBubbleWidget(
            message: message,
            isCurrentUser: true,
            participantType: ConversationParticipantType.elder,
          ),
        ),
      ),
    );

    expect(find.text('Bom dia'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('chat-message-timestamp-message-today')),
      findsOneWidget,
    );
    expect(find.text('Hoje, 09:17'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
