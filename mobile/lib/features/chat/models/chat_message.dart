import 'package:flutter/foundation.dart';

enum ChatMessageType {
  text,
  image,
  audio,
}

@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.sentAt,
    required this.text,
    this.type = ChatMessageType.text,
    this.attachmentUrl,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final DateTime sentAt;
  final String text;
  final ChatMessageType type;
  final String? attachmentUrl;

  bool isFrom(String userId) => senderId == userId;
}
