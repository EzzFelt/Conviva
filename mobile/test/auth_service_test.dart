import 'package:conviva/core/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthService elder password matching', () {
    test('returns the unique elder whose password hash matches the entered password', () {
      final elderUsers = [
        {'id': 'elder-1', 'passwordHash': AuthRegister.hashPassword('1234')},
        {'id': 'elder-2', 'passwordHash': AuthRegister.hashPassword('9999')},
      ];

      final result = AuthService.findMatchingElderUser(
        elderUsers: elderUsers,
        password: '1234',
      );

      expect(result, 'elder-1');
    });

    test('throws when more than one elder shares the same password hash', () {
      final elderUsers = [
        {'id': 'elder-1', 'passwordHash': AuthRegister.hashPassword('1111')},
        {'id': 'elder-2', 'passwordHash': AuthRegister.hashPassword('1111')},
      ];

      expect(
        () => AuthService.findMatchingElderUser(
          elderUsers: elderUsers,
          password: '1111',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('throws when no elder in the institution matches the entered password', () {
      final elderUsers = [
        {'id': 'elder-1', 'passwordHash': AuthRegister.hashPassword('4567')},
      ];

      expect(
        () => AuthService.findMatchingElderUser(
          elderUsers: elderUsers,
          password: '1234',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
