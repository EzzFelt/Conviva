import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/current_user_provider.dart';
import '../services/auri_service.dart';

final auriServiceProvider = Provider<AuriService>((ref) => AuriService());

final auriMessagesProvider = StreamProvider.autoDispose((ref) async* {
  final session = await ref.watch(currentUserProvider.future);
  if (session == null) {
    yield null;
    return;
  }
  yield* ref.read(auriServiceProvider).messagesStream(session.uid);
});
