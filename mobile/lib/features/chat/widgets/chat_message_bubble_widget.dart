import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../models/chat_message.dart';
import '../models/conversation_preview.dart';
import 'chat_avatar_widget.dart';

class ChatMessageBubbleWidget extends StatelessWidget {
  const ChatMessageBubbleWidget({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.participantType,
    this.participantPhotoUrl,
  });

  final ChatMessage message;
  final bool isCurrentUser;
  final ConversationParticipantType participantType;
  final String? participantPhotoUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final bubbleColor = isCurrentUser
        ? colorScheme.primary
        : theme.scaffoldBackgroundColor;
    final textColor = isCurrentUser
        ? colorScheme.onPrimary
        : colorScheme.onSurface;

    return Align(
      alignment: isCurrentUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(bottom: sizes.sm),
        child: Row(
          mainAxisAlignment: isCurrentUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isCurrentUser) ...[
              ChatAvatarWidget(
                participantType: participantType,
                photoUrl: participantPhotoUrl,
                size: sizes.lg,
              ),
              SizedBox(width: sizes.sm),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * .72,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: sizes.md,
                  vertical: sizes.sm,
                ),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(sizes.radiusMd),
                ),
                child: Text(
                  message.text,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: textColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
