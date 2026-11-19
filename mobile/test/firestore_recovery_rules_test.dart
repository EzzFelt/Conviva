import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String rules;
  late String indexes;

  setUpAll(() {
    rules = File('firestore.rules').readAsStringSync().replaceAll('\r\n', '\n');
    indexes = File('firestore.indexes.json').readAsStringSync();
  });

  test('rules use independent decisions and separate timestamps', () {
    expect(rules, contains("familyDecision == 'pending'"));
    expect(rules, contains("caregiverDecision == 'pending'"));
    expect(rules, contains('data.familyRespondedAt == request.time'));
    expect(rules, contains('data.caregiverRespondedAt == request.time'));
    expect(rules, isNot(contains("data.respondedBy")));
  });

  test('approved requests no longer depend on 24-hour request expiry', () {
    expect(rules, contains("data.status == 'approved'"));
    expect(rules, contains("deliveryIsWithinRetention(resource.data)"));
    expect(
      rules,
      contains(
        "request.time <\n"
        "                resource.data.createdAt + duration.value(24, 'h')",
      ),
    );
  });

  test('delivery rules require a scoped expiry and block completed reads', () {
    expect(rules, contains('deliveryExpiresAt'));
    expect(rules, contains("get(requestPath).data.status == 'approved'"));
    expect(
      rules,
      isNot(
        contains("get(requestPath).data.status in ['approved', 'completed']"),
      ),
    );
  });

  test('caregiver validation requires elder caregiver assignment', () {
    expect(
      rules,
      contains(
        "get(elderPath).data.get('recoveryCaregiverUid', '') ==\n"
        "                caregiverUid",
      ),
    );
  });

  test('indexes JSON remains valid and has no duplicate recovery index', () {
    final decoded = jsonDecode(indexes);
    expect(decoded, isA<Map<String, dynamic>>());
    expect(indexes, contains('"elderUid"'));
    expect(indexes, contains('"deliveryForwardedToElder"'));
  });
}
