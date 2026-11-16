import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../shared/utils/first_two_names.dart';
import '../../../shared/widgets/goto_button_widget.dart';
import '../models/conversation_preview.dart';

/// Hora da última mensagem: "14:30" se for hoje, "Ontem" ou "dd/MM".
String conversationTimeLabel(DateTime? date, {DateTime? now}) {
  if (date == null) return '';

  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  final day = DateTime(date.year, date.month, date.day);
  final difference = today.difference(day).inDays;

  if (difference == 0) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  if (difference == 1) return 'Ontem';

  final dayLabel = date.day.toString().padLeft(2, '0');
  final monthLabel = date.month.toString().padLeft(2, '0');
  return '$dayLabel/$monthLabel';
}

/// Ícone que indica quem é a pessoa da conversa.
IconData conversationRoleIcon(ConversationParticipantType type) {
  return switch (type) {
    ConversationParticipantType.family => Icons.groups_rounded,
    ConversationParticipantType.caregiver => Icons.health_and_safety_rounded,
    ConversationParticipantType.elder => Icons.elderly_rounded,
    ConversationParticipantType.staff => Icons.badge_rounded,
  };
}

String conversationRoleLabel(ConversationParticipantType type) {
  return switch (type) {
    ConversationParticipantType.family => 'Familiar',
    ConversationParticipantType.caregiver => 'Cuidador',
    ConversationParticipantType.elder => 'Idoso',
    ConversationParticipantType.staff => 'Equipe',
  };
}

/// Conteúdo dos cards de conversa das homes: nome, ícone do tipo de pessoa,
/// hora da última mensagem e prévia da mensagem.
class ConversationCardContent extends StatelessWidget {
  const ConversationCardContent({
    super.key,
    required this.conversation,
    this.emptyMessage = 'Toque para iniciar uma conversa',
    this.showTimestamp = true,
  });

  final ConversationPreview conversation;
  final String emptyMessage;
  final bool showTimestamp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final time = conversationTimeLabel(conversation.lastMessageAt);
    final message = conversation.lastMessage.trim().isEmpty
        ? emptyMessage
        : conversation.lastMessage;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              flex: 3,
              child: Text(
                firstTwoNames(conversation.participantName),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: sizes.xs),
            Semantics(
              label: conversationRoleLabel(conversation.participantType),
              child: Icon(
                conversationRoleIcon(conversation.participantType),
                size: sizes.icon(sizes.md),
                color: colorScheme.onSurface,
              ),
            ),
            if (showTimestamp && time.isNotEmpty) ...[
              const Spacer(flex: 1),
              SizedBox(width: sizes.xs),
              Text(
                time,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: sizes.xs),
        Text(
          message,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class ConversationCardTrailingWidget extends StatelessWidget {
  const ConversationCardTrailingWidget({
    super.key,
    required this.conversation,
    required this.onPressed,
  });

  final ConversationPreview conversation;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final time = conversationTimeLabel(conversation.lastMessageAt);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (time.isNotEmpty) ...[
          Text(
            time,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(width: sizes.xs),
        ],
        GotoButtonWidget(size: GotoButtonSize.small, onPressed: onPressed),
      ],
    );
  }
}
