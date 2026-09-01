import 'package:conviva/core/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthRegister phone normalization', () {
    test('removes the Brazilian phone mask before saving', () {
      final result = AuthRegister.normalizePhone('(11) 99999-8888');

      expect(result, '11999998888');
    });

    test('keeps a phone that already contains only digits', () {
      final result = AuthRegister.normalizePhone('1133334444');

      expect(result, '1133334444');
    });
  });

  group('AuthRegister elder access code', () {
    test('normalizes the elder code', () {
      final result = AuthRegister.normalizeElderCode(' eld-ab12 ');

      expect(result, 'ELDAB12');
    });

    test('generates a deterministic code from a seed', () {
      final result = AuthRegister.generateElderLinkCode('abc-123');

      expect(result, 'ELD00ABC123');
    });

    test('converts a valid elder code to its internal authentication email', () {
      final result = AuthRegister.elderAuthEmail('eld-ab12');

      expect(result, 'eldab12@elder.conviva.app');
    });

    test('throws when the elder code is invalid', () {
      expect(
        () => AuthRegister.elderAuthEmail('1234'),
        throwsA(isA<Exception>()),
      );
    });
  });
}