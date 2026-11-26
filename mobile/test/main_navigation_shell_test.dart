import 'package:conviva/core/settings/app_settings.dart';
import 'package:conviva/core/themes/app_theme.dart';
import 'package:conviva/core/routes/route_names.dart';
import 'package:conviva/features/auth/models/account_type.dart';
import 'package:conviva/features/auth/models/user_session.dart';
import 'package:conviva/features/auth/providers/current_user_provider.dart';
import 'package:conviva/shared/widgets/main_navigation_bar.dart';
import 'package:conviva/shared/widgets/main_navigation_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows navigation bar inside a conversation route', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith(_TestCurrentUserNotifier.new),
        ],
        child: MaterialApp(
          theme: AppTheme.light(
            const AppSettings(),
          ).copyWith(scaffoldBackgroundColor: Colors.grey),
          home: MainNavigationShell(
            location: RouteNames.chatConversationPath('conversation-1'),
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    );

    expect(find.byType(MainNavigationBar), findsOneWidget);
    final shell = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(shell.extendBody, isFalse);
    expect(
      shell.backgroundColor,
      AppTheme.light(const AppSettings()).colorScheme.surface,
    );
    expect(
      tester
          .widget<MainNavigationBar>(find.byType(MainNavigationBar))
          .currentIndex,
      1,
    );
  });
}

class _TestCurrentUserNotifier extends CurrentUserNotifier {
  @override
  Future<UserSession?> build() async => const UserSession(
    uid: 'elder-1',
    name: 'Pessoa idosa',
    phone: '',
    accountType: AccountType.elder,
    institutionId: 'institution-1',
    status: 'active',
  );
}
