import 'package:flutter/material.dart';

import 'package:conviva/core/constants/app_sizes.dart';
import 'package:conviva/shared/widgets/notification_button_widget.dart';

class HomeHeaderWidget extends StatelessWidget {
  const HomeHeaderWidget({
    super.key,
    required this.name,
    required this.onNotificationsPressed,
    this.greeting = 'Olá,',
    this.photoUrl,
    this.avatar,
    this.notificationCount = 0,
  }) : assert(
          photoUrl == null || avatar == null,
          'Informe photoUrl ou avatar, mas não os dois.',
        );

  final String name;
  final String greeting;
  final String? photoUrl;
  final Widget? avatar;
  final int notificationCount;
  final VoidCallback onNotificationsPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final normalizedPhotoUrl = photoUrl?.trim();
    final hasPhoto = normalizedPhotoUrl != null &&
        normalizedPhotoUrl.isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        sizes.lg,
        sizes.xxl,
        sizes.lg,
        sizes.xl + sizes.sm,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: (sizes.xxl + sizes.lg) / 2,
            backgroundColor: colorScheme.surface,
            foregroundImage: hasPhoto
                ? NetworkImage(normalizedPhotoUrl)
                : null,
            child: avatar ??
                Icon(
                  Icons.person_rounded,
                  color: colorScheme.primary,
                  size: sizes.xxl,
                ),
          ),
          SizedBox(width: sizes.md),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w400,
                ),
                children: [
                  TextSpan(text: '$greeting '),
                  TextSpan(
                    text: name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: sizes.sm),
          NotificationButtonWidget(
            notificationCount: notificationCount,
            onPressed: onNotificationsPressed,
          ),
        ],
      ),
    );
  }
}