import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';

class ElderHomeHeader extends StatelessWidget {
  const ElderHomeHeader({
    super.key,
    required this.name,
    required this.avatar,
    required this.onNotificationsPressed,
    this.notificationCount = 0,
  });

  final String name;
  final Widget avatar;
  final VoidCallback onNotificationsPressed;
  final int notificationCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final notificationLabel = switch (notificationCount) {
      0 => 'Notificações',
      1 => '1 nova notificação',
      _ => '$notificationCount novas notificações',
    };
    final greetingStyle = theme.textTheme.bodyLarge?.copyWith(
      color: colorScheme.onPrimary,
      fontSize: theme.textTheme.titleLarge?.fontSize,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        sizes.lg,
        sizes.xxl,
        sizes.lg,
        sizes.xl + sizes.sm,
      ),
      child: Row(
        children: [
          Container(
            width: sizes.xxl + sizes.lg,
            height: sizes.xxl + sizes.lg,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.surface,
                width: sizes.xs / 2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: avatar,
          ),
          SizedBox(width: sizes.md),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: greetingStyle,
                children: [
                  const TextSpan(text: 'Bem vinda, '),
                  TextSpan(
                    text: name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: sizes.sm),
          Semantics(
            button: true,
            label: notificationLabel,
            excludeSemantics: true,
            child: IconButton(
              tooltip: 'Notificações',
              onPressed: onNotificationsPressed,
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.notifications_rounded,
                    size: sizes.xl + sizes.xs,
                    color: colorScheme.onPrimary,
                  ),
                  if (notificationCount > 0)
                    Positioned(
                      top: -sizes.xs,
                      right: -sizes.xs,
                      child: Container(
                        constraints: BoxConstraints(
                          minWidth: sizes.md,
                          minHeight: sizes.md,
                        ),
                        padding: EdgeInsets.all(sizes.xs / 2),
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$notificationCount',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onError,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
