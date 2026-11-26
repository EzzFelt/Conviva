/// Tipos de usuário do sistema Conviva
enum UserType {
  idoso('IDOSO', 'Para idosos'),
  cuidador('CUIDADOR', 'Para cuidadores'),
  familiar('FAMILIAR', 'Para familiares');

  const UserType(this.value, this.description);

  final String value;
  final String description;

  /// Converte string para enum
  static UserType fromString(String value) {
    return UserType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => UserType.idoso, // Default
    );
  }
}
