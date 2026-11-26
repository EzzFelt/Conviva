import 'package:conviva/core/settings/app_settings.dart';
import 'package:conviva/core/themes/app_theme.dart';
import 'package:conviva/core/routes/route_names.dart';
import 'package:conviva/features/auth/models/account_type.dart';
import 'package:conviva/features/auth/models/user_session.dart';
import 'package:conviva/features/auth/providers/current_user_provider.dart';
import 'package:conviva/features/profile/models/active_family_link.dart';
import 'package:conviva/features/profile/models/family_link_request.dart';
import 'package:conviva/features/profile/models/institution_summary.dart';
import 'package:conviva/features/profile/pages/profile_page.dart';
import 'package:conviva/features/profile/providers/family_link_requests_provider.dart';
import 'package:conviva/features/profile/providers/institution_summary_provider.dart';
import 'package:conviva/features/settings/pages/settings_page.dart';
import 'package:conviva/shared/widgets/main_navigation_bar.dart';
import 'package:conviva/shared/widgets/main_navigation_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  testWidgets('exibe as configurações em uma tela de celular e permite rolar', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();

    tester.view.physicalSize = const Size(365, 802);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith(_SettingsCurrentUserNotifier.new),
        ],
        child: MaterialApp(
          theme: AppTheme.light(const AppSettings()),
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Configurações'), findsOneWidget);
    expect(find.text('Fonte'), findsOneWidget);
    expect(find.text('Notificações'), findsOneWidget);

    await tester.ensureVisible(find.text('Restaurar padrão'));
    await tester.pumpAndSettle();

    expect(find.text('Restaurar padrão'), findsOneWidget);
    final settingsScrollable = find.descendant(
      of: find.byType(CustomScrollView),
      matching: find.byType(Scrollable),
    );
    expect(
      tester.state<ScrollableState>(settingsScrollable.first).position.pixels,
      greaterThan(0),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('o topo do perfil rola junto com o conteúdo', (tester) async {
    tester.view.physicalSize = const Size(365, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith(_ProfileCurrentUserNotifier.new),
          institutionSummaryProvider('institution-1').overrideWith(
            (_) async => const InstitutionSummary(
              id: 'institution-1',
              name: 'Instituição de teste',
              address: '',
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(const AppSettings()),
          home: const ProfilePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Suas informações'));
    await tester.pumpAndSettle();

    final profileScrollable = find.descendant(
      of: find.byType(CustomScrollView),
      matching: find.byType(Scrollable),
    );
    expect(
      tester.state<ScrollableState>(profileScrollable.first).position.pixels,
      greaterThan(0),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'the elder profile can scroll its final section above the navbar',
    (tester) async {
      tester.view.physicalSize = const Size(365, 802);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith(
              _ElderProfileCurrentUserNotifier.new,
            ),
            activeFamilyLinksProvider.overrideWith(
              (_) => Stream.value(const <ActiveFamilyLink>[]),
            ),
            pendingFamilyRequestsProvider.overrideWith(
              (_) => Stream.value(const <FamilyLinkRequest>[]),
            ),
            institutionSummaryProvider('institution-1').overrideWith(
              (_) async => const InstitutionSummary(
                id: 'institution-1',
                name: 'Instituição de teste',
                address: '',
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(const AppSettings()),
            home: MainNavigationShell(
              location: RouteNames.profile,
              child: const ProfilePage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final profileScrollable = find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.byType(Scrollable),
      );
      final position = tester
          .state<ScrollableState>(profileScrollable.first)
          .position;
      await position.moveTo(position.maxScrollExtent);
      await tester.pumpAndSettle();

      final navbarTop = tester.getTopLeft(find.byType(MainNavigationBar)).dy;
      final finalActionBottom = tester
          .getRect(find.text('Mostrar código'))
          .bottom;
      expect(position.pixels, greaterThan(0));
      expect(finalActionBottom, lessThan(navbarTop));
      expect(tester.takeException(), isNull);
    },
  );
}

class _SettingsCurrentUserNotifier extends CurrentUserNotifier {
  @override
  Future<UserSession?> build() async => const UserSession(
    uid: 'user-1',
    name: 'Pessoa',
    phone: '',
    accountType: AccountType.elder,
    institutionId: 'institution-1',
    status: 'active',
  );
}

class _ProfileCurrentUserNotifier extends CurrentUserNotifier {
  @override
  Future<UserSession?> build() async => const UserSession(
    uid: 'user-2',
    name: 'Cuidador de teste',
    phone: '',
    accountType: AccountType.caregiver,
    institutionId: 'institution-1',
    status: 'active',
  );
}

class _ElderProfileCurrentUserNotifier extends CurrentUserNotifier {
  @override
  Future<UserSession?> build() async => const UserSession(
    uid: 'elder-1',
    name: 'Pessoa idosa',
    phone: '',
    accountType: AccountType.elder,
    institutionId: 'institution-1',
    status: 'active',
    elderLinkCode: 'ACCESS1',
  );
}
