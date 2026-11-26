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
    required this.participantId,
    required this.participantName,
    required this.lastMessage,
    required this.participantType,
    this.photoUrl,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  final String id;
  final String participantId;
  final String participantName;
  final String lastMessage;
  final ConversationParticipantType participantType;
  final String? photoUrl;
  final DateTime? lastMessageAt;
  final int unreadCount;
}

@immutable
class InstitutionContact {
  const InstitutionContact({
    required this.uid,
    required this.name,
    required this.type,
    this.phone,
    this.photoUrl,
  });

  final String uid;
  final String name;
  final ConversationParticipantType type;
  final String? phone;
  final String? photoUrl;
}
