import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';

class NotificationButtonWidget extends StatelessWidget {
  const NotificationButtonWidget({
    super.key,
    required this.onPressed,
    this.notificationCount = 0,
    this.iconColor,
  });

  final VoidCallback onPressed;
  final int notificationCount;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final visibleCount = notificationCount.clamp(0, 99);
    final notificationLabel = switch (notificationCount) {
      <= 0 => 'Notificações, nenhuma nova',
      1 => 'Notificações, 1 nova',
      _ => 'Notificações, $notificationCount novas',
    };

    return Semantics(
      button: true,
      label: notificationLabel,
      excludeSemantics: true,
      child: IconButton(
        tooltip: 'Notificações',
        onPressed: onPressed,
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.notifications_rounded,
              size: sizes.xl + sizes.xs,
              color: iconColor ?? colorScheme.onPrimary,
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
                    borderRadius: BorderRadius.circular(sizes.radiusFull),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    notificationCount > 99 ? '99+' : '$visibleCount',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onError,
                      fontSize: notificationCount > 99 ? sizes.sm : null,
                      fontWeight: FontWeight.w600,
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