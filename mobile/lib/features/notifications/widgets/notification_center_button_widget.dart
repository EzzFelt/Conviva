import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/services/notification_service.dart';
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
    final recoveryRequests =
        ref.watch(recoveryApprovalNotificationsProvider).asData?.value ?? [];
    final recoveryDeliveries =
        ref.watch(recoveryDeliveryNotificationsProvider).asData?.value ?? [];
    final seen = ref.watch(seenNotificationIdsProvider);
    final unreadCount = [
      ...notifications,
      ...recoveryRequests,
      ...recoveryDeliveries,
    ].where((item) => isNotificationUnread(item, seen)).length;

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
  final Set<String> _markedIds = {};

  /// O que foi exibido nesta abertura. Ao marcar como lido, o Firestore deixa
  /// de devolver o item; guardamos aqui para a lista não esvaziar na frente
  /// do usuário. Ao fechar o sino, tudo isso é descartado e some de vez.
  final Map<String, AppNotification> _sessionItems = {};

  /// Abrir a lista já conta como visualizar: marca tudo que está não lido.
  void _markVisibleAsRead(List<AppNotification> items) {
    final seen = ref.read(seenNotificationIdsProvider);
    final unread = items
        .where(
          (item) =>
              item.isPersisted && !item.isRead && !_markedIds.contains(item.id),
        )
        .map((item) => item.id)
        .toList();
    final unseenLocal = items
        .where(
          (item) =>
              !item.isPersisted &&
              !seen.contains(item.id) &&
              !_markedIds.contains(item.id),
        )
        .map((item) => item.id)
        .toList();
    if (unread.isEmpty && unseenLocal.isEmpty) return;

    _markedIds
      ..addAll(unread)
      ..addAll(unseenLocal);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final session = ref.read(currentUserProvider).asData?.value;
      if (session == null) return;

      try {
        if (unseenLocal.isNotEmpty) {
          await ref
              .read(seenNotificationIdsProvider.notifier)
              .markSeen(unseenLocal);
        }
        if (unread.isNotEmpty) {
          await NotificationService.instance.dismissNotifications(unread);
          await markNotificationsAsRead(
            userId: session.uid,
            notificationIds: unread,
          );
        }
        // Remove também os pushes desenhados pelo sistema (app em 2º plano).
        await NotificationService.instance.clearDeliveredNotifications();
      } catch (error) {
        debugPrint(
          'Não foi possível marcar as notificações como lidas: $error',
        );
      }
    });
  }

  void _openNotification(BuildContext context, AppNotification notification) {
    Navigator.of(context).pop();

    final path = switch (notification.type) {
      AppNotificationType.message when notification.chatId != null =>
        '/chat/${Uri.encodeComponent(notification.chatId!)}',
      AppNotificationType.task when notification.elderId != null =>
        '/routine/${Uri.encodeComponent(notification.elderId!)}',
      AppNotificationType.passwordReset when notification.requestId != null =>
        '/password-reset/approval/'
            '${Uri.encodeComponent(notification.requestId!)}',
      _ => null,
    };

    if (path != null) {
      context.go(path, extra: notification.elderName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final notifications = ref.watch(notificationsProvider);
    final recoveryRequests = ref.watch(recoveryApprovalNotificationsProvider);
    final recoveryDeliveries = ref.watch(recoveryDeliveryNotificationsProvider);

    if (notifications.isLoading ||
        recoveryRequests.isLoading ||
        recoveryDeliveries.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (notifications.hasError ||
        recoveryRequests.hasError ||
        recoveryDeliveries.hasError) {
      return Text(
        'Não foi possível carregar as notificações.',
        style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.error),
      );
    }

    final seen = ref.watch(seenNotificationIdsProvider);
    final live = [
      ...?notifications.asData?.value,
      ...?recoveryRequests.asData?.value,
      ...?recoveryDeliveries.asData?.value,
    ];
    _markVisibleAsRead(live);

    for (final item in live) {
      if (item.isPersisted || !isNotificationHidden(item, seen)) {
        _sessionItems[item.id] = item;
      }
    }
    final liveIds = live.map((item) => item.id).toSet();
    final items =
        _sessionItems.values
            .where((item) => item.isPersisted || liveIds.contains(item.id))
            .toList()
          ..sort((first, second) => second.createdAt.compareTo(first.createdAt));

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
            onTap: () => _openNotification(context, items[index]),
          ),
          if (index < items.length - 1) SizedBox(height: sizes.sm),
        ],
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final icon = switch (notification.type) {
      AppNotificationType.message => Icons.chat_rounded,
      AppNotificationType.task => Icons.alarm_rounded,
      AppNotificationType.passwordReset => Icons.lock_reset_rounded,
    };
    final showAsNew = !notification.isRead;

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
                icon,
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
                Icon(
                  Icons.circle,
                  size: sizes.icon(sizes.xs),
                  color: colorScheme.primary,
                ),
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
