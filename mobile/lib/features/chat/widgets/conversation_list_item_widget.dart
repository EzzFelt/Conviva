import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../shared/utils/first_two_names.dart';
import '../../../shared/widgets/goto_button_widget.dart';
import '../models/conversation_preview.dart';
import 'chat_avatar_widget.dart';
import 'conversation_card_content.dart';

class ConversationListItemWidget extends StatelessWidget {
  const ConversationListItemWidget({
    super.key,
    required this.conversation,
    required this.onPressed,
  });

  final ConversationPreview conversation;
  final VoidCallback onPressed;

  String _timeLabel() => conversationTimeLabel(conversation.lastMessageAt);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final borderRadius = BorderRadius.circular(sizes.radiusFull);
    final time = _timeLabel();

    return Semantics(
      button: true,
      label:
          'Abrir conversa com ${firstTwoNames(conversation.participantName)}',
      excludeSemantics: true,
      child: Material(
        color: colorScheme.surface,
        elevation: sizes.xs / 2,
        shadowColor: colorScheme.shadow.withValues(alpha: .18),
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: sizes.md,
              vertical: sizes.sm + sizes.xs,
            ),
            child: Row(
              children: [
                ChatAvatarWidget(
                  participantType: conversation.participantType,
                  photoUrl: conversation.photoUrl,
                  unreadCount: conversation.unreadCount,
                  size: sizes.icon(sizes.xxl),
                ),
                SizedBox(width: sizes.md),
                Expanded(
                  child: Column(
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
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(width: sizes.xs),
                          Icon(
                            conversationRoleIcon(conversation.participantType),
                            size: sizes.icon(sizes.md),
                            color: colorScheme.onSurface,
                          ),
                        ],
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
                if (time.isNotEmpty) ...[
                  Text(
                    time,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(width: sizes.xs),
                ],
                GotoButtonWidget(size: GotoButtonSize.small),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
