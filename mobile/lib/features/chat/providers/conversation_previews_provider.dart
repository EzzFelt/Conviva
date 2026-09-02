import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/models/account_type.dart';
import '../../auth/models/user_session.dart';
import '../../auth/providers/current_user_provider.dart';
import '../models/conversation_preview.dart';

final conversationPreviewsProvider =
    FutureProvider<List<ConversationPreview>>((ref) async {
  final session = await ref.watch(currentUserProvider.future);

  if (session == null) {
    return const [];
  }

  // Dados temporários para validar somente o front-end. Quando o repositório
  // do chat for conectado, ele deverá retornar apenas vínculos ativos:
  // idoso <-> familiar e idoso <-> cuidador.
  return _demoConversationsFor(session);
});

final conversationPreviewProvider =
    FutureProvider.family<ConversationPreview?, String>(
  (ref, conversationId) async {
    final conversations = await ref.watch(
      conversationPreviewsProvider.future,
    );

    for (final conversation in conversations) {
      if (conversation.id == conversationId) {
        return conversation;
      }
    }

    return null;
  },
);

List<ConversationPreview> _demoConversationsFor(UserSession session) {
  final now = DateTime.now();

  return switch (session.accountType) {
    AccountType.elder => [
        ConversationPreview(
          id: 'elder-caregiver-demo',
          participantId: 'caregiver-demo',
          participantName: 'Isabelle Guimarães',
          lastMessage: 'Opa, tudo bem?',
          participantType: ConversationParticipantType.caregiver,
          lastMessageAt: now.subtract(const Duration(minutes: 8)),
          unreadCount: 1,
        ),
        ConversationPreview(
          id: 'elder-family-demo',
          participantId: 'family-demo',
          participantName: 'Enzo Oliveira',
          lastMessage: 'Oi, estou bem e você?',
          participantType: ConversationParticipantType.family,
          lastMessageAt: now.subtract(const Duration(minutes: 18)),
          unreadCount: 1,
        ),
      ],
    AccountType.family => [
        ConversationPreview(
          id: 'family-elder-demo',
          participantId: 'elder-demo',
          participantName: 'Julia Adair',
          lastMessage: 'Está tudo bem por aqui.',
          participantType: ConversationParticipantType.elder,
          lastMessageAt: now.subtract(const Duration(minutes: 12)),
        ),
      ],
    AccountType.caregiver => [
        ConversationPreview(
          id: 'caregiver-elder-demo',
          participantId: 'elder-demo',
          participantName: 'Julia Adair',
          lastMessage: 'Obrigada pela ajuda!',
          participantType: ConversationParticipantType.elder,
          lastMessageAt: now.subtract(const Duration(minutes: 5)),
          unreadCount: 1,
        ),
      ],
  };
}
