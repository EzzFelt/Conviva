import 'package:cloud_functions/cloud_functions.dart';

import '../../features/auth/models/elder_password_reset_request.dart';

class ElderPasswordResetService {
  ElderPasswordResetService._();

  static final instance = ElderPasswordResetService._();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  static String? callableErrorMessage(Object error) {
    if (error is! FirebaseFunctionsException) return null;
    final message = error.message?.trim();
    return message == null || message.isEmpty ? null : message;
  }

  Future<ElderPasswordResetRequest> request(String elderCode) async {
    final result = await _functions
        .httpsCallable('requestElderPasswordReset')
        .call<Map<String, dynamic>>({'code': elderCode});
    final data = result.data;
    final requestId = data['requestId']?.toString();
    final token = data['token']?.toString();

    if (requestId == null ||
        requestId.isEmpty ||
        token == null ||
        token.isEmpty) {
      throw StateError('A solicitação de redefinição não foi identificada.');
    }

    return ElderPasswordResetRequest(id: requestId, token: token);
  }

  Future<String> getStatus(ElderPasswordResetRequest request) async {
    final result = await _functions
        .httpsCallable('getElderPasswordResetStatus')
        .call<Map<String, dynamic>>({
          'requestId': request.id,
          'token': request.token,
        });
    final status = result.data['status']?.toString();
    if (status != 'pending' && status != 'approved' && status != 'closed') {
      throw StateError('O status da solicitação não é válido.');
    }
    return status!;
  }

  Future<void> respond({
    required String requestId,
    required bool approve,
  }) async {
    await _functions.httpsCallable('respondToElderPasswordReset').call({
      'requestId': requestId,
      'approve': approve,
    });
  }

  Future<void> complete({
    required ElderPasswordResetRequest request,
    required String newPassword,
  }) async {
    await _functions.httpsCallable('completeElderPasswordReset').call({
      'requestId': request.id,
      'token': request.token,
      'newPassword': newPassword,
    });
  }
}
