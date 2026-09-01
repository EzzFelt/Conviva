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
            extra: linkedElder['name']?.toString() ?? 'Idoso',
          );
        }
    }
  }
}
