import 'package:conviva/core/settings/app_settings.dart';
import 'package:conviva/core/themes/app_theme.dart';
import 'package:conviva/features/auth/models/account_type.dart';
import 'package:conviva/features/auth/models/user_session.dart';
import 'package:conviva/features/auth/providers/current_user_provider.dart';
import 'package:conviva/features/routine/models/routine_elder_summary.dart';
import 'package:conviva/features/routine/pages/routine_page.dart';
import 'package:conviva/features/routine/providers/routine_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows resident profile details in the caregiver list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(365, 802);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final elder = RoutineElderSummary(
      id: 'elder-1',
      name: 'Maria Antônia',
      phone: '11987654321',
      institutionId: 'institution-1',
      gender: 'Feminino',
      bloodType: 'O+',
      dependencyLevel: '1',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith(_TestCaregiverNotifier.new),
          accessibleRoutineEldersProvider.overrideWith(
            (_) => Stream.value([elder]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(const AppSettings()),
          home: const RoutinePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Residentes'), findsOneWidget);
    expect(find.text('Seus residentes'), findsOneWidget);
    expect(find.text('Maria Antônia'), findsOneWidget);
    expect(find.text('Tel: (11) 98765-4321'), findsOneWidget);
    expect(find.text('Sexo: Feminino'), findsOneWidget);
    expect(find.text('Tipo sanguíneo: O+'), findsOneWidget);
    expect(find.text('Grau de dependência: 1'), findsOneWidget);
    expect(find.text('Ver rotina'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _TestCaregiverNotifier extends CurrentUserNotifier {
  @override
  Future<UserSession?> build() async => const UserSession(
    uid: 'caregiver-1',
    name: 'Cuidador',
    phone: '',
    accountType: AccountType.caregiver,
    institutionId: 'institution-1',
    status: 'active',
  );
}
