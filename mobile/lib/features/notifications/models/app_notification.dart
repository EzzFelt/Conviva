import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum AppNotificationType { message, task, passwordReset }

@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    this.chatId,
    this.elderId,
    this.requestId,
    this.elderName,
    this.isPersisted = true,
  });

  final String id;
  final AppNotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String? chatId;
  final String? elderId;
  final String? requestId;
  final String? elderName;
  final bool isPersisted;

  factory AppNotification.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final createdAt = data['createdAt'];

    return AppNotification(
      id: document.id,
      type: switch (data['type']) {
        'task' => AppNotificationType.task,
        'password_reset' => AppNotificationType.passwordReset,
        _ => AppNotificationType.message,
      },
      title: data['title']?.toString() ?? 'Notificação',
      body: data['body']?.toString() ?? '',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      isRead: data['read'] == true,
      chatId: data['chatId']?.toString(),
      elderId: data['elderId']?.toString(),
      requestId: data['requestId']?.toString(),
      elderName: data['elderName']?.toString(),
    );
  }

  factory AppNotification.fromRecoveryRequest(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final createdAt = data['createdAt'];
    if (createdAt is! Timestamp) {
      throw const FormatException('Data do pedido inválida.');
    }

    return AppNotification(
      id: 'password_reset_${document.id}',
      type: AppNotificationType.passwordReset,
      title: data['status'] == 'rejected'
          ? 'Resultado da recuperação de senha'
          : DateTime.now().isAfter(
              createdAt.toDate().add(const Duration(hours: 24)),
            )
          ? 'Pedido expirado'
          : 'Pedido de troca de senha',
      body: data['status'] == 'rejected'
          ? 'Ambos responsáveis recusaram o pedido.'
          : DateTime.now().isAfter(
              createdAt.toDate().add(const Duration(hours: 24)),
            )
          ? 'O prazo de 24 horas para aprovação terminou.'
          : 'Há um pedido aguardando sua resposta.',
      createdAt: createdAt.toDate(),
      isRead: data['status'] == 'rejected',
      elderId: data['elderUid']?.toString(),
      requestId: document.id,
      isPersisted: false,
    );
  }

  factory AppNotification.fromRecoveryDeliveryRequest(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final createdAt = data['createdAt'];
    if (createdAt is! Timestamp) {
      throw const FormatException('Data do pedido inválida.');
    }

    return AppNotification(
      id: 'password_reset_delivery_${document.id}',
      type: AppNotificationType.passwordReset,
      title: data['linkDeliveredToApprover'] == true
          ? 'Link de recuperação disponível'
          : 'Pedido de recuperação aprovado',
      body: data['linkDeliveredToApprover'] == true
          ? 'Encaminhe o link ao idoso pela área privada do pedido.'
          : 'A equipe de suporte ainda precisa inserir o link.',
      createdAt: createdAt.toDate(),
      isRead: false,
      elderId: data['elderUid']?.toString(),
      requestId: document.id,
      isPersisted: false,
    );
  }
}
