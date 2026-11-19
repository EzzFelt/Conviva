import 'package:conviva/core/constants/recovery_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecoveryConfig.elderRecoveryLookupId', () {
    test('gera um ID SHA-256 sem armazenar o código em texto', () {
      final lookupId = RecoveryConfig.elderRecoveryLookupId('ELD12345678');

      expect(lookupId, hasLength(64));
      expect(lookupId, matches(RegExp(r'^[a-f0-9]{64}$')));
      expect(lookupId, isNot('ELD12345678'));
    });

    test('rejeita códigos que não estejam normalizados e válidos', () {
      expect(
        () => RecoveryConfig.elderRecoveryLookupId('eld12345678'),
        throwsArgumentError,
      );
    });
  });
}
