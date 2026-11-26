import 'package:conviva/core/settings/app_settings.dart';
import 'package:conviva/core/themes/app_theme.dart';
import 'package:conviva/features/auth/models/account_type.dart';
import 'package:conviva/features/auth/models/user_session.dart';
import 'package:conviva/features/auth/providers/current_user_provider.dart';
import 'package:conviva/features/reports/models/report_draft.dart';
import 'package:conviva/features/reports/pages/report_select_person_page.dart';
import 'package:conviva/features/reports/providers/reports_provider.dart';
import 'package:conviva/features/reports/widgets/report_offender_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the institution display name instead of its code', () {
    final target = reportTargetFromInstitution('INST-123', {
      'code': 'INST-123',
      'nomeFantasia': 'Casa de Repouso Esperança',
    });

    expect(target.id, 'INST-123');
    expect(target.name, 'Casa de Repouso Esperança');
  });

  test('does not expose the institution id when no display name exists', () {
    final target = reportTargetFromInstitution('INST-123', {
      'code': 'INST-123',
    });

    expect(target.name, 'Instituição');
  });

  testWidgets('selecting an institution opens its confirmation modal', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith(_TestCurrentUserNotifier.new),
          reportTargetsProvider(OffenderKind.institution).overrideWith(
            (_) async => const [
              ReportTarget(id: 'institution-code', name: 'Casa Esperança'),
            ],
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(const AppSettings()),
          home: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => const ReportSelectPersonPage(
                draft: ReportDraft(offender: OffenderKind.institution),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Casa Esperança'), findsOneWidget);
    await tester.tap(find.text('Selecionar'));
    await tester.pumpAndSettle();

    final titleFinder = find.text(
      'Tem certeza que deseja\ndenunciar esta instituição?',
    );
    expect(titleFinder, findsOneWidget);
    expect(tester.widget<Text>(titleFinder).textAlign, TextAlign.left);
    final closeFinder = find.byTooltip('Fechar');
    expect(
      tester.getCenter(closeFinder).dy,
      lessThan(tester.getTopLeft(titleFinder).dy),
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.close_rounded)).size,
      greaterThan(24),
    );
    expect(find.text('Casa Esperança'), findsNWidgets(2));
    expect(find.text('Confirmar'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final cancelFinder = find.text('Cancelar');
    await tester.ensureVisible(cancelFinder);
    await tester.tap(cancelFinder);
    await tester.pumpAndSettle();
    expect(titleFinder, findsNothing);
    expect(find.text('Selecionar'), findsOneWidget);

    await tester.tap(find.text('Selecionar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();
    expect(titleFinder, findsNothing);
    expect(find.text('Selecionar'), findsOneWidget);
  });

  testWidgets('unselected offender artwork is grayscale and translucent', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(const AppSettings()),
        home: Scaffold(
          body: ReportOffenderCard(
            label: 'Parente',
            illustration: const Icon(Icons.people),
            selected: false,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.byType(Opacity), findsOneWidget);
    expect(find.byType(ColorFiltered), findsOneWidget);
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, .48);
  });
}

class _TestCurrentUserNotifier extends CurrentUserNotifier {
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
