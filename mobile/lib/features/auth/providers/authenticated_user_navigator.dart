import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/route_names.dart';
import '../../../core/services/auth_service.dart';
import '../models/account_type.dart';
import '../models/user_session.dart';

class AuthenticatedUserNavigator {
  AuthenticatedUserNavigator._();

  static Future<void> open(
    BuildContext context,
    UserSession session,
  ) async {
    // Familiar e cuidador só entram depois de confirmar o e-mail.
    if (session.accountType != AccountType.elder &&
        session.accountType != AccountType.support) {
      final verified = await AuthService.instance.isCurrentEmailVerified();

      if (!context.mounted) return;

      if (!verified) {
        context.go(RouteNames.verifyEmail);
        return;
      }
    }

    switch (session.accountType) {
      case AccountType.elder:
        context.go(RouteNames.elderHome);
        return;

      case AccountType.caregiver:
        context.go(
          RouteNames.caregiverHome,
          extra: session.toMap(),
        );
        return;

      case AccountType.family:
        final linkedElder = await AuthService.instance
            .getActiveLinkedElderForFamily(session.uid);

        if (!context.mounted) return;

        if (linkedElder == null) {
          context.go(RouteNames.familyLink);
        } else {
          context.go(
            RouteNames.familyHome,
            extra: {
              'id': linkedElder['id']?.toString(),
              'name': linkedElder['name']?.toString() ?? 'Idoso',
            },
          );
        }
        return;

      case AccountType.support:
        context.go(RouteNames.supportHome);
        return;
    }
  }
}
