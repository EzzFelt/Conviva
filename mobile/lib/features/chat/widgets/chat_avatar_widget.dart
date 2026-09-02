import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../models/conversation_preview.dart';

class ChatAvatarWidget extends StatelessWidget {
  const ChatAvatarWidget({
    super.key,
    required this.participantType,
    this.photoUrl,
    this.unreadCount = 0,
    this.size,
  });

  final ConversationParticipantType participantType;
  final String? photoUrl;
  final int unreadCount;
  final double? size;

  IconData _fallbackIcon() {
    return switch (participantType) {
      ConversationParticipantType.family => Icons.family_restroom_rounded,
      ConversationParticipantType.caregiver =>
        Icons.health_and_safety_rounded,
      ConversationParticipantType.elder => Icons.elderly_rounded,
      ConversationParticipantType.staff => Icons.badge_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sizes = context.appSizes;
    final dimension = size ?? sizes.xxl;
    final normalizedPhotoUrl = photoUrl?.trim();
    final hasPhoto = normalizedPhotoUrl != null &&
        normalizedPhotoUrl.isNotEmpty;

    return SizedBox.square(
      dimension: dimension + sizes.xs,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CircleAvatar(
              backgroundColor: colorScheme.primary.withValues(alpha: .12),
              foregroundImage: hasPhoto
                  ? NetworkImage(normalizedPhotoUrl)
                  : null,
              child: hasPhoto
                  ? null
                  : Icon(
                      _fallbackIcon(),
                      color: colorScheme.primary,
                      size: sizes.icon(dimension * .52),
                    ),
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              right: -sizes.xs,
              bottom: -sizes.xs,
              child: Container(
                constraints: BoxConstraints(
                  minWidth: sizes.lg,
                  minHeight: sizes.lg,
                ),
                padding: EdgeInsets.symmetric(horizontal: sizes.xs),
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  unreadCount > 9 ? '9+' : '$unreadCount',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onError,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
