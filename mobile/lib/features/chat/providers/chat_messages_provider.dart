import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/current_user_provider.dart';
import '../models/chat_message.dart';

final chatMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, conversationId) async* {
  final session = await ref.watch(currentUserProvider.future);
  if (session == null) {
    yield const <ChatMessage>[];
    return;
  }

  yield* FirebaseFirestore.instance
      .collection('chats')
      .doc(conversationId)
      .collection('messages')
      .orderBy('createdAt')
      .snapshots()
      .map((snapshot) => [
            for (final document in snapshot.docs)
              _messageFromDocument(document, conversationId),
          ]);
});

ChatMessage _messageFromDocument(
  QueryDocumentSnapshot<Map<String, dynamic>> document,
  String conversationId,
) {
  final data = document.data();
  return ChatMessage(
    id: data['messageId']?.toString() ?? document.id,
    conversationId: conversationId,
    senderId: data['senderId']?.toString() ?? '',
    sentAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    text: data['text']?.toString() ?? '',
    type: switch (data['type']?.toString()) {
      'image' => ChatMessageType.image,
      'audio' => ChatMessageType.audio,
      _ => ChatMessageType.text,
    },
    readBy: List<String>.from(data['readBy'] as List? ?? const []),
  );
}
