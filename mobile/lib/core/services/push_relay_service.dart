import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/push_relay_config.dart';

/// Pede ao relé gratuito (Cloudflare Worker) que envie o push FCM de uma
/// mensagem recém-enviada. O relé confere o login e lê a mensagem no
/// Firestore, então o app não manda título nem texto: nada pode ser forjado.
class PushRelayService {
  PushRelayService._();

  static Future<void> notifyNewMessage({
    required String chatId,
    required String messageId,
  }) async {
    final baseUrl = PushRelayConfig.url.trim();
    if (kIsWeb || baseUrl.isEmpty) return;

    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) return;

      final response = await http
          .post(
            Uri.parse('$baseUrl/notify-message'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({'chatId': chatId, 'messageId': messageId}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 400) {
        debugPrint(
          'Relé de push respondeu ${response.statusCode}: ${response.body}',
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Não foi possível acionar o relé de push: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
