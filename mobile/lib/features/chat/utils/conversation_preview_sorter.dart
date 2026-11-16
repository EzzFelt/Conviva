import '../models/conversation_preview.dart';

List<ConversationPreview> sortConversationsByLatestMessage(
  Iterable<ConversationPreview> conversations,
) {
  final sorted = conversations.toList()
    ..sort((first, second) {
      final firstDate = first.lastMessageAt;
      final secondDate = second.lastMessageAt;
      if (firstDate == null) return secondDate == null ? 0 : 1;
      if (secondDate == null) return -1;
      return secondDate.compareTo(firstDate);
    });

  return sorted;
}
