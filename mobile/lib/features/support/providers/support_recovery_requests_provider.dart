import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/models/account_type.dart';
import '../../auth/models/elder_recovery_request.dart';
import '../../auth/providers/current_user_provider.dart';

final supportRecoveryRequestsProvider =
    StreamProvider<List<ElderRecoveryRequest>>((ref) async* {
      final session = await ref.watch(currentUserProvider.future);
      if (session?.accountType != AccountType.support) {
        yield const <ElderRecoveryRequest>[];
        return;
      }

      yield* FirebaseFirestore.instance
          .collection('passwordRecoveryRequests')
          .where('status', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .map(
            (snapshot) => List<ElderRecoveryRequest>.unmodifiable(
              snapshot.docs.map(
                (document) => ElderRecoveryRequest.fromMap(
                  id: document.id,
                  data: document.data(),
                ),
              ),
            ),
          );
    });
