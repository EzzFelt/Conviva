import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/current_user_provider.dart';
import '../models/conversation_preview.dart';

final conversationPreviewsProvider =
    FutureProvider<List<ConversationPreview>>((ref) async {
  final session = await ref.watch(currentUserProvider.future);

  if (session == null) {
    return const [];
  }

  // Ponto de integração com o repositório de conversas do usuário atual.
  return const [];
});
