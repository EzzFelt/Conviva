import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_modal_widget.dart';
import '../../../shared/widgets/notification_button_widget.dart';
import '../../auth/providers/current_user_provider.dart';
import '../models/app_notification.dart';
import '../providers/notifications_provider.dart';

class NotificationCenterButtonWidget extends ConsumerWidget {
  const NotificationCenterButtonWidget({super.key});

  Future<void> _openNotifications(BuildContext context) async {
    await showAppModal<void>(
      context: context,
      title: 'Notificações',
      size: AppModalSize.large,
      child: const _NotificationsList(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider).asData?.value ?? [];
    final unreadCount = notifications.where((item) => !item.isRead).length;

    return NotificationButtonWidget(
      notificationCount: unreadCount,
      onPressed: () => _openNotifications(context),
    );
  }
}

class _NotificationsList extends ConsumerStatefulWidget {
  const _NotificationsList();

  @override
  ConsumerState<_NotificationsList> createState() => _NotificationsListState();
}

class _NotificationsListState extends ConsumerState<_NotificationsList> {
  /// Notificações que estavam não lidas quando a lista foi aberta.
  /// Continuam destacadas enquanto a lista estiver na tela, mesmo já
  /// tendo sido marcadas como lidas.
  final Set<String> _highlightedIds = {};
  final Set<String> _markedIds = {};

  /// Abrir a lista já conta como visualizar: marca tudo que está não lido.
  void _markVisibleAsRead(List<AppNotification> items) {
    final unread = items
        .where((item) => !item.isRead && !_markedIds.contains(item.id))
        .map((item) => item.id)
        .toList();
    if (unread.isEmpty) return;

    _highlightedIds.addAll(unread);
    _markedIds.addAll(unread);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final session = ref.read(currentUserProvider).asData?.value;
      if (session == null) return;

      try {
        await markNotificationsAsRead(
          userId: session.uid,
          notificationIds: unread,
        );
      } catch (error) {
        debugPrint('Não foi possível marcar as notificações como lidas: $error');
      }
    });
  }

  void _openNotification(
    BuildContext context,
    AppNotification notification,
  ) {
    Navigator.of(context).pop();

    final path = switch (notification.type) {
      AppNotificationType.message when notification.chatId != null =>
        '/chat/${Uri.encodeComponent(notification.chatId!)}',
      AppNotificationType.task when notification.elderId != null =>
        '/routine/${Uri.encodeComponent(notification.elderId!)}',
      _ => null,
    };

    if (path != null) context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final notifications = ref.watch(notificationsProvider);

    return notifications.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Text(
        'Não foi possível carregar as notificações.',
        style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.error),
      ),
      data: (items) {
        _markVisibleAsRead(items);

        if (items.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: sizes.xl),
            child: Column(
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  size: sizes.icon(sizes.xxl),
                  color: colorScheme.onSurfaceVariant,
                ),
                SizedBox(height: sizes.md),
                Text(
                  'Você ainda não tem notificações.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              _NotificationTile(
                notification: items[index],
                isNew: _highlightedIds.contains(items[index].id),
                onTap: () => _openNotification(context, items[index]),
              ),
              if (index < items.length - 1) SizedBox(height: sizes.sm),
            ],
          ],
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
    this.isNew = false,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  /// Destaca a notificação como "nova" mesmo depois de marcada como lida.
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final isTask = notification.type == AppNotificationType.task;
    final showAsNew = isNew || !notification.isRead;

    return Material(
      color: showAsNew
          ? colorScheme.primaryContainer.withValues(alpha: .45)
          : colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(sizes.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(sizes.radiusMd),
        child: Padding(
          padding: EdgeInsets.all(sizes.md),
          child: Row(
            children: [
              Icon(
                isTask ? Icons.alarm_rounded : Icons.chat_rounded,
                color: colorScheme.primary,
                size: sizes.icon(sizes.lg),
              ),
              SizedBox(width: sizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notification.title, style: theme.textTheme.titleSmall),
                    SizedBox(height: sizes.xs),
                    Text(
                      notification.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    SizedBox(height: sizes.xs),
                    Text(
                      _formatDate(notification.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (showAsNew) ...[
                SizedBox(width: sizes.sm),
                Icon(Icons.circle, size: sizes.icon(sizes.xs), color: colorScheme.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} às $hour:$minute';
  }
}
