import 'package:flutter/material.dart';
import 'package:conviva/shared/utils/profile_image.dart';
import 'package:conviva/shared/utils/first_two_names.dart';

import 'package:conviva/core/constants/app_sizes.dart';
import '../../notifications/widgets/notification_center_button_widget.dart';

class HomeHeaderWidget extends StatelessWidget {
  const HomeHeaderWidget({
    super.key,
    required this.name,
    this.greeting = 'Olá,',
    this.subtitle,
    this.photoUrl,
    this.avatar,
  }) : assert(
         photoUrl == null || avatar == null,
         'Informe photoUrl ou avatar, mas não os dois.',
       );

  final String name;
  final String greeting;
  final String? subtitle;
  final String? photoUrl;
  final Widget? avatar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final normalizedPhotoUrl = photoUrl?.trim();
    final displayName = firstTwoNames(name);
    final hasPhoto =
        normalizedPhotoUrl != null && normalizedPhotoUrl.isNotEmpty;
    final titleStyle = theme.textTheme.titleLarge?.copyWith(
      color: colorScheme.onPrimary,
      fontWeight: FontWeight.w400,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(sizes.lg, sizes.xl, sizes.lg, sizes.xl),
      child: Row(
        children: [
          CircleAvatar(
            radius: sizes.xxl / 1.5,
            backgroundColor: colorScheme.surface,
            foregroundImage: hasPhoto
                ? profileImageProvider(normalizedPhotoUrl)
                : null,
            child:
                avatar ??
                Icon(
                  Icons.person_rounded,
                  color: colorScheme.primary,
                  size: sizes.icon(sizes.xxl),
                ),
          ),
          SizedBox(width: sizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text.rich(
                  TextSpan(
                    style: titleStyle,
                    children: [
                      TextSpan(text: '$greeting '),
                      TextSpan(
                        text: displayName,
                        style: titleStyle?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  SizedBox(height: sizes.xs),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: sizes.sm),
          const NotificationCenterButtonWidget(),
        ],
      ),
    );
  }
}
