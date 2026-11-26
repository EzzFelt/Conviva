import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/models/account_type.dart';
import '../../auth/models/user_session.dart';
import '../../auth/providers/current_user_provider.dart';
import '../../../core/services/push_relay_service.dart';
import '../../../core/utils/family_link_id.dart';
import '../models/chat_message.dart';
import '../models/conversation_preview.dart';

final _firestoreProvider = Provider<FirebaseFirestore>(
  (_) => FirebaseFirestore.instance,
);

final conversationPreviewsProvider = StreamProvider<List<ConversationPreview>>((
  ref,
) async* {
  final session = await ref.watch(currentUserProvider.future);
  if (session == null) {
    yield const <ConversationPreview>[];
    return;
  }

  yield* getChatsStream(
    currentUserId: session.uid,
    institutionId: session.institutionId,
  );
});

final institutionContactsProvider = StreamProvider<List<InstitutionContact>>((
  ref,
) async* {
  final session = await ref.watch(currentUserProvider.future);
  if (session == null) {
    yield const <InstitutionContact>[];
    return;
  }

  yield* getInstitutionContactsStream(
    currentUserId: session.uid,
    institutionId: session.institutionId,
  );
});

final linkedFamilyIdsProvider = StreamProvider<Set<String>>((ref) async* {
  final session = await ref.watch(currentUserProvider.future);
  if (session == null) {
    yield const <String>{};
    return;
  }

  final isElder = session.accountType.name == 'elder';
  final field = isElder ? 'elderId' : 'familiarId';
  final linkedField = isElder ? 'familiarId' : 'elderId';

  yield* FirebaseFirestore.instance
      .collection('familyLinks')
      .where(field, isEqualTo: session.uid)
      .snapshots()
      .map(
        (snapshot) => {
          for (final document in snapshot.docs)
            if (document.data()['institutionId']?.toString() ==
                    session.institutionId &&
                document.data()['status']?.toString() == 'active')
              document.data()[linkedField]?.toString() ?? '',
        }..removeWhere((id) => id.isEmpty),
      );
});

final conversationPreviewProvider =
    FutureProvider.family<ConversationPreview?, String>((
      ref,
      conversationId,
    ) async {
      final session = await ref.watch(currentUserProvider.future);
      if (session == null) return null;

      final firestore = ref.read(_firestoreProvider);
      final document = await firestore
          .collection('chats')
          .doc(conversationId)
          .get();
      if (document.exists) {
        final chatData = document.data()!;
        final preview = _conversationFromDocument(document, session.uid);
        if (chatData['institutionId'] != session.institutionId ||
            preview.participantId.isEmpty) {
          return null;
        }

        final participant = await firestore
            .collection('users')
            .doc(preview.participantId)
            .get();
        final participantData = participant.data();
        if (participantData == null ||
            !await _canChatWith(
              session,
              preview.participantId,
              participantData,
            )) {
          return null;
        }

        final contact = _contactFromDocument(participant);
        return ConversationPreview(
          id: preview.id,
          participantId: contact.uid,
          participantName: contact.name,
          lastMessage: preview.lastMessage,
          participantType: contact.type,
          photoUrl: contact.photoUrl ?? preview.photoUrl,
          lastMessageAt: preview.lastMessageAt,
          unreadCount: preview.unreadCount,
        );
      }

      final participantIds = conversationId.split('_');
      if (participantIds.length != 2 || !participantIds.contains(session.uid)) {
        return null;
      }

      final participantId = participantIds.firstWhere(
        (id) => id != session.uid,
      );
      final participant = await firestore
          .collection('users')
          .doc(participantId)
          .get();
      final participantData = participant.data();
      if (participantData == null ||
          !await _canChatWith(session, participantId, participantData)) {
        return null;
      }

      final contact = _contactFromDocument(participant);
      return ConversationPreview(
        id: conversationId,
        participantId: contact.uid,
        participantName: contact.name,
        lastMessage: '',
        participantType: contact.type,
        photoUrl: contact.photoUrl,
      );
    });

Stream<List<ConversationPreview>> getChatsStream({
  required String currentUserId,
  required String institutionId,
}) {
  final participantPhotoCache = <String, String?>{};

  return FirebaseFirestore.instance
      .collection('chats')
      .where('participants', arrayContains: currentUserId)
      .where('institutionId', isEqualTo: institutionId)
      .orderBy('lastMessageAt', descending: true)
      .snapshots()
      .asyncMap((snapshot) async {
        final conversations = [
          for (final document in snapshot.docs)
            _conversationFromDocument(document, currentUserId),
        ];
        final participantIdsWithoutPhoto = conversations
            .where(
              (conversation) =>
                  conversation.photoUrl?.trim().isNotEmpty != true &&
                  conversation.participantId.isNotEmpty &&
                  !participantPhotoCache.containsKey(
                    conversation.participantId,
                  ),
            )
            .map((conversation) => conversation.participantId)
            .toSet();

        await Future.wait(
          participantIdsWithoutPhoto.map((participantId) async {
            final participant = await FirebaseFirestore.instance
                .collection('users')
                .doc(participantId)
                .get();
            participantPhotoCache[participantId] = participant
                .data()?['photoUrl']
                ?.toString();
          }),
        );

        return [
          for (final conversation in conversations)
            if (conversation.photoUrl?.trim().isNotEmpty == true)
              conversation
            else
              ConversationPreview(
                id: conversation.id,
                participantId: conversation.participantId,
                participantName: conversation.participantName,
                lastMessage: conversation.lastMessage,
                participantType: conversation.participantType,
                photoUrl: participantPhotoCache[conversation.participantId],
                lastMessageAt: conversation.lastMessageAt,
                unreadCount: conversation.unreadCount,
              ),
        ];
      });
}

Stream<List<InstitutionContact>> getInstitutionContactsStream({
  required String currentUserId,
  required String institutionId,
}) {
  return FirebaseFirestore.instance
      .collection('users')
      .where('institutionId', isEqualTo: institutionId)
      .snapshots()
      .map(
        (snapshot) => [
          for (final document in snapshot.docs)
            if (document.id != currentUserId &&
                document.data()['status']?.toString() == 'active')
              _contactFromDocument(document),
        ],
      );
}

Future<bool> _canChatWith(
  UserSession currentUser,
  String recipientId,
  Map<String, dynamic> recipientData,
) async {
  if (recipientData['status']?.toString() != 'active' ||
      recipientData['institutionId']?.toString() != currentUser.institutionId) {
    return false;
  }

  final recipientType = recipientData['type']?.toString();
  switch (currentUser.accountType) {
    case AccountType.caregiver:
      return recipientType == 'idoso' || recipientType == 'caregiver';
    case AccountType.family:
      return recipientType == 'idoso' &&
          await _hasActiveFamilyLink(
            elderId: recipientId,
            familyId: currentUser.uid,
            institutionId: currentUser.institutionId,
          );
    case AccountType.elder:
      if (recipientType == 'caregiver') return true;
      return recipientType == 'family' &&
          await _hasActiveFamilyLink(
            elderId: currentUser.uid,
            familyId: recipientId,
            institutionId: currentUser.institutionId,
          );
    case AccountType.support:
      return false;
  }
}

Future<bool> _hasActiveFamilyLink({
  required String elderId,
  required String familyId,
  required String institutionId,
}) async {
  final linkId = FamilyLinkId.forUsers(elderId: elderId, familyId: familyId);
  final link = await FirebaseFirestore.instance
      .collection('familyLinks')
      .doc(linkId)
      .get();
  final data = link.data();

  return link.exists &&
      data?['status']?.toString() == 'active' &&
      data?['elderId']?.toString() == elderId &&
      data?['familiarId']?.toString() == familyId &&
      data?['institutionId']?.toString() == institutionId;
}

Future<String> getOrCreateChat({
  required UserSession currentUser,
  required String recipientId,
}) async {
  if (currentUser.uid == recipientId) {
    throw ArgumentError('Não é possível iniciar uma conversa consigo mesmo.');
  }

  final ids = [currentUser.uid, recipientId]..sort();
  final chatId = '${ids[0]}_${ids[1]}';
  final reference = FirebaseFirestore.instance.collection('chats').doc(chatId);
  final recipient = await FirebaseFirestore.instance
      .collection('users')
      .doc(recipientId)
      .get();
  final recipientData = recipient.data();
  if (recipientData == null) {
    throw StateError('Destinatário não encontrado.');
  }
  if (!await _canChatWith(currentUser, recipientId, recipientData)) {
    throw StateError('Não há permissão para conversar com este contato.');
  }

  final existing = await reference.get();
  if (existing.exists) return chatId;

  await reference.set({
    'chatId': chatId,
    'institutionId': currentUser.institutionId,
    'participants': ids,
    'participantsData': {
      currentUser.uid: {
        'name': currentUser.name,
        'type': _typeValue(currentUser),
      },
      recipientId: {
        'name': recipientData['name']?.toString() ?? '',
        'type': recipientData['type']?.toString() ?? '',
      },
    },
    'lastMessage': '',
    'lastMessageAt': Timestamp.fromDate(DateTime.fromMillisecondsSinceEpoch(0)),
    'unreadCount': {currentUser.uid: 0, recipientId: 0},
  });
  return chatId;
}

Future<void> sendMessage({
  required UserSession currentUser,
  required String recipientId,
  required String text,
  ChatMessageType type = ChatMessageType.text,
  String? mediaUrl,
}) async {
  final chatId = await getOrCreateChat(
    currentUser: currentUser,
    recipientId: recipientId,
  );
  final chatReference = FirebaseFirestore.instance
      .collection('chats')
      .doc(chatId);
  final messageReference = chatReference.collection('messages').doc();
  final batch = FirebaseFirestore.instance.batch();
  final now = Timestamp.now();

  batch.set(messageReference, {
    'messageId': messageReference.id,
    'senderId': currentUser.uid,
    'text': text,
    'type': _messageTypeValue(type),
    'mediaUrl': ?mediaUrl,
    'createdAt': now,
    'readBy': [currentUser.uid],
  });
  batch.update(chatReference, {
    'lastMessage': text,
    'lastMessageAt': now,
    'unreadCount.$recipientId': FieldValue.increment(1),
  });
  await batch.commit();

  // Avisa o relé gratuito para empurrar o push ao destinatário (app fechado).
  // Não bloqueia nem derruba o envio se falhar.
  unawaited(
    PushRelayService.notifyNewMessage(
      chatId: chatId,
      messageId: messageReference.id,
    ),
  );
}

Future<void> markAsRead({
  required String chatId,
  required String currentUserId,
}) async {
  final firestore = FirebaseFirestore.instance;
  final chatReference = firestore.collection('chats').doc(chatId);
  final chat = await chatReference.get();
  if (!chat.exists) return;
  final messages = await chatReference.collection('messages').get();
  final batch = firestore.batch();
  batch.update(chatReference, {'unreadCount.$currentUserId': 0});
  for (final message in messages.docs) {
    final data = message.data();
    final readBy = List<String>.from(data['readBy'] as List? ?? const []);
    if (!readBy.contains(currentUserId)) {
      batch.update(message.reference, {
        'readBy': FieldValue.arrayUnion([currentUserId]),
      });
    }
  }
  await batch.commit();
}

ConversationPreview _conversationFromDocument(
  DocumentSnapshot<Map<String, dynamic>> document,
  String currentUserId,
) {
  final data = document.data() ?? const <String, dynamic>{};
  final participants = Map<String, dynamic>.from(
    data['participantsData'] as Map? ?? const {},
  );
  final participantId = (data['participants'] as List? ?? const [])
      .map((value) => value.toString())
      .firstWhere((id) => id != currentUserId, orElse: () => '');
  final participantData = Map<String, dynamic>.from(
    participants[participantId] as Map? ?? const {},
  );

  return ConversationPreview(
    id: document.id,
    participantId: participantId,
    participantName: participantData['name']?.toString() ?? 'Contato',
    lastMessage: data['lastMessage']?.toString() ?? '',
    participantType: _participantType(participantData['type']?.toString()),
    photoUrl: participantData['photoUrl']?.toString(),
    lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
    unreadCount:
        ((data['unreadCount'] as Map?)?[currentUserId] as num?)?.toInt() ?? 0,
  );
}

InstitutionContact _contactFromDocument(
  DocumentSnapshot<Map<String, dynamic>> document,
) {
  final data = document.data() ?? const <String, dynamic>{};
  return InstitutionContact(
    uid: document.id,
    name: data['name']?.toString() ?? 'Contato',
    type: _participantType(data['type']?.toString()),
    phone: data['phone']?.toString(),
    photoUrl: data['photoUrl']?.toString(),
  );
}

ConversationParticipantType _participantType(String? type) {
  return switch (type) {
    'caregiver' => ConversationParticipantType.caregiver,
    'family' => ConversationParticipantType.family,
    'idoso' => ConversationParticipantType.elder,
    _ => ConversationParticipantType.staff,
  };
}

String _typeValue(UserSession session) {
  return switch (session.accountType.name) {
    'elder' => 'idoso',
    'caregiver' => 'caregiver',
    'family' => 'family',
    _ => session.accountType.name,
  };
}

String _messageTypeValue(ChatMessageType type) => type.name;
