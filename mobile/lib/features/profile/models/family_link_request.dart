/// Pedido de vínculo enviado por um familiar e ainda não respondido pelo idoso.
class FamilyLinkRequest {
  const FamilyLinkRequest({
    required this.linkId,
    required this.familyId,
    required this.name,
    this.photoUrl,
    this.receiveNotifications = true,
    this.createdAt,
  });

  final String linkId;
  final String familyId;
  final String name;
  final String? photoUrl;
  final bool receiveNotifications;
  final DateTime? createdAt;
}
