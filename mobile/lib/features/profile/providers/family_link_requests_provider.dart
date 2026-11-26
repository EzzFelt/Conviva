import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/models/account_type.dart';
import '../../auth/providers/current_user_provider.dart';
import '../models/active_family_link.dart';
import '../models/family_link_request.dart';

/// Familiares vinculados ao idoso logado (em tempo real).
final activeFamilyLinksProvider =
    StreamProvider.autoDispose<List<ActiveFamilyLink>>((ref) async* {
      final session = await ref.watch(currentUserProvider.future);

      if (session == null || session.accountType != AccountType.elder) {
        yield const <ActiveFamilyLink>[];
        return;
      }

      final firestore = FirebaseFirestore.instance;

      yield* firestore
          .collection('familyLinks')
          .where('elderId', isEqualTo: session.uid)
          .where('status', isEqualTo: 'active')
          .snapshots()
          .asyncMap((snapshot) async {
            final families = <ActiveFamilyLink>[];

            for (final document in snapshot.docs) {
              final data = document.data();
              if (data['institutionId']?.toString() != session.institutionId) {
                continue;
              }

              final familyId = data['familiarId']?.toString() ?? '';
              if (familyId.isEmpty) continue;

              var name = 'Familiar';
              String? photoUrl;
              final familyDocument = await firestore
                  .collection('users')
                  .doc(familyId)
                  .get();
              final familyData = familyDocument.data();

              if (familyData != null) {
                final familyName = familyData['name']?.toString().trim();
                if (familyName != null && familyName.isNotEmpty) {
                  name = familyName;
                }
                photoUrl = familyData['photoUrl']?.toString();
              }

              families.add(
                ActiveFamilyLink(
                  linkId: document.id,
                  familyId: familyId,
                  name: name,
                  photoUrl: photoUrl,
                ),
              );
            }

            families.sort((first, second) => first.name.compareTo(second.name));
            return families;
          });
    });

/// Pedidos de vínculo pendentes para o idoso logado (em tempo real).
final pendingFamilyRequestsProvider =
    StreamProvider.autoDispose<List<FamilyLinkRequest>>((ref) async* {
      final session = await ref.watch(currentUserProvider.future);

      if (session == null || session.accountType != AccountType.elder) {
        yield const <FamilyLinkRequest>[];
        return;
      }

      final firestore = FirebaseFirestore.instance;

      yield* firestore
          .collection('familyLinks')
          .where('elderId', isEqualTo: session.uid)
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .asyncMap((snapshot) async {
            final requests = <FamilyLinkRequest>[];

            for (final document in snapshot.docs) {
              final data = document.data();
              if (data['institutionId']?.toString() != session.institutionId) {
                continue;
              }

              final familyId = data['familiarId']?.toString() ?? '';
              if (familyId.isEmpty) continue;

              var name = 'Familiar';
              String? photoUrl;

              try {
                final familyDocument = await firestore
                    .collection('users')
                    .doc(familyId)
                    .get();
                final familyData = familyDocument.data();

                if (familyData != null) {
                  final familyName = familyData['name']?.toString().trim();
                  if (familyName != null && familyName.isNotEmpty) {
                    name = familyName;
                  }
                  photoUrl = familyData['photoUrl']?.toString();
                }
              } catch (_) {
                // Sem os dados do familiar, mostra só "Familiar".
              }

              final createdAt = data['createdAt'];

              requests.add(
                FamilyLinkRequest(
                  linkId: document.id,
                  familyId: familyId,
                  name: name,
                  photoUrl: photoUrl,
                  receiveNotifications: data['receiveNotifications'] != false,
                  createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
                ),
              );
            }

            requests.sort((a, b) {
              final first = a.createdAt ?? DateTime.now();
              final second = b.createdAt ?? DateTime.now();
              return first.compareTo(second);
            });

            return requests;
          });
    });
