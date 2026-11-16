class ActiveFamilyLink {
  const ActiveFamilyLink({
    required this.linkId,
    required this.familyId,
    required this.name,
    this.photoUrl,
  });

  final String linkId;
  final String familyId;
  final String name;
  final String? photoUrl;
}
