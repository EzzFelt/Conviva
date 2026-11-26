import 'package:conviva/features/auth/models/account_type.dart';
import 'package:conviva/features/auth/models/user_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads and serializes an administrator-provisioned support profile', () {
    final session = UserSession.fromMap(
      uid: 'support-uid',
      data: const {
        'name': 'Equipe Conviva',
        'type': 'support',
        'status': 'active',
      },
    );

    expect(session.accountType, AccountType.support);
    expect(session.institutionId, isEmpty);
    expect(session.toMap()['type'], 'support');
  });
}
