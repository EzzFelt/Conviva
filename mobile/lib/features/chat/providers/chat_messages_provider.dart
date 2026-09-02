import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/current_user_provider.dart';
import '../models/chat_message.dart';
import '../models/conversation_preview.dart';
import 'conversation_previews_provider.dart';

final chatMessagesProvider =
    FutureProvider.family<List<ChatMessage>, String>(
  (ref, conversationId) async {
    final session = await ref.watch(currentUserProvider.future);
    final conversation = await ref.watch(
      conversationPreviewProvider(conversationId).future,
    );

    if (session == null || conversation == null) {
      return const <ChatMessage>[];
    }

    final today = DateTime.now();
    final baseTime = DateTime(
      today.year,
      today.month,
      today.day,
      9,
      41,
    );

    if (conversation.participantType ==
        ConversationParticipantType.caregiver) {
      return [
        ChatMessage(
          id: 'message-1',
          conversationId: conversationId,
          senderId: conversation.participantId,
          sentAt: baseTime,
          text: 'Blz',
        ),
        ChatMessage(
          id: 'message-2',
          conversationId: conversationId,
          senderId: conversation.participantId,
          sentAt: baseTime.add(const Duration(minutes: 1)),
          text: 'Como que está funcionando a medicação dele?',
        ),
        ChatMessage(
          id: 'message-3',
          conversationId: conversationId,
          senderId: session.uid,
          sentAt: baseTime.add(const Duration(minutes: 3)),
          text: 'Atualmente ele está tomando clonazepam para dormir e, '
              'na parte da manhã, toma os remédios indicados na rotina.',
        ),
        ChatMessage(
          id: 'message-4',
          conversationId: conversationId,
          senderId: session.uid,
          sentAt: baseTime.add(const Duration(minutes: 4)),
          text: 'Entendeu?',
        ),
        ChatMessage(
          id: 'message-5',
          conversationId: conversationId,
          senderId: conversation.participantId,
          sentAt: baseTime.add(const Duration(minutes: 5)),
          text: 'Acho que eu entendi.',
        ),
      ];
    }

    return [
      ChatMessage(
        id: 'message-1',
        conversationId: conversationId,
        senderId: conversation.participantId,
        sentAt: baseTime,
        text: 'Oi, tudo bem?',
      ),
      ChatMessage(
        id: 'message-2',
        conversationId: conversationId,
        senderId: session.uid,
        sentAt: baseTime.add(const Duration(minutes: 2)),
        text: 'Oi, estou bem e você?',
      ),
    ];
  },
);
