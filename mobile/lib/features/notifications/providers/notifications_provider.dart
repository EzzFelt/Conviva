import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/providers/current_user_provider.dart';
import '../../auth/models/account_type.dart';
import '../models/app_notification.dart';

final notificationsProvider = StreamProvider<List<AppNotification>>((
  ref,
) async* {
  final session = await ref.watch(currentUserProvider.future);
  if (session == null) {
    yield const <AppNotification>[];
    return;
  }

  yield* FirebaseFirestore.instance
      .collection('users')
      .doc(session.uid)
      .collection('notifications')
      .where('read', isEqualTo: false)
      .limit(50)
      .snapshots()
      .map((snapshot) {
        final items = snapshot.docs.map(AppNotification.fromFirestore).toList();
        items.sort(
          (first, second) => second.createdAt.compareTo(first.createdAt),
        );
        return List<AppNotification>.unmodifiable(items);
      });
});

final recoveryApprovalNotificationsProvider =
    StreamProvider<List<AppNotification>>((ref) async* {
      final session = await ref.watch(currentUserProvider.future);
      if (session == null) {
        yield const <AppNotification>[];
        return;
      }

      final recipientField = switch (session.accountType) {
        AccountType.family => 'familyUid',
        AccountType.caregiver => 'caregiverUid',
        _ => null,
      };
      if (recipientField == null) {
        yield const <AppNotification>[];
        return;
      }

      yield* FirebaseFirestore.instance
          .collection('passwordRecoveryRequests')
          .where(recipientField, isEqualTo: session.uid)
          .where('status', whereIn: ['pending', 'rejected'])
          .snapshots()
          .map(
            (snapshot) => List<AppNotification>.unmodifiable(
              snapshot.docs
                  .where(
                    (document) =>
                        document.data()['status'] == 'rejected' ||
                        (document.data()['createdAt'] is Timestamp &&
                            DateTime.now().isBefore(
                              (document.data()['createdAt'] as Timestamp)
                                  .toDate()
                                  .add(const Duration(hours: 24)),
                            )),
                  )
                  .map(AppNotification.fromRecoveryRequest),
            ),
          );
    });

final recoveryDeliveryNotificationsProvider =
    StreamProvider<List<AppNotification>>((ref) async* {
      final session = await ref.watch(currentUserProvider.future);
      if (session == null ||
          !{
            AccountType.family,
            AccountType.caregiver,
          }.contains(session.accountType)) {
        yield const <AppNotification>[];
        return;
      }

      yield* FirebaseFirestore.instance
          .collection('passwordRecoveryRequests')
          .where('approvedByUid', isEqualTo: session.uid)
          .where('status', isEqualTo: 'approved')
          .where('deliveryForwardedToElder', isEqualTo: false)
          .snapshots()
          .map(
            (snapshot) => List<AppNotification>.unmodifiable(
              snapshot.docs.map(AppNotification.fromRecoveryDeliveryRequest),
            ),
          );
    });

Future<void> markNotificationAsRead({
  required String userId,
  required String notificationId,
}) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('notifications')
      .doc(notificationId)
      .update({'read': true});
}

/// Marca várias notificações como lidas de uma vez (um único envio).
Future<void> markNotificationsAsRead({
  required String userId,
  required Iterable<String> notificationIds,
}) {
  final collection = FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('notifications');

  final batch = FirebaseFirestore.instance.batch();
  for (final id in notificationIds) {
    batch.update(collection.doc(id), {'read': true});
  }

  return batch.commit();
}

/// Ids de avisos que não existem no Firestore (pedidos de recuperação de
/// senha) e que o usuário já viu ao abrir o sino. Fica salvo no aparelho.
final seenNotificationIdsProvider =
    NotifierProvider<SeenNotificationIdsNotifier, Set<String>>(
      SeenNotificationIdsNotifier.new,
    );

class SeenNotificationIdsNotifier extends Notifier<Set<String>> {
  static const _maxStored = 300;

  @override
  Set<String> build() {
    final uid = ref.watch(currentUserProvider).asData?.value?.uid;
    if (uid != null) unawaited(_load(uid));
    return const <String>{};
  }

  String _key(String uid) => 'conviva_seen_notifications_$uid';

  Future<void> _load(String uid) async {
    try {
      final stored = await SharedPreferencesAsync().getStringList(_key(uid));
      if (stored == null || !ref.mounted) return;
      state = {...stored, ...state};
    } catch (_) {
      // Sem a marca local o aviso só aparece de novo; nada grave.
    }
  }

  Future<void> markSeen(Iterable<String> ids) async {
    final uid = ref.read(currentUserProvider).asData?.value?.uid;
    final fresh = ids.where((id) => !state.contains(id)).toList();
    if (uid == null || fresh.isEmpty) return;

    final merged = [...state, ...fresh];
    final trimmed = merged.length > _maxStored
        ? merged.sublist(merged.length - _maxStored)
        : merged;
    state = trimmed.toSet();

    try {
      await SharedPreferencesAsync().setStringList(_key(uid), trimmed);
    } catch (_) {}
  }
}

/// Avisos informativos (sem ação pendente) que já foram vistos somem do sino.
bool isNotificationHidden(AppNotification item, Set<String> seen) =>
    !item.isPersisted && !item.requiresAction && seen.contains(item.id);

/// Conta no selo do sino: persistidos usam `read`; os demais, a marca local.
bool isNotificationUnread(AppNotification item, Set<String> seen) =>
    !item.isRead && (item.isPersisted || !seen.contains(item.id));
