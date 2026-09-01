import 'package:flutter/foundation.dart';

enum ConversationParticipantType {
  family,
  caregiver,
  elder,
  staff,
}

@immutable
class ConversationPreview {
  const ConversationPreview({
    required this.id,
    required this.participantName,
    required this.lastMessage,
    required this.participantType,
    this.photoUrl,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  final String id;
  final String participantName;
  final String lastMessage;
  final ConversationParticipantType participantType;
  final String? photoUrl;
  final DateTime? lastMessageAt;
  final int unreadCount;
}
