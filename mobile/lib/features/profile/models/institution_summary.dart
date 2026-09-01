class InstitutionSummary {
  const InstitutionSummary({
    required this.id,
    required this.name,
    required this.address,
    this.photoUrl,
  });

  final String id;
  final String name;
  final String address;
  final String? photoUrl;

  factory InstitutionSummary.fromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final street = _firstValue(data, ['address', 'street', 'endereco']);
    final city = _firstValue(data, ['city', 'cidade']);
    final state = _firstValue(data, ['state', 'estado', 'uf']);
    final addressParts = [
      if (street.isNotEmpty) street,
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
    ];

    return InstitutionSummary(
      id: id,
      name: _firstValue(data, ['name', 'nome']).isEmpty
          ? 'Instituição'
          : _firstValue(data, ['name', 'nome']),
      address: addressParts.isEmpty
          ? 'Código: $id'
          : addressParts.join(', '),
      photoUrl: _optionalValue(data, ['photoUrl', 'imageUrl', 'logoUrl']),
    );
  }

  static String _firstValue(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  static String? _optionalValue(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    final value = _firstValue(data, keys);
    return value.isEmpty ? null : value;
  }
}
