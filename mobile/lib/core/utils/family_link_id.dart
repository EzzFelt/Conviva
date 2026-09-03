class FamilyLinkId {
  FamilyLinkId._();

  static String forUsers({
    required String elderId,
    required String familyId,
  }) {
    final normalizedElderId = elderId.trim();
    final normalizedFamilyId = familyId.trim();

    if (normalizedElderId.isEmpty || normalizedFamilyId.isEmpty) {
      throw ArgumentError('O idoso e o familiar devem ser informados.');
    }

    return '${normalizedElderId}_$normalizedFamilyId';
  }
}
