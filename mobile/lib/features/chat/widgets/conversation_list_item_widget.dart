import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../models/conversation_preview.dart';
import 'chat_avatar_widget.dart';

class ConversationListItemWidget extends StatelessWidget {
  const ConversationListItemWidget({
    super.key,
    required this.conversation,
    required this.onPressed,
  });

  final ConversationPreview conversation;
  final VoidCallback onPressed;

  String _timeLabel() {
    final date = conversation.lastMessageAt;
    if (date == null) return '';

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;

    return Semantics(
      button: true,
      label: 'Abrir conversa com ${conversation.participantName}',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(sizes.radiusMd),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: sizes.sm,
              vertical: sizes.md,
            ),
            child: Row(
              children: [
                ChatAvatarWidget(
                  participantType: conversation.participantType,
                  photoUrl: conversation.photoUrl,
                  unreadCount: conversation.unreadCount,
                  size: sizes.xxl,
                ),
                SizedBox(width: sizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversation.participantName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge,
                      ),
                      SizedBox(height: sizes.xs),
                      Text(
                        conversation.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: sizes.sm),
                Text(
                  _timeLabel(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
